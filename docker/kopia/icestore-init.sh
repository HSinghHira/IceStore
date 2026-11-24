#!/bin/sh
# IceStore start script for Kopia. Makes this install's web UI password once
# and keeps it in the config folder, then starts upstream's kopia.
#   - KOPIA_SERVER_PASSWORD set in the app settings: used and saved to the file.
#   - Blank or missing: the saved password is used, or a new one is made.
set -eu

CONFIG=${ICESTORE_CONFIG:-/app/config}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply (an empty KOPIA_PASSWORD would be tried as the password).
for v in $(env | sed -n 's/^\(KOPIA_[A-Z0-9_]*\)=$/\1/p') USER; do
  eval "val=\${$v-unset}"
  [ "$val" = "" ] && unset "$v"
done

mkdir -p "$CONFIG"
umask 077
FILE=$CONFIG/.icestore-password
if [ -n "${KOPIA_SERVER_PASSWORD:-}" ]; then
  printf '%s' "$KOPIA_SERVER_PASSWORD" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
elif [ ! -s "$FILE" ]; then
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
  log "first start: made this install's web UI password (.icestore-password in the config folder)"
fi
umask 022
KOPIA_SERVER_PASSWORD=$(cat "$FILE")
KOPIA_SERVER_USERNAME=${KOPIA_SERVER_USERNAME:-admin}
# The user name in each snapshot's owner (user@hostname).
USER=${USER:-zimaos}
export KOPIA_SERVER_PASSWORD KOPIA_SERVER_USERNAME USER

cred_reset
cred_add URL "http://<your ZimaOS IP>:6802"
cred_add USER "$KOPIA_SERVER_USERNAME"
cred_add PASSWORD "$KOPIA_SERVER_PASSWORD"
cred_note "This is the web page login. The repository password is the one you choose when you create the repository; write it down, Kopia cannot recover it."
/usr/local/lib/icestore/credentials.sh &

exec /bin/kopia "$@"
