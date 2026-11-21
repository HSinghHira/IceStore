#!/bin/bash
# IceStore start script for PLANKA. Runs as root, once per start:
#
#   - /data/secrets.env: SECRET_KEY and the database password, made on first
#     start. SECRET_KEY set in the app settings wins.
#   - DEFAULT_ADMIN_PASSWORD: blank means the one in /data/.admin_password,
#     made on first start. PLANKA sets it on the admin on every start.
#   - BASE_URL: PLANKA only accepts browsers at this address. While it still
#     has [ZIMAOS-IP-ADDRESS], localhost is used and the log says what to do.
#   - Every other blank variable is dropped, so PLANKA uses its default.
#   - first start: initdb and the planka database and role.
#
# Then supervisord runs PostgreSQL and PLANKA (svc.sh).
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
PASS_FILE=$DATA/.admin_password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres" /app/data
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret SECRET_KEY 32
ensure_secret DB_PASSWORD 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
[ -n "${SECRET_KEY:-}" ] || SECRET_KEY=$(secret SECRET_KEY)
DB_PASSWORD=$(secret DB_PASSWORD)
DATABASE_URL="postgresql://planka:${DB_PASSWORD}@127.0.0.1:5432/planka"
export SECRET_KEY DB_PASSWORD DATABASE_URL

# ---- first admin ----
[ -n "${DEFAULT_ADMIN_EMAIL:-}" ] || DEFAULT_ADMIN_EMAIL=admin@example.com
[ -n "${DEFAULT_ADMIN_USERNAME:-}" ] || DEFAULT_ADMIN_USERNAME=admin
[ -n "${DEFAULT_ADMIN_NAME:-}" ] || DEFAULT_ADMIN_NAME=Admin
PASSWORD_SET=
if [ -n "${DEFAULT_ADMIN_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  DEFAULT_ADMIN_PASSWORD=$(cat "$PASS_FILE")
else
  openssl rand -hex 12 > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  DEFAULT_ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in /data/.admin_password."
fi
export DEFAULT_ADMIN_EMAIL DEFAULT_ADMIN_USERNAME DEFAULT_ADMIN_NAME DEFAULT_ADMIN_PASSWORD

# ---- BASE_URL ----
BASE_URL=${BASE_URL:-http://[ZIMAOS-IP-ADDRESS]:6762}
case $BASE_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "BASE_URL is still $BASE_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, like http://192.168.1.20:6762. Until then PLANKA only works at http://localhost:6762."
    BASE_URL=${BASE_URL//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
export BASE_URL

# ---- every other blank variable: PLANKA's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
umask 022

# PLANKA runs as node; its upload folder is made by ZimaOS as root.
chown -R node:node /app/data

# ---- PostgreSQL ----
pg_setup /usr/libexec/postgresql16 "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE planka LOGIN PASSWORD '${DB_PASSWORD}';" \
          -c "CREATE DATABASE planka OWNER planka;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "$(cred_url "$BASE_URL")"
cred_add EMAIL "$DEFAULT_ADMIN_EMAIL"
cred_add USERNAME "$DEFAULT_ADMIN_USERNAME"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in DEFAULT_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$DEFAULT_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/planka/data/.admin_password"
fi
cred_note "To change it, set DEFAULT_ADMIN_PASSWORD in the app settings."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
