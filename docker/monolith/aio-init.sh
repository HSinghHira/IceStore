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

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

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

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: uploaded files and add-ons (storage/addons) live in /data,
  # so they survive image updates.
  if [ "$(basename "$d")" = server ]; then
    mkdir -p "$d/monolith/storage"
    mountpoint -q "$d/monolith/storage" || mount --bind "$DATA/storage" "$d/monolith/storage" 2>/dev/null \
      || log "warning: could not mount $DATA/storage into the server"
    uid=$(awk -F: '$1=="node"{print $3":"$4}' "$d/etc/passwd" 2>/dev/null || true)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/storage"
  fi
  return 0
}
prep_chroots

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

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "Create your account right away; the first account is the owner."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

# ---- built-in data folders and first-start database ----
pg_setup /usr/lib/postgresql/17/bin

if pg_is_new; then
  log "first start: creating the database"
  PG_PASSWORD=$DB_ADMIN_PASSWORD pg_initdb

  # Upstream's docker/server/init-db.sh: the restricted application role.
  # migrate.sh (run before the server on every start) makes the tables and
  # grants this role what it needs.
  pg_start_local
  pg_psql -v app_password="$DB_APP_PASSWORD" <<'SQL'
CREATE DATABASE monolith;
CREATE ROLE monolith_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS PASSWORD :'app_password';
GRANT CONNECT ON DATABASE monolith TO monolith_app;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
