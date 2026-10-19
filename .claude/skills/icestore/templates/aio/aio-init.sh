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

# ---- public address: default MUST use the app's ledger port ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:__PORT__}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
ADMIN_EMAIL=${ADMIN_EMAIL:-CHANGEME@example.com}
ADMIN_PASSWORD_ENV=${ADMIN_PASSWORD:-}

# ---- APP-SPECIFIC: one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/app"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
NEW_ADMIN_PASSWORD=0
ensure_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -hex "$2")" >> "$SECRETS"
    [ "$1" = ADMIN_PASSWORD ] && NEW_ADMIN_PASSWORD=1
  fi
  return 0
}
secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# APP-SPECIFIC: every secret the services need (name, bytes of randomness)
ensure_secret PG_PASSWORD 16
ensure_secret APP_SECRET_KEY 32
ensure_secret ADMIN_PASSWORD 12

PG_PASSWORD=$(secret PG_PASSWORD)
APP_SECRET_KEY=$(secret APP_SECRET_KEY)
ADMIN_PASSWORD=$(secret ADMIN_PASSWORD)
if [ -n "$ADMIN_PASSWORD_ENV" ]; then
  ADMIN_PASSWORD=$ADMIN_PASSWORD_ENV
elif [ "$NEW_ADMIN_PASSWORD" = 1 ]; then
  log "first start: admin email is $ADMIN_EMAIL"
  log "first start: admin password is $ADMIN_PASSWORD (also saved in $SECRETS)"
fi

# ---- APP-SPECIFIC: hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
# Keeps upstream defaults (like http://app_db:5432) working without rewriting them.
if ! grep -q '__APP___postgres' "$HOSTS"; then
  echo "127.0.0.1 __APP___postgres __APP___redis __APP___app" >> "$HOSTS"
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
# APP-SPECIFIC: every port any service listens on inside the container
INTERNAL_PORTS=" __APP_INTERNAL_PORT__ 5432 6379 "
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
PGURL="postgres://postgres:${PG_PASSWORD}@__APP___postgres:5432/postgres"
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# APP-SPECIFIC: copy the environment block of each service from upstream's
# docker-compose / .env example. Use $PUBLIC_URL for every browser-facing URL
# and 127.0.0.1 or the /etc/hosts names above for service-to-service URLs.
write_env app "$TZV" \
  "DATABASE_URL=$PGURL" \
  "REDIS_URL=redis://__APP___redis:6379" \
  "SECRET_KEY=$APP_SECRET_KEY" \
  "ADMIN_EMAIL=$ADMIN_EMAIL" \
  "ADMIN_PASSWORD=$ADMIN_PASSWORD" \
  "PUBLIC_URL=$PUBLIC_URL"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# APP-SPECIFIC: forward every setting (compose environment: and README
# variables:) that the service reads by its own name (COMPOSE.md section 8).
pass_env app '__APP_PREFIX___[A-Z0-9_]+|SMTP_[A-Z_]+'

# APP-SPECIFIC: settings that live in a config file instead of env vars. Write
# them on every start (skip blank ones) so a change in ZimaOS takes effect.
# set_json() { [ -n "$2" ] || return 0; ... jq into the app's config file ... }

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

# ---- APP-SPECIFIC: built-in data folders and first-start database ----
id postgres >/dev/null
mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql "$DATA/postgres"
chmod 700 "$DATA/postgres"
chown redis:redis "$DATA/redis"

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  setpriv --reuid=postgres --regid=postgres --init-groups \
    /usr/lib/postgresql/16/bin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
