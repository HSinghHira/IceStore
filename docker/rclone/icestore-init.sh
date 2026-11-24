#!/bin/sh
# IceStore start script for Rclone. Makes this install's GUI password once
# and keeps it in /config, then starts upstream's web GUI:
#   GUI  on 0.0.0.0:8080 (published as 6803)
#   API  on 0.0.0.0:5572 (published as 6804; the GUI page calls it directly)
#   - RCLONE_GUI_PASSWORD set in the app settings: used and saved to the file.
#   - Blank or missing: the saved password is used, or a new one is made.
# Any arguments replace the default "gui ..." command (for example
# "rcd --rc-addr=:5572 ..." for the API only).
set -eu

CONFIG=${ICESTORE_CONFIG:-/config}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so rclone's
# defaults apply.
for v in $(env | sed -n 's/^\(RCLONE_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$CONFIG/rclone"
umask 077
FILE=$CONFIG/.icestore-password
if [ -n "${RCLONE_GUI_PASSWORD:-}" ]; then
  printf '%s' "$RCLONE_GUI_PASSWORD" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
elif [ ! -s "$FILE" ]; then
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
  log "first start: made this install's GUI password (.icestore-password in the config folder)"
fi
umask 022
PASS=$(cat "$FILE")
GUI_USER=${RCLONE_GUI_USER:-admin}
unset RCLONE_GUI_PASSWORD RCLONE_GUI_USER

if [ "$#" -gt 0 ]; then
  exec rclone "$@"
fi

cred_reset
cred_add URL "http://<your ZimaOS IP>:6803"
cred_add "API URL" "http://<your ZimaOS IP>:6804"
cred_add USER "$GUI_USER"
cred_add PASSWORD "$PASS"
cred_note "On the login page, type the API URL with your ZimaOS IP, the user and the password."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/ &

exec rclone gui --addr 0.0.0.0:8080 --api-addr 0.0.0.0:5572 --no-open-browser \
  --user "$GUI_USER" --pass "$PASS"
