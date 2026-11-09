#!/bin/bash
# Starts one service. Usage: run-svc <name>
# Three kinds of service:
#   built-in  - installed in the base image with apt (postgres, valkey, nginx gateway, ...).
#               Started by an explicit command in the "built-in" case below.
#   native    - a binary copied out of its upstream image into the base image (NATIVE list).
#   chroot    - everything else: runs inside its own upstream image's filesystem under
#               /opt/rootfs/<name>.
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
    file:*) [ -f "${1#file:}" ] ;;
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
# Specs: pg | tcp:<port> | http://127.0.0.1:<port>/<health path> | file:<path>
# From upstream's depends_on. NATS 8222, SeaweedFS S3 8333, Meilisearch 7700,
# the id/user/gif/message services 8110-8113, the API 8100. s3init leaves
# $RUN/s3-ready when the buckets exist. The gateway (and so the container
# health) waits for the API.
NATS=http://127.0.0.1:8222/healthz
S3=file:$RUN/s3-ready
SVCS="http://127.0.0.1:8110/_health http://127.0.0.1:8111/_health http://127.0.0.1:8112/_health http://127.0.0.1:8113/_health"
case $svc in
  s3init)     wait_all http://127.0.0.1:8333/healthz ;;
  snowflakes|gifs|unfurl) wait_all $NATS ;;
  users|messages) wait_all $NATS pg ;;
  api)        wait_all pg tcp:6379 $NATS http://127.0.0.1:7700/health "$S3" $SVCS ;;
  worker)     wait_all pg tcp:6379 $NATS "$S3" $SVCS ;;
  realtime)   wait_all $NATS tcp:6379 ;;
  media)      wait_all $NATS "$S3" ;;
  push)       wait_all $NATS http://127.0.0.1:8100/_health ;;
  admin)      wait_all http://127.0.0.1:8100/_health ;;
  app)        wait_all http://127.0.0.1:8100/_health ;;
  gateway)    wait_all http://127.0.0.1:8100/_health ;;
  *) ;;
esac

# Puts each bucket with a signed S3 request; 409 means it is already there.
make_buckets() {
  local b code tries
  for b in $S3_BUCKETS; do
    tries=0
    while :; do
      code=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H 'Content-Length: 0' \
        --aws-sigv4 "aws:amz:$S3_REGION:s3" --user "$S3_KEY:$S3_SECRET" \
        "http://127.0.0.1:8333/$b" || true)
      case $code in
        200|409) echo "bucket $b is ready"; break ;;
      esac
      tries=$((tries + 1))
      [ "$tries" -lt 60 ] || { echo "could not create bucket $b (HTTP $code)"; exit 1; }
      sleep 2
    done
  done
}

# Runs one "weed shell" command inside the SeaweedFS files.
weed_shell() {
  echo "$1" | /usr/sbin/chroot "$ROOTFS/seaweedfs" /usr/bin/env PATH=/usr/bin:/bin \
    timeout 30 weed shell -master=127.0.0.1:9333
}

# ---- APP-SPECIFIC: built-in services (installed with apt in the Dockerfile) ----
case $svc in
  postgres)
    load_env "$RUN/postgres.env"
    exec setpriv --reuid=postgres --regid=postgres --init-groups \
      /usr/lib/postgresql/16/bin/postgres -D "$DATA/postgres" \
      -c listen_addresses=127.0.0.1 -c unix_socket_directories=/run/postgresql \
      -c max_connections=150 -c shared_buffers="$PG_SHARED_BUFFERS" \
      -c effective_cache_size=1GB -c work_mem=8MB -c maintenance_work_mem=128MB \
      -c random_page_cost=1.1 -c jit=off -c max_wal_size=1GB \
      -c wal_compression=zstd -c shared_preload_libraries=pg_stat_statements
    ;;
  valkey)
    exec setpriv --reuid=valkey --regid=valkey --init-groups \
      valkey-server --bind 127.0.0.1 --port 6379 --dir "$DATA/valkey" \
      --appendonly yes --appendfsync everysec --save "" \
      --maxmemory 192mb --maxmemory-policy noeviction
    ;;
  s3init)
    load_env "$RUN/s3init.env"
    rm -f "$RUN/s3-ready"
    make_buckets
    # Upstream's seaweedfs-init: unfinished uploads expire after a day.
    if [ "$UPLOADS_TTL" = off ]; then
      rule="fs.configure -locationPrefix=/buckets/fluxer-uploads/ -delete -apply"
    else
      rule="fs.configure -locationPrefix=/buckets/fluxer-uploads/ -ttl=$UPLOADS_TTL -apply"
    fi
    weed_shell "$rule" >/dev/null 2>&1 || echo "could not set the expiry of fluxer-uploads (uploads still work)"
    : > "$RUN/s3-ready"
    echo "buckets ready"
    exit 0
    ;;
  gateway)
    exec nginx -c /etc/nginx/aio.conf -g 'daemon off;'
    ;;
esac

# ---- generic from here down: native and chroot services ----
native=0
case " $NATIVE " in *" $svc "*) native=1 ;; esac

# APP-SPECIFIC: the worker runs from the api's files and start-up config.
from=$svc
case $svc in
  worker) from=api ;;
esac

root=$ROOTFS/$from
meta=$META/$from.json
[ "$native" = 1 ] || [ -d "$root" ] || { echo "missing $root"; exit 1; }
[ -f "$meta" ] || { echo "missing $meta (run capture-meta.sh before building)"; exit 1; }

mapfile -t entry < <(jq -r '.Entrypoint // [] | if type == "string" then [.] else . end | .[]' "$meta")
mapfile -t cmd   < <(jq -r '.Cmd // [] | if type == "string" then [.] else . end | .[]' "$meta")
workdir=$(jq -r '.WorkingDir // ""' "$meta")
userspec=$(jq -r '.User // ""' "$meta")

# ---- APP-SPECIFIC: start-up tweaks ----
# The commands upstream's compose file sets: the worker entrypoint, NATS and
# LiveKit with the config files aio-init writes, SeaweedFS as one
# "weed server" on 127.0.0.1 (its volume server moves off 8080, the gateway's).
# Meilisearch, NATS and SeaweedFS run as root, as in their images.
case $svc in
  worker)
    cmd=(node dist/WorkerEntrypoint.js)
    ;;
  nats)
    entry=()
    cmd=(nats-server -c /etc/nats-aio.conf)
    ;;
  livekit)
    cmd=(--config /etc/livekit.yml)
    ;;
  seaweedfs)
    entry=()
    cmd=(weed server -dir=/data -ip=127.0.0.1 -ip.bind=127.0.0.1
         -master.port=9333 -master.telemetry=false -master.volumeSizeLimitMB=1024
         -master.garbageThreshold=0.1
         -volume.port=8085 -volume.max=10000
         -filer -filer.port=8888
         -s3 -s3.port=8333 -s3.config=/etc/seaweedfs/s3.json -s3.concurrentFileUploadLimit=5)
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

# Readers for programs that write to /dev/stdout by path. The worker shares
# the api's files, so only the api owns their readers.
if [ "$svc" != worker ]; then
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
fi

echo "starting: ${argv[*]}"
exec /usr/bin/env -i "${envs[@]}" /usr/sbin/chroot ${us:+--userspec="$us"} "$root" "${argv[@]}"
