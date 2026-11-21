#!/bin/bash
# IceStore start script for Tandoor Recipes. Runs as root, once per start:
#
#   - /data/secrets.env: SECRET_KEY and the database password, made on first
#     start. SECRET_KEY set in the app settings wins.
#   - Database settings point at the PostgreSQL inside this container;
#     uploaded images live in /data/mediafiles.
#   - Every other blank variable is dropped, so Tandoor uses its default
#     (ZimaOS passes settings left empty as empty strings).
#   - first start: initdb and the tandoor database and role.
#
# Then supervisord runs PostgreSQL and Tandoor (svc.sh).
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres" "$DATA/mediafiles"
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret SECRET_KEY 32
ensure_secret DB_PASSWORD 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
[ -n "${SECRET_KEY:-}" ] || SECRET_KEY=$(secret SECRET_KEY)
POSTGRES_PASSWORD=$(secret DB_PASSWORD)
DB_ENGINE=django.db.backends.postgresql
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USER=tandoor
POSTGRES_DB=tandoor
MEDIA_ROOT=$DATA/mediafiles
export SECRET_KEY POSTGRES_PASSWORD DB_ENGINE POSTGRES_HOST POSTGRES_PORT POSTGRES_USER POSTGRES_DB MEDIA_ROOT
unset DATABASE_URL SECRET_KEY_FILE POSTGRES_PASSWORD_FILE 2>/dev/null || true
umask 022

# ---- every other blank variable: Tandoor's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
# Upstream's default is an empty list, so Django turns every address away
# (400 Bad Request); answer to any name unless set in the app settings.
[ -n "${ALLOWED_HOSTS:-}" ] || ALLOWED_HOSTS='*'
export ALLOWED_HOSTS

# ---- PostgreSQL ----
pg_setup /usr/libexec/postgresql17 "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE tandoor LOGIN PASSWORD '${POSTGRES_PASSWORD}';" \
          -c "CREATE DATABASE tandoor OWNER tandoor;"
  # Tandoor's search uses these (upstream's migrations create them, which
  # needs a superuser; tandoor is not one).
  pg_psql -d tandoor -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" \
                     -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6770"
cred_note "No account yet: the first page asks you to make the admin account."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
