#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each
# service's environment, prepares the database, then hands over to
# supervisord.
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

# ---- public address: Tianji's PUBLIC_URL (links in emails, OAuth callbacks) ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6163}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. Tracking scripts and links only work on this server;"
    log "set PUBLIC_URL to the address you open Tianji at, like http://192.168.1.20:6163" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres"
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

# PG_PASSWORD: postgres superuser. TIANJI_DB_PASSWORD: the "tianji" role.
# JWT_SECRET signs sign-ins; upstream makes a new one on every start when it
# is blank, which signs everyone out, so it is kept here instead.
# ADMIN_PASSWORD replaces the default admin / admin login.
ensure_secret PG_PASSWORD 16
ensure_secret TIANJI_DB_PASSWORD 16
ensure_secret JWT_SECRET 32
ensure_secret ADMIN_PASSWORD 9
PG_PASSWORD=$(secret PG_PASSWORD)
TIANJI_DB_PASSWORD=$(secret TIANJI_DB_PASSWORD)

# Admin login: ADMIN_PASSWORD from the app settings wins; blank means the one
# made on first start. It only replaces the password while it is still
# "admin"; after you change it in Tianji, this has no effect.
ADMIN_PW=${ADMIN_PASSWORD:-$(secret ADMIN_PASSWORD)}
ADMIN_LOGIN_FILE=$DATA/admin-password.txt
if [ -n "${ADMIN_PASSWORD:-}" ]; then
  log "Tianji login is admin / the ADMIN_PASSWORD you set (until you change the password in Tianji)"
else
  if [ ! -s "$ADMIN_LOGIN_FILE" ]; then
    printf 'Tianji first login\nusername: admin\npassword: %s\n' "$ADMIN_PW" > "$ADMIN_LOGIN_FILE"
    chmod 600 "$ADMIN_LOGIN_FILE"
  fi
  log "Tianji login is admin / $ADMIN_PW (until you change the password in Tianji; also in $ADMIN_LOGIN_FILE)"
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'tianji-postgres' "$HOSTS"; then
  echo "127.0.0.1 postgres tianji tianji-postgres" >> "$HOSTS"
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

  # APP-SPECIFIC: none. Tianji keeps all its data in Postgres.

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
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 5432 8080 12345 "
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
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# From upstream's docker-compose.yml and environment docs, with Postgres on
# 127.0.0.1 and the secret made above.
write_env tianji "$TZV" \
  "NODE_ENV=production" \
  "PORT=12345" \
  "PUBLIC_URL=$PUBLIC_URL" \
  "DATABASE_URL=postgresql://tianji:$TIANJI_DB_PASSWORD@127.0.0.1:5432/tianji" \
  "JWT_SECRET=$(secret JWT_SECRET)" \
  "ALLOW_REGISTER=${ALLOW_REGISTER:-false}" \
  "ALLOW_OPENAPI=${ALLOW_OPENAPI:-true}"

# ---- settings: the README variables: list (Apps/tianji/) ----
# Tianji reads these itself on every start; blank ones are skipped, so they
# mean "default".
pass_env tianji 'DISABLE_AUTO_CLEAR|AUDIT_LOG_RETENTION_DAYS|DISABLE_ACCESS_LOGS|DB_DEBUG|ALPHA_MODE'
pass_env tianji 'ENABLE_FUNCTION_WORKER|REGISTER_AUTO_JOIN_WORKSPACE_ID|CACHE_MEMORY_ONLY|REDIS_URL'
pass_env tianji 'DISABLE_ACCOUNT|AUTH_SECRET|AUTH_RESTRICT_EMAIL|AUTH_USE_SECURE_COOKIES|EMAIL_SERVER|EMAIL_FROM'
pass_env tianji 'AUTH_(GITHUB|GOOGLE)_(ID|SECRET)|AUTH_CUSTOM_(ID|SECRET|NAME|TYPE|ISSUER|ICON)'
pass_env tianji 'SHARED_OPENAI_[A-Z_]+|DEBUG_AI_FEATURE|CLICKHOUSE_[A-Z_]+'
pass_env tianji 'AMAP_TOKEN|MAPBOX_TOKEN|DISABLE_ANONYMOUS_TELEMETRY|CUSTOM_TRACKER_SCRIPT_NAME|USE_VM2|SANDBOX_MEMORY_LIMIT'

write_env admin "ADMIN_PASSWORD=$ADMIN_PW"

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

pgbin=/usr/lib/postgresql/15/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE tianji LOGIN PASSWORD '${TIANJI_DB_PASSWORD}';" \
    -c "CREATE DATABASE tianji OWNER tianji;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
