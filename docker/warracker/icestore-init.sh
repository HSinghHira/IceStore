#!/bin/bash
# IceStore start script for Warracker. Runs as root, once per start:
#
#   - /data/secrets.env: the database password, made on first start.
#   - FRONTEND_URL / APP_BASE_URL: blank means http://localhost:6769 (only
#     used for email links and single sign-on redirects).
#   - Every other blank variable is dropped, so Warracker uses its default
#     (ZimaOS passes settings left empty as empty strings).
#   - first start: initdb and the warranty_db database and role.
#
# Then PostgreSQL is started for upstream's entrypoint (migrations), and
# icestore-handoff starts supervisord.
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres" "$DATA/uploads"
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret DB_PASSWORD 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
DB_PASSWORD=$(secret DB_PASSWORD)
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=warranty_db
DB_USER=warranty_user
UPLOAD_FOLDER=$DATA/uploads
export DB_PASSWORD DB_HOST DB_PORT DB_NAME DB_USER UPLOAD_FOLDER
unset DATABASE_URL 2>/dev/null || true
umask 022
# gunicorn runs as warracker (999) and keeps its SECRET_KEY in uploads.
chown -R 999:999 "$DATA/uploads"

# ---- every other blank variable: Warracker's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
[ -n "${FRONTEND_URL:-}" ] || FRONTEND_URL=${APP_BASE_URL:-http://localhost:6769}
[ -n "${APP_BASE_URL:-}" ] || APP_BASE_URL=$FRONTEND_URL
export FRONTEND_URL APP_BASE_URL

# ---- PostgreSQL ----
pg_setup /usr/lib/postgresql/17/bin "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  # Upstream's own stack makes warranty_user the database superuser (it is
  # POSTGRES_USER there); its permission fixer expects that.
  pg_psql -c "CREATE ROLE warranty_user LOGIN SUPERUSER PASSWORD '${DB_PASSWORD}';" \
          -c "CREATE DATABASE warranty_db OWNER warranty_user;"
  pg_stop_local
fi
# Running for the migrations in upstream's entrypoint; icestore-handoff
# stops it and supervisord starts it again.
as_pg "$PGBIN/pg_ctl" -D "$PG_DIR" \
  -o "-c listen_addresses=127.0.0.1 -c port=5432 -c unix_socket_directories=/run/postgresql" -w start >/dev/null
pg_psql -c "ALTER ROLE warranty_user PASSWORD '${DB_PASSWORD}';"

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6769"
cred_note "No account yet: click Register. The first account you make is the admin."
cred_note "Then turn off sign-ups for others in Settings > Admin if you want."

exec /app/entrypoint.sh /usr/local/bin/icestore-handoff
