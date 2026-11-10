#!/bin/bash
# IceStore start script for CartVibe.
#   - SECRET_KEY / ENCRYPTION_KEY: a value from the app settings wins and is
#     saved; blank means the saved key, or a new one on first start.
#   - Starts Valkey (upstream's separate valkey service) on 127.0.0.1, kept
#     running in the background, then hands over to upstream's entrypoint.
set -euo pipefail

BASE=/app/cartvibe-api
KEYS=$BASE/sqlite/.icestore
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$KEYS" "$BASE/sqlite/valkey"
chmod 700 "$KEYS"
keep() {
  local name=$1 file=$KEYS/$1 val=${!1:-}
  umask 077
  if [ -n "$val" ]; then
    printf '%s' "$val" > "$file"
  elif [ ! -s "$file" ]; then
    openssl rand -hex 32 2>/dev/null > "$file" || head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$file"
    log "first start: made $name (kept in the sqlite folder, .icestore/$name). Back it up."
  fi
  export "$name=$(tr -d '\n' < "$file")"
}
keep SECRET_KEY
keep ENCRYPTION_KEY

export DB_ENGINE=${DB_ENGINE:-sqlite} DB_FILENAME=${DB_FILENAME:-app.db}
export VALKEY_HOST=127.0.0.1 VALKEY_PORT=6379
# ZimaOS passes settings left empty as empty strings; drop them.
for v in PUID PGID VAPID_PUBLIC_KEY VAPID_PRIVATE_KEY VAPID_SUBJECT; do
  [ -n "${!v:-}" ] || unset "$v"
done

# Valkey, restarted if it stops; its data lives next to the database.
( while :; do
    valkey-server --bind 127.0.0.1 --port 6379 --dir "$BASE/sqlite/valkey" \
      --appendonly yes --tcp-backlog 128 --daemonize no 2>&1 | sed -u 's/^/[valkey] /'
    sleep 2
  done ) &

cred_reset
cred_add URL "http://<your ZimaOS IP>:6717"
cred_add USER admin
cred_add PASSWORD "admin (until you change it)"
cred_note "Change it right away: Management, Users, the key icon on your row."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:80/ &

exec /app/entrypoint.sh "$@"
