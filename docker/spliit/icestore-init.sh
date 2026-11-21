#!/bin/bash
# IceStore start script for Spliit. Runs as root, once per start:
#
#   - /data/secrets.env: the database password and the cron secret, made on
#     first start.
#   - POSTGRES_PRISMA_URL / POSTGRES_URL_NON_POOLING point at the PostgreSQL
#     inside this container.
#   - BASE_URL: blank means http://localhost:6787.
#   - Every other blank variable is dropped, so Spliit uses its default
#     (ZimaOS passes settings left empty as empty strings).
#   - first start: initdb and the spliit database and role.
#
# Then supervisord runs PostgreSQL and Spliit (svc.sh).
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres"
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret DB_PASSWORD 24
ensure_secret CRON_SECRET 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
DB_PASSWORD=$(secret DB_PASSWORD)
[ -n "${CRON_SECRET:-}" ] || CRON_SECRET=$(secret CRON_SECRET)
POSTGRES_PRISMA_URL="postgresql://spliit:${DB_PASSWORD}@127.0.0.1:5432/spliit"
POSTGRES_URL_NON_POOLING=$POSTGRES_PRISMA_URL
export DB_PASSWORD CRON_SECRET POSTGRES_PRISMA_URL POSTGRES_URL_NON_POOLING
umask 022

# ---- every other blank variable: Spliit's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
[ -n "${BASE_URL:-}" ] || BASE_URL=http://localhost:6787
export BASE_URL

# ---- PostgreSQL ----
pg_setup /usr/libexec/postgresql17 "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE spliit LOGIN PASSWORD '${DB_PASSWORD}';" \
          -c "CREATE DATABASE spliit OWNER spliit;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6787"
cred_note "Spliit has no accounts: make a group and share its link with the people in it."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
