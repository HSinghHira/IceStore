#!/bin/sh
# IceStore start script for Dufs. Makes this install's login once and keeps
# it in /config, then starts upstream's server.
#   - DUFS_AUTH set in the app settings: used exactly as written (your own
#     rules, several accounts); the made password is not used.
#   - DUFS_PASSWORD set: used and saved to the file.
#   - Both blank or missing: the saved password is used, or a new one is made.
set -eu

CONFIG=${ICESTORE_CONFIG:-/config}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings, and Dufs refuses an
# empty true/false; drop them so upstream's defaults apply.
for v in $(env | sed -n 's/^\(DUFS_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$CONFIG"
umask 077
FILE=$CONFIG/.icestore-password
if [ -n "${DUFS_PASSWORD:-}" ]; then
  printf '%s' "$DUFS_PASSWORD" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
elif [ ! -s "$FILE" ]; then
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
  log "first start: made this install's password (.icestore-password in the config folder)"
fi
umask 022
PASS=$(cat "$FILE")
USER_NAME=${DUFS_USER:-admin}
unset DUFS_PASSWORD DUFS_USER

cred_reset
cred_add URL "http://<your ZimaOS IP>:6801"
if [ -n "${DUFS_AUTH:-}" ]; then
  cred_note "DUFS_AUTH is set in the app settings, so its accounts are used."
else
  DUFS_AUTH="$USER_NAME:$PASS@/:rw"
  export DUFS_AUTH
  cred_add USER "$USER_NAME"
  cred_add PASSWORD "$PASS"
fi
export DUFS_SERVE_PATH="${DUFS_SERVE_PATH:-/srv}"
export DUFS_PORT="${DUFS_PORT:-5000}"
/usr/local/lib/icestore/credentials.sh "http://127.0.0.1:$DUFS_PORT/${DUFS_PATH_PREFIX:+${DUFS_PATH_PREFIX#/}/}__dufs__/health" &

exec /bin/dufs "$@"
