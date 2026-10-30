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
# The api runs the database migrations before gunicorn starts listening, so
# the worker, the setup job and the gateway (and the container health) wait
# for it.
case $svc in
  api)     wait_all pg tcp:6379 ;;
  worker)  wait_all pg tcp:6379 http://127.0.0.1:8000/admin/login/ ;;
  setup)   wait_all http://127.0.0.1:8000/admin/login/ ;;
  gateway) wait_all http://127.0.0.1:8000/admin/login/ ;;
  *) ;;
esac

# ---- APP-SPECIFIC: built-in services (installed with apt in the Dockerfile) ----
case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups \
      /usr/lib/postgresql/16/bin/postgres -D "$DATA/postgres" \
      -c listen_addresses=127.0.0.1 -c unix_socket_directories=/run/postgresql
    ;;
  redis)
    # Cache and Celery broker. Snapshots so queued jobs survive a restart;
    # never evict queued jobs.
    exec setpriv --reuid=redis --regid=redis --init-groups \
      redis-server --bind 127.0.0.1 --port 6379 --dir "$DATA/redis" \
      --save "900 1" --save "300 10" --appendonly no --maxmemory-policy noeviction
    ;;
  setup)
    # Runs upstream's create_initial_organization once, while there is no
    # organization yet. After that this does nothing, so a password you
    # change in TutorLoom is never reset.
    orgs=$(setpriv --reuid=postgres --regid=postgres --init-groups \
      psql -h /run/postgresql -U postgres -d tutorloom -Atq \
      -c "SELECT count(*) FROM organizations_organization;") || { echo "could not read the database"; exit 1; }
    if [ "$orgs" != 0 ]; then
      exit 0
    fi
    echo "first start: making the first organization and the admin account"
    ;;
  gateway)
    exec nginx -c /etc/nginx/aio.conf -g 'daemon off;'
    ;;
esac

# ---- generic from here down: native and chroot services ----
native=0
case " $NATIVE " in *" $svc "*) native=1 ;; esac

root=$ROOTFS/$svc
# APP-SPECIFIC: worker and setup live in the api's filesystem.
case $svc in worker|setup) root=$ROOTFS/api ;; esac
meta=$META/$svc.json
[ "$svc" = setup ] && meta=$META/api.json
[ "$native" = 1 ] || [ -d "$root" ] || { echo "missing $root"; exit 1; }
[ -f "$meta" ] || { echo "missing $meta (run capture-meta.sh before building)"; exit 1; }

mapfile -t entry < <(jq -r '.Entrypoint // [] | if type == "string" then [.] else . end | .[]' "$meta")
mapfile -t cmd   < <(jq -r '.Cmd // [] | if type == "string" then [.] else . end | .[]' "$meta")
workdir=$(jq -r '.WorkingDir // ""' "$meta")
userspec=$(jq -r '.User // ""' "$meta")

# APP-SPECIFIC: the commands from upstream's compose. gunicorn instead of
# the dev server (upstream lists gunicorn in requirements.txt for this),
# on 127.0.0.1 only; the gateway is the way in.
case $svc in
  api)
    cmd=(/bin/sh -c 'python manage.py migrate --noinput && exec gunicorn lms_core.wsgi:application --bind 127.0.0.1:8000 --workers "$TUTORLOOM_WEB_WORKERS" --timeout 120 --access-logfile -')
    ;;
  worker)
    cmd=(/bin/sh -c 'exec celery -A lms_core worker -l info --concurrency "$TUTORLOOM_WORKER_CONCURRENCY"')
    ;;
  setup)
    cmd=(/bin/sh -c 'exec python manage.py create_initial_organization --name "$TUTORLOOM_ORG_NAME" --admin-email "$ADMIN_EMAIL" --password "$ADMIN_PASSWORD" --first-name Admin --batch-name "$TUTORLOOM_BATCH_NAME"')
    ;;
esac

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
