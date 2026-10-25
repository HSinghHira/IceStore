#!/bin/bash
# Starts one service. Usage: run-svc <name>
# Three kinds of service:
#   built-in  - installed in the base image with apt (postgres, redis, nginx gateway, ...).
#               Started by an explicit command in the "built-in" case below.
#   native    - a binary copied out of its upstream image into the base image (NATIVE list).
#               Use this for anything that needs a real /proc (Rust/Go servers usually work).
#   chroot    - everything else: runs inside its own upstream image's filesystem under
#               /opt/rootfs/<name> (Node on Alpine, Python apps, anything with many libs).
# Native and chroot services start with their image's own entrypoint, command, env,
# working dir and user, read from /opt/meta/<name>.json, plus /run/aio/<name>.env.
set -euo pipefail

svc=${1:?usage: run-svc <name>}
DATA=${AIO_DATA:-/data}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}

# ---- APP-SPECIFIC: services copied out as native binaries (space separated) ----
NATIVE=""

# Strip ANSI colour codes (ZimaOS/CasaOS log viewers show them as junk like [32m),
# then prefix every line with the service name.
exec > >(sed -u -e 's|\x1b\[[0-9;?]*[ -/]*[@-~]||g' -e "s/^/[$svc] /") 2>&1

wait_one() {
  case $1 in
    pg)     /usr/lib/postgresql/15/bin/pg_isready -q -h 127.0.0.1 -p 5432 ;;
    tcp:*)  (exec 3<>"/dev/tcp/127.0.0.1/${1#tcp:}") 2>/dev/null ;;
    http*)  curl -fsS -o /dev/null -m 5 "$1" 2>/dev/null ;;
    sock:*) [ -S "${1#sock:}" ] ;;
    *)      echo "bad wait spec: $1"; return 1 ;;
  esac
}

wait_all() {
  [ "${AIO_SKIP_WAIT:-}" = 1 ] && return 0
  local spec deadline=$((SECONDS + 900))
  for spec in "$@"; do
    if ! wait_one "$spec"; then
      echo "waiting for $spec"
      until wait_one "$spec"; do
        [ "$SECONDS" -lt "$deadline" ] || { echo "gave up waiting for $spec"; exit 1; }
        sleep 2
      done
    fi
  done
}

load_env() {
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] && export "$line"
  done < "$1"
}

# ---- APP-SPECIFIC: what each service waits for before it starts ----
# Specs: pg | tcp:<port> | http://127.0.0.1:<port>/<health path> | sock:<unix socket file>
# Tianji runs its database migrations before it starts listening, so the
# gateway (and the container health) only goes green once the app is ready.
case $svc in
  tianji)  wait_all pg ;;
  admin)   wait_all http://127.0.0.1:12345/health ;;
  gateway) wait_all http://127.0.0.1:12345/health ;;
  *) ;;
esac

# ---- APP-SPECIFIC: built-in services (installed with apt in the Dockerfile) ----
case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups \
      /usr/lib/postgresql/15/bin/postgres -D "$DATA/postgres" \
      -c listen_addresses=127.0.0.1 -c unix_socket_directories=/run/postgresql
    ;;
  admin)
    # Tianji's first migration creates the account admin / admin. While that
    # account still has the password "admin", give it this install's
    # password (ADMIN_PASSWORD, or the one made on first start). Once you
    # change the password in Tianji, this does nothing any more.
    load_env "$RUN/admin.env"
    psql_pg() {
      setpriv --reuid=postgres --regid=postgres --init-groups \
        psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -Atq "$@"
    }
    # bcrypt of "admin", as written by Tianji's first migration. pgcrypto
    # makes $2a$ bcrypt hashes, the kind Tianji's bcryptjs checks.
    default_hash='$2a$10$V384zbubCaykNgBHs5mag.AngiWhAgRR.KLoxal7xh8sfOBwnASN2'
    hash=$(printf '%s\n' "CREATE EXTENSION IF NOT EXISTS pgcrypto;" "SELECT crypt(:'pw', gen_salt('bf', 10));" \
      | psql_pg -d postgres -v pw="$ADMIN_PASSWORD") || { echo "could not hash the admin password"; exit 1; }
    updated=$(printf '%s\n' "UPDATE \"User\" SET password = :'h' WHERE username = 'admin' AND password = :'old' RETURNING id;" \
      | psql_pg -d tianji -v h="$hash" -v old="$default_hash") || { echo "could not set the admin password"; exit 1; }
    if [ -n "$updated" ]; then
      echo "the default admin / admin login is gone: sign in as admin with the password on the \"Tianji login is\" line above"
    fi
    exit 0
    ;;
  gateway)
    exec nginx -c /etc/nginx/aio.conf -g 'daemon off;'
    ;;
esac

# ---- generic from here down: native and chroot services ----
native=0
case " $NATIVE " in *" $svc "*) native=1 ;; esac

root=$ROOTFS/$svc
meta=$META/$svc.json
[ "$native" = 1 ] || [ -d "$root" ] || { echo "missing $root"; exit 1; }
[ -f "$meta" ] || { echo "missing $meta (run capture-meta.sh before building)"; exit 1; }

mapfile -t entry < <(jq -r '.Entrypoint // [] | if type == "string" then [.] else . end | .[]' "$meta")
mapfile -t cmd   < <(jq -r '.Cmd // [] | if type == "string" then [.] else . end | .[]' "$meta")
workdir=$(jq -r '.WorkingDir // ""' "$meta")
userspec=$(jq -r '.User // ""' "$meta")

argv=("${entry[@]}" "${cmd[@]}")
[ "${#argv[@]}" -gt 0 ] || { echo "no entrypoint or command in $meta"; exit 1; }

mapfile -t envs < <(jq -r '.Env // [] | .[]' "$meta")
printf '%s\n' "${envs[@]}" | grep -q '^PATH=' \
  || envs+=("PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
mapfile -t ours < "$RUN/$svc.env"
envs+=("${ours[@]}")

if [ "$native" = 1 ]; then
  [ -n "$workdir" ] || workdir=/
  mkdir -p "$workdir"
  echo "starting (native, in $workdir): ${argv[*]}"
  exec /usr/bin/env -i -C "$workdir" "${envs[@]}" "${argv[@]}"
fi

resolve_ids() {
  local spec=$1 u g uid gid
  [ -n "$spec" ] || return 0
  u=${spec%%:*}
  g=""
  [[ $spec == *:* ]] && g=${spec#*:}
  if [[ $u =~ ^[0-9]+$ ]]; then
    uid=$u
    gid=$(awk -F: -v x="$u" '$3==x {print $4; exit}' "$root/etc/passwd" 2>/dev/null || true)
    gid=${gid:-$u}
  else
    local line
    line=$(awk -F: -v x="$u" '$1==x {print $3":"$4; exit}' "$root/etc/passwd" 2>/dev/null || true)
    [ -n "$line" ] || { echo "user '$u' not found in $root/etc/passwd" >&2; return 1; }
    uid=${line%%:*}
    gid=${line#*:}
  fi
  if [ -n "$g" ]; then
    if [[ $g =~ ^[0-9]+$ ]]; then
      gid=$g
    else
      gid=$(awk -F: -v x="$g" '$1==x {print $3; exit}' "$root/etc/group" 2>/dev/null || true)
      [ -n "$gid" ] || { echo "group '$g' not found in $root/etc/group" >&2; return 1; }
    fi
  fi
  echo "$uid:$gid"
}

ids=$(resolve_ids "$userspec")
us=""
if [ -n "$ids" ] && [ "$ids" != "0:0" ]; then
  us=$ids
fi

if [ -n "$workdir" ] && [ "$workdir" != "/" ]; then
  argv=(/bin/sh -c 'cd "$1" && shift && exec "$@"' sh "$workdir" "${argv[@]}")
fi

readers=$RUN/$svc.readers
if [ -f "$readers" ]; then
  while read -r p; do kill "$p" 2>/dev/null || true; done < "$readers"
  pkill -f "^cat $root/dev/(stdout|stderr)\$" 2>/dev/null || true
fi
: > "$readers"
for f in stdout stderr; do
  if [ -p "$root/dev/$f" ]; then
    ( while :; do cat "$root/dev/$f"; done ) &
    echo $! >> "$readers"
  fi
done

echo "starting: ${argv[*]}"
exec /usr/bin/env -i "${envs[@]}" /usr/sbin/chroot ${us:+--userspec="$us"} "$root" "${argv[@]}"
