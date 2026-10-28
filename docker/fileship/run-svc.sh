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
    pg)     /usr/lib/postgresql/16/bin/pg_isready -q -h 127.0.0.1 -p 5432 ;;
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
# Fileship runs its database migrations before it starts listening, and
# /api/healthz answers 503 until its start-up tasks are done, so the gateway
# (and the container health) only goes green once the app is ready.
case $svc in
  fileship) wait_all pg ;;
  admin)    wait_all http://127.0.0.1:3000/api/healthz ;;
  gateway)  wait_all http://127.0.0.1:3000/api/healthz ;;
  *) ;;
esac

# ---- APP-SPECIFIC: built-in services (installed with apt in the Dockerfile) ----
case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups \
      /usr/lib/postgresql/16/bin/postgres -D "$DATA/postgres" \
      -c listen_addresses=127.0.0.1 -c unix_socket_directories=/run/postgresql
    ;;
  admin)
    # On first start Fileship makes the account admin / password (argon2
    # hash). While that account still has the password "password", give it
    # this install's password (ADMIN_PASSWORD, or the one made on first
    # start). Once you change the password in Fileship, this does nothing.
    load_env "$RUN/admin.env"
    psql_db() {
      setpriv --reuid=postgres --regid=postgres --init-groups \
        psql -h /run/postgresql -U postgres -d fileship -v ON_ERROR_STOP=1 -Atq "$@"
    }
    # Hashing and checking use Fileship's own argon2 module and node, inside
    # its filesystem, so the hash is exactly the kind it checks at sign-in.
    # MODE=verify prints yes/no for PW against H; MODE=hash prints a new hash.
    argon() {
      /usr/bin/env -i PATH=/usr/local/bin:/usr/bin:/bin "$@" \
        /usr/sbin/chroot "$ROOTFS/fileship" node -e '
          const a = require("/fileship/apps/dashboard/.output/server/node_modules/argon2");
          const e = process.env;
          (e.MODE === "verify" ? a.verify(e.H, e.PW).then((ok) => (ok ? "yes" : "no")) : a.hash(e.PW))
            .then((out) => process.stdout.write(out))
            .catch((err) => { console.error(err.message); process.exit(1); });'
    }
    # The account is made by a start-up task; give it a moment.
    current=""
    for _ in $(seq 1 30); do
      current=$(printf '%s\n' "SELECT password FROM \"User\" WHERE username = 'admin' AND \"superAdmin\" LIMIT 1;" \
        | psql_db) || current=""
      [ -n "$current" ] && break
      sleep 2
    done
    [ -n "$current" ] || { echo "no admin account with a password: nothing to do"; exit 0; }
    still_default=$(argon MODE=verify H="$current" PW=password) || { echo "could not check the admin password"; exit 1; }
    [ "$still_default" = yes ] || exit 0
    hash=$(argon MODE=hash PW="$ADMIN_PASSWORD") || { echo "could not hash the admin password"; exit 1; }
    updated=$(printf '%s\n' "UPDATE \"User\" SET password = :'h' WHERE username = 'admin' AND password = :'old' RETURNING id;" \
      | psql_db -v h="$hash" -v old="$current") || { echo "could not set the admin password"; exit 1; }
    if [ -n "$updated" ]; then
      echo "the default admin / password login is gone: sign in as admin with the password on the \"Fileship login is\" line above"
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
