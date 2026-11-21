#!/bin/bash
# IceStore start script for Zipline. Runs as root, once per start:
#
#   - /data/secrets.env: CORE_SECRET and the database password, made on
#     first start. CORE_SECRET set in the app settings wins.
#   - DATABASE_URL points at the PostgreSQL inside this container; uploads
#     live in /data/uploads.
#   - Every other blank variable is dropped, so Zipline uses its default
#     (ZimaOS passes settings left empty as empty strings).
#   - first start: initdb and the zipline database and role.
#
# Then supervisord runs PostgreSQL and Zipline (svc.sh).
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres" "$DATA/uploads"
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret CORE_SECRET 32
ensure_secret DB_PASSWORD 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
[ -n "${CORE_SECRET:-}" ] || CORE_SECRET=$(secret CORE_SECRET)
if [ ${#CORE_SECRET} -lt 32 ]; then
  log "CORE_SECRET must be at least 32 characters; using the one made for this install instead."
  CORE_SECRET=$(secret CORE_SECRET)
fi
DB_PASSWORD=$(secret DB_PASSWORD)
DATABASE_URL="postgres://zipline:${DB_PASSWORD}@127.0.0.1:5432/zipline"
export CORE_SECRET DB_PASSWORD DATABASE_URL
unset DATABASE_USERNAME DATABASE_PASSWORD DATABASE_HOST DATABASE_PORT DATABASE_NAME 2>/dev/null || true
umask 022

# ---- every other blank variable: Zipline's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
[ -n "${DATASOURCE_LOCAL_DIRECTORY:-}" ] || DATASOURCE_LOCAL_DIRECTORY=$DATA/uploads
export DATASOURCE_LOCAL_DIRECTORY

# ---- PostgreSQL ----
pg_setup /usr/libexec/postgresql17 "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE zipline LOGIN PASSWORD '${DB_PASSWORD}';" \
          -c "CREATE DATABASE zipline OWNER zipline;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6775"
cred_note "No account yet: the first page asks you to make the admin account."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
