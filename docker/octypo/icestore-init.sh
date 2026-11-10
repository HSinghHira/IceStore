#!/bin/bash
# IceStore start script for Octypo. Makes this install's database and admin
# passwords, creates the database on first start, then hands over to
# supervisord (postgres, octypo).
set -euo pipefail

DATA=${AIO_DATA:-/data}
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

STATE=$DATA/state
mkdir -p "$STATE" "$DATA/postgres" "$DATA/octypo"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"
ensure_secret PG_PASSWORD 16
ensure_secret ADMIN_PASSWORD 9
ensure_secret SECRETS_PASSWORD 24
PG_PASSWORD=$(secret PG_PASSWORD)

# ---- environment for the engine (supervisord passes it on) ----
export DATABASE_URL="postgres://octypo:$PG_PASSWORD@127.0.0.1:5432/octypo"
export PORT=3000
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-$(secret ADMIN_PASSWORD)}
export OCTYPO_SECRETS_PASSWORD=${OCTYPO_SECRETS_PASSWORD:-$(secret SECRETS_PASSWORD)}
# Upstream's .env.example defaults, as `octypo init` writes them.
export CONTENT_DOMAIN=${CONTENT_DOMAIN:-general news and analysis}
export AUTO_PUBLISH=${AUTO_PUBLISH:-false}
export ENABLE_INDEXNOW=${ENABLE_INDEXNOW:-false}
# Settings left empty in the app settings mean "use the default".
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do unset "$v"; done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6719/admin"
cred_add PASSWORD "$ADMIN_PASSWORD"
cred_note "Add at least one model key (like ANTHROPIC_API_KEY) in the app settings, or articles can't be written."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  env | grep -E '^(DATABASE_URL|ADMIN_PASSWORD|CONTENT_DOMAIN|AUTO_PUBLISH)=' | sed 's/:[^:@]*@/:***@/'
  log "dry run finished"
  exit 0
fi

chown -R node:node "$DATA/octypo"
pg_setup /usr/lib/postgresql/16/bin
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb
  pg_start_local
  pg_psql -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE octypo LOGIN SUPERUSER PASSWORD :'pw';
CREATE DATABASE octypo OWNER octypo;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
