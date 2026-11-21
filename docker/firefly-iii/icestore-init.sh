#!/bin/bash
# IceStore start script for Firefly III. Runs as root, once per start:
#
#   - APP_KEY and STATIC_CRON_TOKEN: set in the app settings wins; blank
#     means the ones in storage/database/secrets.env, made on first start.
#     Firefly III needs both to be exactly 32 characters.
#   - DB_CONNECTION=sqlite, with the database in storage/database.
#   - APP_URL: blank means http://localhost:6771 (only used in email links).
#   - Every other blank variable is dropped, so Firefly III uses its default
#     (ZimaOS passes settings left empty as empty strings).
#   - A background loop calls Firefly III's cron URL every hour; Firefly III
#     only runs its jobs once a day.
#
# Then upstream's entrypoint runs as www-data.
set -euo pipefail

STORAGE=/var/www/html/storage
DB_DIR=$STORAGE/database
SECRETS=$DB_DIR/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DB_DIR" "$STORAGE/upload"
umask 077
touch "$SECRETS"

# ---- secrets (32 characters each) ----
ensure_secret APP_KEY 16
ensure_secret STATIC_CRON_TOKEN 16
[ -n "${APP_KEY:-}" ] || APP_KEY=$(secret APP_KEY)
[ -n "${STATIC_CRON_TOKEN:-}" ] || STATIC_CRON_TOKEN=$(secret STATIC_CRON_TOKEN)
if [ ${#APP_KEY} -ne 32 ]; then
  log "APP_KEY must be exactly 32 characters (it is ${#APP_KEY}); using the one made for this install instead."
  APP_KEY=$(secret APP_KEY)
fi
if [ ${#STATIC_CRON_TOKEN} -ne 32 ]; then
  log "STATIC_CRON_TOKEN must be exactly 32 characters; using the one made for this install instead."
  STATIC_CRON_TOKEN=$(secret STATIC_CRON_TOKEN)
fi
export APP_KEY STATIC_CRON_TOKEN
umask 022

# ---- every other blank variable: Firefly III's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
DB_CONNECTION=sqlite
DKR_CHECK_SQLITE=true
unset DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD 2>/dev/null || true
[ -n "${APP_URL:-}" ] || APP_URL=http://localhost:6771
[ -n "${PHP_DATE_TIMEZONE:-}" ] || PHP_DATE_TIMEZONE=${TZ:-UTC}
export DB_CONNECTION DKR_CHECK_SQLITE APP_URL PHP_DATE_TIMEZONE

# Firefly III runs as www-data; ZimaOS makes the bind folders as root.
chown -R www-data:www-data "$STORAGE/upload" "$DB_DIR"

# ---- daily jobs (recurring transactions, bills, exchange rates) ----
(
  sleep 300
  while true; do
    curl -fsS -o /dev/null -m 300 "http://127.0.0.1:8080/api/v1/cron/${STATIC_CRON_TOKEN}" \
      || log "cron call did not answer; trying again in an hour."
    sleep 3600
  done
) &

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6771"
cred_note "No account yet: click Register. The first account you make is the admin."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/health &

exec setpriv --reuid=www-data --regid=www-data --init-groups docker-php-serversideup-entrypoint "$@"
