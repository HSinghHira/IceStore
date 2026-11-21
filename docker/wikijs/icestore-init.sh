#!/bin/bash
# IceStore start script for Wiki.js 3. Runs as root, once per start:
#
#   - /data/secrets.env: the database password, made on first start.
#   - ADMIN_PASS: blank means the one in /data/.admin_password, made on first
#     start. Wiki.js only reads ADMIN_EMAIL and ADMIN_PASS on its very first
#     start against an empty database.
#   - first start: initdb and the wiki database and role.
#
# Then supervisord runs PostgreSQL and Wiki.js (svc.sh).
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
PASS_FILE=$DATA/.admin_password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres" /wiki/data/content /wiki/data/repo
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret DB_PASS 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
DB_PASS=$(secret DB_PASS)
export DB_PASS

# ---- first admin ----
[ -n "${ADMIN_EMAIL:-}" ] || ADMIN_EMAIL=admin@example.com
PASSWORD_SET=
if [ -n "${ADMIN_PASS:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  ADMIN_PASS=$(cat "$PASS_FILE")
else
  openssl rand -hex 12 > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  ADMIN_PASS=$(cat "$PASS_FILE")
  log "first start: made the admin password in /data/.admin_password."
fi
export ADMIN_EMAIL ADMIN_PASS

# ---- other settings: blank means Wiki.js's default ----
for v in LOG_LEVEL LOG_FORMAT OFFLINE ICONIFY_API_URL; do
  [ -n "${!v:-}" ] || unset "$v"
done
umask 022

# Wiki.js runs as node; its data folders are made by ZimaOS as root.
chown -R node:node /wiki/data/content /wiki/data/repo

# ---- PostgreSQL ----
pg_setup /usr/lib/postgresql/18/bin "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE wiki LOGIN PASSWORD '${DB_PASS}';" \
          -c "CREATE DATABASE wiki OWNER wiki;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6760"
cred_add EMAIL "$ADMIN_EMAIL"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASS)"
else
  cred_add PASSWORD "$ADMIN_PASS"
  cred_note "Also saved in /DATA/AppData/wikijs/data/.admin_password"
fi
cred_note "Only used for the first admin. Change it in your profile after you sign in."

[ -z "${AIO_DRY_RUN:-}" ] || exit 0
exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
