#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each service's
# environment, prepares the database, then hands over to supervisord.
set -euo pipefail

DATA=${AIO_DATA:-/data}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}
HOSTS=${AIO_HOSTS:-/etc/hosts}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/aio.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/aio.conf}
GATEWAY_PORT=8080

log() { echo "[init] $*"; }

# ---- public address: default uses the app's IceStore port ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6102}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac

# ---- one folder per stateful service under /data ----
# affine/ is bind-mounted over /root/.affine inside the AFFiNE chroot, so it
# holds config/ (config.json, private.key) and storage/ (uploaded files).
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" \
         "$DATA/affine/config" "$DATA/affine/storage"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -hex "$2")" >> "$SECRETS"
  fi
  return 0
}
secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# PG_PASSWORD: postgres superuser. AFFINE_DB_PASSWORD: the "affine" role.
# AFFiNE makes its own signing key (config/private.key) on first start.
ensure_secret PG_PASSWORD 16
ensure_secret AFFINE_DB_PASSWORD 16
PG_PASSWORD=$(secret PG_PASSWORD)
AFFINE_DB_PASSWORD=$(secret AFFINE_DB_PASSWORD)

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'affine_postgres' "$HOSTS"; then
  echo "127.0.0.1 affine_postgres affine_redis affine_server" >> "$HOSTS"
fi

# ---- first start: AFFiNE's own config.json (upstream's self-host example) ----
# The server name and the search indexer live here. Edit it later from the
# admin panel, or in /data/affine/config/config.json.
if [ ! -s "$DATA/affine/config/config.json" ]; then
  log "first start: writing $DATA/affine/config/config.json"
  cat > "$DATA/affine/config/config.json" <<'JSON'
{
  "$schema": "https://github.com/toeverything/affine/releases/latest/download/config.schema.json",
  "deployment": {
    "type": "selfhosted"
  },
  "server": {
    "name": "AFFiNE Self Hosted Server"
  },
  "indexer": {
    "enabled": true,
    "provider.type": "embedded"
  }
}
JSON
fi

# ---- generic: prepare every chroot filesystem under /opt/rootfs ----
for d in "$ROOTFS"/*/; do
  [ -d "$d" ] || continue
  mkdir -p "$d/dev" "$d/etc" "$d/tmp" "$d/proc" "$d/sys"
  chmod 1777 "$d/tmp"
  cat "$HOSTS" > "$d/etc/hosts"
  [ -f /etc/resolv.conf ] && cat /etc/resolv.conf > "$d/etc/resolv.conf"

  if ! mountpoint -q "$d/proc"; then
    mount -t proc proc "$d/proc" 2>/dev/null || mount --rbind /proc "$d/proc" 2>/dev/null || {
      err=$(mount --rbind /proc "$d/proc" 2>&1 || true)
      log "warning: could not mount proc into $d/proc: $err"
    }
  fi
  mountpoint -q "$d/sys" || mount --rbind /sys "$d/sys" 2>/dev/null || true
  mkdir -p "$d/dev/shm"
  mountpoint -q "$d/dev/shm" || mount -t tmpfs tmpfs "$d/dev/shm" 2>/dev/null || true
  chmod 1777 "$d/dev/shm" 2>/dev/null || true
  [ -e "$d/dev/fd" ] || ln -s /proc/self/fd "$d/dev/fd" 2>/dev/null || true
  if [ -f "$d/proc/version" ]; then
    log "$d procfs mounted successfully"
  else
    log "WARNING: $d procfs is NOT mounted"
  fi

  # APP-SPECIFIC: AFFiNE keeps everything under /root/.affine (it runs as root).
  # Without this mount its files would live in the image and vanish on update.
  if [ "$(basename "$d")" = affine ]; then
    mkdir -p "$d/root/.affine"
    if ! mountpoint -q "$d/root/.affine"; then
      mount --bind "$DATA/affine" "$d/root/.affine" 2>/dev/null \
        || log "WARNING: could not bind $DATA/affine to $d/root/.affine; files will not survive an update"
    fi
  fi

  [ -e "$d/dev/null" ]    || mknod -m 666 "$d/dev/null" c 1 3    2>/dev/null || log "warning: could not create $d/dev/null"
  [ -e "$d/dev/zero" ]    || mknod -m 666 "$d/dev/zero" c 1 5    2>/dev/null || true
  [ -e "$d/dev/random" ]  || mknod -m 666 "$d/dev/random" c 1 8  2>/dev/null || true
  [ -e "$d/dev/urandom" ] || mknod -m 666 "$d/dev/urandom" c 1 9 2>/dev/null || true
  [ -e "$d/dev/stdin" ] || : > "$d/dev/stdin"
  for f in stdout stderr; do
    [ -p "$d/dev/$f" ] && continue
    rm -f "$d/dev/$f"
    mkfifo -m 666 "$d/dev/$f" 2>/dev/null || : > "$d/dev/$f"
  done
done

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3010 5432 6379 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# From upstream's .docker/selfhost/compose.yml (affine + affine_migration).
# The migration job runs right before the server, in the same service (run-svc.sh).
write_env affine "$TZV" \
  "HOME=/root" \
  "NODE_ENV=production" \
  "DEPLOYMENT_TYPE=selfhosted" \
  "DATABASE_URL=postgresql://affine:${AFFINE_DB_PASSWORD}@affine_postgres:5432/affine" \
  "REDIS_SERVER_HOST=affine_redis" \
  "REDIS_SERVER_PORT=6379" \
  "AFFINE_SERVER_EXTERNAL_URL=$PUBLIC_URL" \
  "LISTEN_ADDR=127.0.0.1" \
  "AFFINE_SERVER_PORT=3010"

# Pass through mail and AFFINE_* settings set on the container. Empty values
# are skipped, so a blank MAILER_PORT in the app settings changes nothing.
env | grep -E '^(MAILER|AFFINE)_[A-Z0-9_]+=.' | grep -vE '^AFFINE_(SERVER_PORT|SERVER_EXTERNAL_URL)=' >> "$RUN/affine.env" || true

# Files in /data/state/overrides/<service>.env are appended last, so users can
# change any service setting without rebuilding the image.
for f in "$STATE"/overrides/*.env; do
  [ -f "$f" ] || continue
  svc=$(basename "$f" .env)
  log "applying your overrides to $svc"
  cat "$f" >> "$RUN/$svc.env"
done

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

# ---- built-in data folders and first-start database ----
id postgres >/dev/null
mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql "$DATA/postgres"
chmod 700 "$DATA/postgres"
chown redis:redis "$DATA/redis"

pgbin=/usr/lib/postgresql/16/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  # Upstream's "affine" user is the Postgres superuser (POSTGRES_USER=affine),
  # and the migrations run CREATE EXTENSION vector, so it stays a superuser here.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE affine LOGIN SUPERUSER PASSWORD '${AFFINE_DB_PASSWORD}';" \
    -c "CREATE DATABASE affine OWNER affine;"
  as_pg $pgbin/psql -h /run/postgresql -U postgres -d affine -v ON_ERROR_STOP=1 -q \
    -c "CREATE EXTENSION IF NOT EXISTS vector;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
