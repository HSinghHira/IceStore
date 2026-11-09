#!/bin/sh
# IceStore start script for Trackhop. Makes this install's SONGPORT_PASSWORD
# once and keeps it in the data folder, then starts upstream's server.
#   - SONGPORT_PASSWORD set in the app settings: used and saved to the file.
#   - Blank or missing: the saved password is used, or a new one is made.
set -eu

DATA=${SONGPORT_DATA:-/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA"
umask 077
FILE=$DATA/.icestore-password
if [ -n "${SONGPORT_PASSWORD:-}" ]; then
  printf '%s' "$SONGPORT_PASSWORD" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
elif [ ! -s "$FILE" ]; then
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
  log "first start: made this install's password (.icestore-password in the data folder)"
fi
SONGPORT_PASSWORD=$(cat "$FILE")
export SONGPORT_PASSWORD

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in SONGPORT_URL SONGPORT_USER SONGPORT_MULTIUSER SONGPORT_LOCALE SONGPORT_MUSIC SONGPORT_UPDATE_CHECK \
         SPOTIFY_CLIENT_ID TIDAL_CLIENT_ID DEEZER_APP_ID DEEZER_REDIRECT_URL GOOGLE_CLIENT_ID LASTFM_API_KEY; do
  eval "val=\${$v-unset}"
  [ "$val" = "" ] && unset "$v"
done

cred_reset
cred_add URL "${SONGPORT_URL:-http://127.0.0.1:8080}"
cred_add USER "${SONGPORT_USER:-any name}"
cred_add PASSWORD "$SONGPORT_PASSWORD"
cred_note "Open SONGPORT_URL exactly as written; music service sign-ins come back to it."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/ &

exec /opt/songport/bin/songport-server "$@"
