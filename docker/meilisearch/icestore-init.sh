#!/bin/sh
# IceStore start script for Meilisearch. Makes this install's master key once
# and keeps it in the data folder, then starts upstream's meilisearch.
#   - MEILI_MASTER_KEY set in the app settings: used and saved to the file
#     (at least 16 characters).
#   - Blank or missing: the saved key is used, or a new one is made.
set -eu

DATA=${ICESTORE_DATA:-/meili_data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(MEILI_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$DATA"
umask 077
FILE=$DATA/.icestore-master-key
if [ -n "${MEILI_MASTER_KEY:-}" ]; then
  printf '%s' "$MEILI_MASTER_KEY" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
elif [ ! -s "$FILE" ]; then
  head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
  log "first start: made this install's master key (.icestore-master-key in the data folder)"
fi
umask 022
MEILI_MASTER_KEY=$(cat "$FILE")
export MEILI_MASTER_KEY

cred_reset
cred_add URL "http://<your ZimaOS IP>:6810"
cred_add "MASTER KEY" "$MEILI_MASTER_KEY"
cred_note "Use the master key only to make API keys (GET /keys); give apps the Default Search or Admin API key."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:7700/health &

exec "$@"
