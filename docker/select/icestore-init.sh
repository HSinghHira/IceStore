#!/bin/bash
# IceStore start script for Select. Makes this install's database password,
# creates the database on first start, sets the public address, then hands
# over to supervisord (postgres, api, worker, web).
set -euo pipefail

DATA=${AIO_DATA:-/data}
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# ---- public address: invitation links use it; with https:// the session
# ---- cookie is marked Secure. The app itself works from any address. ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6702}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL: Select works from any address, but invitation links will say localhost;"
    log "set PUBLIC_URL to the address you open it at, like http://192.168.1.20:6702" ;;
esac

# ---- secrets: made once, kept in /data/state/secrets.env ----
STATE=$DATA/state
mkdir -p "$STATE" "$DATA/postgres" "$DATA/select"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"
ensure_secret PG_PASSWORD 16
PG_PASSWORD=$(secret PG_PASSWORD)
# Select makes its own SELECT_SECRET_KEY (it encrypts provider keys and
# mailbox passwords) in /data/select/secret.key when it isn't set.
[ "${AIO_DRY_RUN:-}" = 1 ] || chown -R select:select "$DATA/select"

# ---- environment for every program (supervisord passes it on) ----
export SELECT_DATABASE_URL="postgresql+psycopg://select:$PG_PASSWORD@127.0.0.1:5432/select"
export SELECT_PUBLIC_URL="$PUBLIC_URL"
export SELECT_AUTH_MODE="${SELECT_AUTH_MODE:-password}"
export SELECT_SESSION_DAYS="${SELECT_SESSION_DAYS:-30}"
export SELECT_CORS_ORIGINS="[\"$PUBLIC_URL\"]"
# Blank settings from the app settings mean "use the default".
[ -n "${SELECT_SECRET_KEY:-}" ] || unset SELECT_SECRET_KEY
[ -n "${SELECT_DEMO_STEP_DELAY_MS:-}" ] || unset SELECT_DEMO_STEP_DELAY_MS

# ---- CREDENTIALS banner, printed once Select answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "The first visit creates the owner account."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  env | grep -E '^SELECT_' | sed 's/:[^:@]*@/:***@/'
  log "dry run finished"
  exit 0
fi

# ---- first-start database (upstream's postgres:16 with POSTGRES_DB/USER select) ----
pg_setup /usr/lib/postgresql/16/bin
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb
  pg_start_local
  pg_psql -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE "select" LOGIN PASSWORD :'pw';
CREATE DATABASE "select" OWNER "select";
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
