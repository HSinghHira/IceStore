#!/bin/bash
# IceStore start script for Joplin Server. Runs as root, once per start:
#
#   - /data/secrets.env: the database password, made on first start.
#   - DEFAULT_ADMIN_PASSWORD: blank means the one in /data/.admin_password,
#     made on first start. Joplin only uses it when it makes the admin
#     (admin@localhost) on its very first start.
#   - APP_BASE_URL: while it still has [ZIMAOS-IP-ADDRESS], localhost is used
#     and the log says what to do.
#   - Every other blank variable is dropped, so Joplin uses its default.
#   - first start: initdb and the joplin database and role.
#
# Then supervisord runs PostgreSQL and Joplin Server (svc.sh).
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
PASS_FILE=$DATA/.admin_password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres"
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret DB_PASSWORD 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
POSTGRES_PASSWORD=$(secret DB_PASSWORD)
export POSTGRES_PASSWORD

# ---- first admin ----
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
export DEFAULT_ADMIN_PASSWORD

# ---- APP_BASE_URL ----
APP_BASE_URL=${APP_BASE_URL:-http://[ZIMAOS-IP-ADDRESS]:6764}
case $APP_BASE_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "APP_BASE_URL is still $APP_BASE_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, like http://192.168.1.20:6764. Until then Joplin Server only works at http://localhost:6764."
    APP_BASE_URL=${APP_BASE_URL//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
export APP_BASE_URL

# ---- every other blank variable: Joplin's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
umask 022

# ---- PostgreSQL ----
pg_setup /usr/lib/postgresql/16/bin "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE joplin LOGIN PASSWORD '${POSTGRES_PASSWORD}';" \
          -c "CREATE DATABASE joplin OWNER joplin;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "$(cred_url "$APP_BASE_URL")"
cred_add EMAIL "admin@localhost"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in DEFAULT_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$DEFAULT_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/joplin-server/data/.admin_password"
fi
cred_note "Change the email and password in your profile after you sign in."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
