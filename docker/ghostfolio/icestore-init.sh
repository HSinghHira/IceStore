#!/bin/bash
# IceStore start script for Ghostfolio. Runs as root, once per start:
#
#   - /data/secrets.env: JWT_SECRET_KEY, ACCESS_TOKEN_SALT and the database
#     and Redis passwords, made on first start. JWT_SECRET_KEY and
#     ACCESS_TOKEN_SALT set in the app settings win.
#   - Database and Redis settings point at the services inside this
#     container.
#   - ROOT_URL: blank means http://localhost:6772.
#   - Every other blank variable is dropped, so Ghostfolio uses its default
#     (ZimaOS passes settings left empty as empty strings).
#   - first start: initdb and the ghostfolio database and role.
#
# Then supervisord runs PostgreSQL, Redis and Ghostfolio (svc.sh).
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/postgres" "$DATA/redis"
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret JWT_SECRET_KEY 32
ensure_secret ACCESS_TOKEN_SALT 32
ensure_secret DB_PASSWORD 24
ensure_secret REDIS_PASSWORD 24
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only reachable over the socket
[ -n "${JWT_SECRET_KEY:-}" ] || JWT_SECRET_KEY=$(secret JWT_SECRET_KEY)
[ -n "${ACCESS_TOKEN_SALT:-}" ] || ACCESS_TOKEN_SALT=$(secret ACCESS_TOKEN_SALT)
POSTGRES_PASSWORD=$(secret DB_PASSWORD)
REDIS_PASSWORD=$(secret REDIS_PASSWORD)
POSTGRES_USER=ghostfolio
POSTGRES_DB=ghostfolio
DATABASE_URL="postgresql://ghostfolio:${POSTGRES_PASSWORD}@127.0.0.1:5432/ghostfolio?connect_timeout=300&sslmode=disable"
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
export JWT_SECRET_KEY ACCESS_TOKEN_SALT POSTGRES_PASSWORD POSTGRES_USER POSTGRES_DB DATABASE_URL \
       REDIS_HOST REDIS_PORT REDIS_PASSWORD
unset DIRECT_URL 2>/dev/null || true
umask 022

# ---- every other blank variable: Ghostfolio's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
[ -n "${ROOT_URL:-}" ] || ROOT_URL=http://localhost:6772
export ROOT_URL

chown -R redis:redis "$DATA/redis"

# ---- PostgreSQL ----
pg_setup /usr/lib/postgresql/17/bin "$DATA/postgres"
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE ghostfolio LOGIN PASSWORD '${POSTGRES_PASSWORD}';" \
          -c "CREATE DATABASE ghostfolio OWNER ghostfolio;"
  pg_stop_local
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6772"
cred_note "No account yet: click Get Started. The first account is the admin."
cred_note "Ghostfolio shows your security token once. Save it: it is how you sign in."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
