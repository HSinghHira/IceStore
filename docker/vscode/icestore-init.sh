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
PASSWORD_SET=${PASSWORD:-}
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

# CREDENTIALS banner (docker/_common), printed in the background once the
# desktop answers. lib.sh's log keeps the [icestore] tag.
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh
cred_reset
cred_add URL "https://<your ZimaOS IP>:6119"
cred_add USERNAME "$CUSTOM_USER"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in PASSWORD)"
else
  cred_add PASSWORD "$PASSWORD"
  cred_note "Also saved in /DATA/AppData/vscode/password.txt"
fi
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:3000/ &

exec /init "$@"
