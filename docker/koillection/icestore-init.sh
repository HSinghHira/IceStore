#!/bin/bash
# IceStore start script for Koillection. Runs as root, once per start:
#
#   - /data/secrets.env: the database password, APP_SECRET and the JWT
#     passphrase, made on first start. Upstream makes a new APP_SECRET and
#     JWT passphrase on every start, which signs everyone out and breaks
#     the API keys.
#   - /data/jwt: the JWT key pair (upstream keeps it inside the container).
#   - first start: initdb and the koillection database and role.
#
# Then supervisord runs PostgreSQL and upstream's entrypoint (svc.sh), which
# runs the migrations and serves Koillection on port 80.
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres" "$DATA/jwt" /uploads
umask 077
touch "$SECRETS"

# ---- settings left blank in ZimaOS: use upstream's defaults ----
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do
  case $v in
    APP_*|JWT_*|CORS_*|PHP_*|UPLOAD_*|HTTPS_*|FRANKENPHP_*|CADDY_*) unset "$v" ;;
  esac
done

# ---- secrets ----
ensure_secret DB_PASSWORD 24
ensure_secret APP_SECRET 21
ensure_secret JWT_PASSPHRASE 21
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
DB_PASSWORD=$(secret DB_PASSWORD)
[ -n "${APP_SECRET:-}" ] || APP_SECRET=$(secret APP_SECRET)
[ -n "${JWT_PASSPHRASE:-}" ] || JWT_PASSPHRASE=$(secret JWT_PASSPHRASE)
export DB_PASSWORD APP_SECRET JWT_PASSPHRASE
umask 022

# Keep the JWT keys in /data so they survive updates (upstream makes them in
# config/jwt with --skip-if-exists).
if [ ! -L /app/public/config/jwt ]; then
  rm -rf /app/public/config/jwt
  ln -s "$DATA/jwt" /app/public/config/jwt
fi
chown -R "${PUID:-1001}:${PGID:-1001}" "$DATA/jwt"

# Plain http by default; set HTTPS_ENABLED=1 behind a reverse proxy with https.
export HTTPS_ENABLED=${HTTPS_ENABLED:-0}
export PHP_TZ=${PHP_TZ:-${TZ:-UTC}}

# ---- PostgreSQL ----
pg_setup /usr/lib/postgresql/18/bin "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE koillection LOGIN PASSWORD '${DB_PASSWORD}';" \
          -c "CREATE DATABASE koillection OWNER koillection;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:7001"
cred_note "First visit: create your account. The first account becomes the admin."

[ -z "${AIO_DRY_RUN:-}" ] || exit 0
exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
