#!/bin/bash
# IceStore start script for tududi. Runs as root, once per start:
#
#   - /data/secrets.env: TUDUDI_SESSION_SECRET and the database password,
#     made on first start. TUDUDI_SESSION_SECRET set in the app settings wins.
#   - TUDUDI_USER_PASSWORD: blank means the one in /data/.admin_password,
#     made on first start. tududi only makes this account while it has no
#     users at all.
#   - Every other blank variable is dropped, so tududi uses its default.
#   - first start: initdb and the tududi database and role.
#
# Then supervisord runs PostgreSQL and tududi (svc.sh).
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
ensure_secret SESSION_SECRET 64
ensure_secret DB_PASSWORD 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
[ -n "${TUDUDI_SESSION_SECRET:-}" ] || TUDUDI_SESSION_SECRET=$(secret SESSION_SECRET)
DB_PASSWORD=$(secret DB_PASSWORD)
DATABASE_URL="postgres://tududi:${DB_PASSWORD}@127.0.0.1:5432/tududi"
export TUDUDI_SESSION_SECRET DB_PASSWORD DATABASE_URL

# ---- first admin ----
[ -n "${TUDUDI_USER_EMAIL:-}" ] || TUDUDI_USER_EMAIL=admin@example.com
PASSWORD_SET=
if [ -n "${TUDUDI_USER_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  TUDUDI_USER_PASSWORD=$(cat "$PASS_FILE")
else
  openssl rand -hex 12 > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  TUDUDI_USER_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in /data/.admin_password."
fi
export TUDUDI_USER_EMAIL TUDUDI_USER_PASSWORD

# ---- every other blank variable: tududi's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
umask 022

# ---- PostgreSQL ----
pg_setup /usr/libexec/postgresql16 "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE tududi LOGIN PASSWORD '${DB_PASSWORD}';" \
          -c "CREATE DATABASE tududi OWNER tududi;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6763"
cred_add EMAIL "$TUDUDI_USER_EMAIL"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in TUDUDI_USER_PASSWORD)"
else
  cred_add PASSWORD "$TUDUDI_USER_PASSWORD"
  cred_note "Also saved in /DATA/AppData/tududi/data/.admin_password"
fi
cred_note "Only used to make the first account. Change it in Profile after you sign in."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
