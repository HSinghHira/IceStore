#!/bin/sh
# IceStore start script for VS Code. Makes sure /config/password.txt holds the
# login password in use, then hands over to upstream's /init (s6-overlay),
# which sets up PUID/PGID and starts the desktop.
#
#   - PASSWORD set (from the app settings): that password is used and written
#     to the file.
#   - PASSWORD blank or missing: the password already in the file is used, or
#     a new random one is made on first start.
set -eu

PASS_FILE=/config/password.txt
log() { echo "[icestore] $*"; }

mkdir -p /config
umask 077
if [ -n "${PASSWORD:-}" ]; then
  printf '%s' "$PASSWORD" > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
elif [ ! -s "$PASS_FILE" ]; then
  head -c 18 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  log "first start: made this install's login password in $PASS_FILE"
fi
PASSWORD=$(cat "$PASS_FILE")
export PASSWORD

# ZimaOS passes a variable someone left empty as an empty string.
[ -n "${CUSTOM_USER:-}" ] || CUSTOM_USER=abc
export CUSTOM_USER
log "sign in as $CUSTOM_USER with the password $PASSWORD (also in /DATA/AppData/vscode/password.txt)"

exec /init "$@"
