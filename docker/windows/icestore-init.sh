#!/bin/sh
# IceStore start script for Windows. Makes sure /storage/icestore-password.txt
# holds the Windows password, then hands over to upstream's /run/entry.sh.
#
#   - PASSWORD set (from the app settings): that password is used and written
#     to the file.
#   - PASSWORD blank or missing: the password already in the file is used, or
#     a new random one is made on first start.
#
# Windows takes the password only while it installs itself (first start).
# Changing PASSWORD later does not change it inside Windows.
set -eu

PASS_FILE=/storage/icestore-password.txt
log() { echo "[icestore] $*"; }

mkdir -p /storage
PASSWORD_SET=${PASSWORD:-}
(
  umask 077
  if [ -n "$PASSWORD_SET" ]; then
    printf '%s' "$PASSWORD_SET" > "$PASS_FILE.tmp"
    mv "$PASS_FILE.tmp" "$PASS_FILE"
  elif [ ! -s "$PASS_FILE" ]; then
    # 12 letters and digits: easy to type in a Remote Desktop window.
    head -c 64 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | cut -c1-12 > "$PASS_FILE.tmp"
    mv "$PASS_FILE.tmp" "$PASS_FILE"
    log "first start: made this install's Windows password in $PASS_FILE"
  fi
)
PASSWORD=$(cat "$PASS_FILE")
export PASSWORD

# ZimaOS passes a variable someone left empty as an empty string; upstream
# then uses its own default user name.
[ -n "${USERNAME:-}" ] || USERNAME=Docker
export USERNAME

# CREDENTIALS banner (docker/_common), printed in the background once the
# web viewer answers.
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh
cred_reset
cred_add "WEB VIEWER" "http://<your ZimaOS IP>:6187"
cred_add "REMOTE DESKTOP" "<your ZimaOS IP>:6188"
cred_add USERNAME "$USERNAME"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in PASSWORD)"
else
  cred_add PASSWORD "$PASSWORD"
  cred_note "Also saved in the storage folder as icestore-password.txt"
fi
cred_note "Windows uses this password from the moment it is installed"
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8006/ &

exec /run/entry.sh "$@"
