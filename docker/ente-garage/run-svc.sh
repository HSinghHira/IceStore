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

exec > >(sed -u "s/^/[$svc] /") 2>&1

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

as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

# ---- APP-SPECIFIC: what each service waits for before it starts ----
# Specs: pg | tcp:<port> | http://127.0.0.1:<port>/<health path> | sock:<unix socket file>
# museum runs its database migrations before it answers /ping, so the gateway
# (and the container health) only goes green once the API is ready.
case $svc in
  museum)  wait_all pg tcp:3900 tcp:1025 ;;
  s3init)  wait_all tcp:3900 tcp:3903 ;;
  quota)   wait_all pg http://127.0.0.1:8090/ping ;;
  gateway) wait_all http://127.0.0.1:8090/ping tcp:3000 tcp:3002 ;;
  *) ;;
esac

# Puts each Ente bucket with a signed S3 request; 409 means it is already there.
make_buckets() {
  local b code tries
  for b in b2-eu-cen wasabi-eu-central-2-v3 scw-eu-fr-v3; do
    tries=0
    while :; do
      code=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H 'Content-Length: 0' \
        --aws-sigv4 "aws:amz:$S3_REGION:s3" --user "$S3_KEY:$S3_SECRET" \
        "http://127.0.0.1:$S3_PORT/$b" || true)
      case $code in
        200|409) echo "bucket $b is ready"; break ;;
      esac
      tries=$((tries + 1))
      [ "$tries" -lt 60 ] || { echo "could not create bucket $b (HTTP $code)"; exit 1; }
      sleep 2
    done
  done
}

# ---- APP-SPECIFIC: built-in services (installed with apt in the Dockerfile) ----
case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups \
      /usr/lib/postgresql/15/bin/postgres -D "$DATA/postgres" \
      -c listen_addresses=127.0.0.1 -c unix_socket_directories=/run/postgresql
    ;;
  s3init)
    # Garage starts empty: give this node a role in the cluster layout, import
    # Ente's key and make the buckets, through Garage's admin API (v2). Every
    # step checks first, so it is safe on every start.
    load_env "$RUN/s3init.env"
    api() {
      if [ $# -gt 1 ]; then
        curl -fsS -H "Authorization: Bearer $GARAGE_ADMIN_TOKEN" -H 'Content-Type: application/json' \
          -d "$2" "http://127.0.0.1:3903/v2/$1"
      else
        curl -fsS -H "Authorization: Bearer $GARAGE_ADMIN_TOKEN" "http://127.0.0.1:3903/v2/$1"
      fi
    }
    until status=$(api GetClusterStatus 2>/dev/null); do sleep 2; done
    node=$(jq -r '.nodes[0].id' <<<"$status")
    if [ "$(jq '[.nodes[] | select(.role != null)] | length' <<<"$status")" = 0 ]; then
      echo "giving node $node a role in the cluster layout"
      api UpdateClusterLayout "$(jq -nc --arg id "$node" --argjson cap "$GARAGE_CAPACITY" \
        '{roles: [{id: $id, zone: "zima", capacity: $cap, tags: []}]}')" >/dev/null
      version=$(api GetClusterLayout | jq '.version')
      api ApplyClusterLayout "{\"version\": $((version + 1))}" >/dev/null
      sleep 3
    fi
    if ! api "GetKeyInfo?id=$S3_KEY" >/dev/null 2>&1; then
      api ImportKey "$(jq -nc --arg k "$S3_KEY" --arg s "$S3_SECRET" \
        '{accessKeyId: $k, secretAccessKey: $s, name: "ente"}')" >/dev/null
      echo "imported the ente key"
    fi
    for b in b2-eu-cen wasabi-eu-central-2-v3 scw-eu-fr-v3; do
      id=$(api "GetBucketInfo?globalAlias=$b" 2>/dev/null | jq -r '.id // empty' || true)
      [ -n "$id" ] || id=$(api CreateBucket "{\"globalAlias\": \"$b\"}" | jq -r '.id')
      api AllowBucketKey "$(jq -nc --arg b "$id" --arg k "$S3_KEY" \
        '{bucketId: $b, accessKeyId: $k, permissions: {read: true, write: true, owner: true}}')" >/dev/null
      echo "bucket $b is ready"
    done
    exit 0
    ;;
  quota)
    # Ente gives every account its 10 GB free plan. Once a minute, raise any
    # account below ENTE_AIO_STORAGE_GB to it (0 = keep Ente's own limits).
    load_env "$RUN/quota.env"
    if [ "${STORAGE_BYTES:-0}" = 0 ]; then
      echo "keeping Ente's own storage limits"
      exec sleep infinity
    fi
    echo "every account gets $((STORAGE_BYTES / 1073741824)) GB of storage"
    while :; do
      as_pg /usr/lib/postgresql/15/bin/psql -h /run/postgresql -U postgres -d ente_db -q -v ON_ERROR_STOP=1 \
        -c "UPDATE subscriptions SET storage = $STORAGE_BYTES WHERE storage < $STORAGE_BYTES;" >/dev/null 2>&1 || true
      sleep 60
    done
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
