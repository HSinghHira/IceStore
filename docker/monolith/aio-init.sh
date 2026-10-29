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

# ---- public address ----
# Monolith's gateway only accepts an https:// address, or http:// on
# localhost, and its sign-in cookies are Secure. So from other devices it
# needs an https address (a reverse proxy or Tailscale). Anything else is
# run on localhost and every other address gets a note instead of a sign-in
# that silently fails.
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6138}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
host=${hostport%:*}
case $PUBLIC_URL in
  https://*) ;;
  http://localhost*|http://127.0.0.1*) ;;
  *)
    log "PUBLIC_URL is $PUBLIC_URL, but Monolith only works on an https:// address (or http://localhost on the ZimaOS box)."
    log "Put Monolith behind a reverse proxy with https and set PUBLIC_URL to that address. Running on http://localhost:6138 until then."
    PUBLIC_URL=http://localhost:6138
    host=localhost ;;
esac
if [ "$host" = localhost ] || [ "$host" = 127.0.0.1 ]; then
  log "PUBLIC_URL is $PUBLIC_URL: Monolith works on the ZimaOS box only. Other devices need an https address in PUBLIC_URL."
fi

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/storage"
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

# Hex values, as upstream asks: they are URL-safe inside the database URLs.
ensure_secret MONOLITH_DB_ADMIN_PASSWORD 24
ensure_secret MONOLITH_DB_APP_PASSWORD 24
ensure_secret MASTER_KEY 32
ensure_secret JWT_SIGNING_KEY 32

DB_ADMIN_PASSWORD=$(secret MONOLITH_DB_ADMIN_PASSWORD)
DB_APP_PASSWORD=$(secret MONOLITH_DB_APP_PASSWORD)
MASTER_KEY_V=$(secret MASTER_KEY)
JWT_KEY_V=$(secret JWT_SIGNING_KEY)

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' monolith_db' "$HOSTS"; then
  echo "127.0.0.1 db server gateway monolith_db" >> "$HOSTS"
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

  # APP-SPECIFIC: uploaded files and add-ons (storage/addons) live in /data,
  # so they survive image updates.
  if [ "$(basename "$d")" = server ]; then
    mkdir -p "$d/monolith/storage"
    mountpoint -q "$d/monolith/storage" || mount --bind "$DATA/storage" "$d/monolith/storage" 2>/dev/null \
      || log "warning: could not mount $DATA/storage into the server"
    uid=$(awk -F: '$1=="node"{print $3":"$4}' "$d/etc/passwd" 2>/dev/null || true)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/storage"
  fi
done

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3636 8090 5432 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

# PUBLIC_URL on localhost: any other address gets a note, not a broken sign-in.
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1) cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Monolith is not set up for this address.\n\nMonolith only signs you in on an https:// address (or on http://localhost on the ZimaOS box itself).\n\nPut Monolith behind a reverse proxy with https (or Tailscale), then open the Monolith app settings in ZimaOS, set PUBLIC_URL to that https address and save.\n";
}
EOF
    ;;
  *) : > "$GUARD_FILE" ;;
esac
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@GUARD_FILE@/$(sed_escape "$GUARD_FILE")/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

APP_DB_URL="postgres://monolith_app:${DB_APP_PASSWORD}@127.0.0.1:5432/monolith"
ADMIN_DB_URL="postgres://postgres:${DB_ADMIN_PASSWORD}@127.0.0.1:5432/monolith"

# From upstream's docker-compose.yml: the migrate and server services.
write_env server "$TZV" \
  "DATABASE_URL=$APP_DB_URL" \
  "DATABASE_ADMIN_URL=$ADMIN_DB_URL" \
  "MONOLITH_DB_APP_USER=monolith_app" \
  "MASTER_KEY=$MASTER_KEY_V" \
  "JWT_SIGNING_KEY=$JWT_KEY_V" \
  "CORS_ALLOWED_ORIGINS=$PUBLIC_URL" \
  "MONOLITH_PUBLIC_URL=$PUBLIC_URL" \
  "FILE_STORAGE_LOCAL_PATH=/monolith/storage" \
  "MONOLITH_CORE_ONLY=${MONOLITH_CORE_ONLY:-0}"

# From upstream's docker-compose.yml: the gateway service.
write_env edge "$TZV" \
  "GATEWAY_ADDRESS=127.0.0.1:8090" \
  "PUBLIC_URL=$PUBLIC_URL" \
  "PRIVATE_API_URL=http://127.0.0.1:3636" \
  "WEB_ROOT=/monolith/apps/web/dist" \
  "DATABASE_URL=$APP_DB_URL" \
  "MASTER_KEY=$MASTER_KEY_V" \
  "JWT_SIGNING_KEY=$JWT_KEY_V" \
  "SERVER_NAME=${SERVER_NAME:-monolith}"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional setting from the README Variables list, by its own name.
pass_env server 'MONOLITH_AUTH_ADMIN_IDS|MONOLITH_ADDON_[A-Z_]+|ROOMS_TURN_URLS|ROOMS_TURN_SECRET|FILE_UPLOAD_MAX_BYTES'
pass_env edge 'BOOTSTRAP_TOKEN'

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
pgbin=/usr/lib/postgresql/17/bin
id postgres >/dev/null
mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql "$DATA/postgres"
chmod 700 "$DATA/postgres"

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$DB_ADMIN_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  # Upstream's docker/server/init-db.sh: the restricted application role.
  # migrate.sh (run before the server on every start) makes the tables and
  # grants this role what it needs.
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses=''" -w start >/dev/null
  setpriv --reuid=postgres --regid=postgres --init-groups \
    psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
      -v app_password="$DB_APP_PASSWORD" <<'SQL'
CREATE DATABASE monolith;
CREATE ROLE monolith_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS PASSWORD :'app_password';
GRANT CONNECT ON DATABASE monolith TO monolith_app;
SQL
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
