#!/bin/sh
# IceStore start script for OpenCadence.
#
#   1. Makes the login password once (or uses PASSWORD from the app
#      settings) and keeps it in /app/data/icestore-password.txt.
#   2. Writes nginx's password file and starts nginx on 8080 in front of the
#      app (OpenCadence itself has no login).
#   3. Gives the data folder to the node user (ZimaOS makes it as root) and
#      starts upstream's server on 127.0.0.1:3000 as that user.
# Paths can be moved for testing outside Docker (CADENCE_DATA, ICESTORE_RUN,
# ICESTORE_DRY_RUN).
set -eu

DATA=${CADENCE_DATA:-/app/data}
RUN=${ICESTORE_RUN:-/run/icestore}
PASS_FILE=$DATA/icestore-password.txt
log() { echo "[icestore] $*"; }

mkdir -p "$DATA" "$RUN"

# ---- the login ----
[ -n "${USERNAME:-}" ] || USERNAME=admin
PASSWORD_SET=${PASSWORD:-}
(
  umask 077
  if [ -n "$PASSWORD_SET" ]; then
    printf '%s' "$PASSWORD_SET" > "$PASS_FILE.tmp"
    mv "$PASS_FILE.tmp" "$PASS_FILE"
  elif [ ! -s "$PASS_FILE" ]; then
    head -c 18 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp"
    mv "$PASS_FILE.tmp" "$PASS_FILE"
    log "first start: made this install's login password in $PASS_FILE"
  fi
  printf '%s:%s\n' "$USERNAME" "$(openssl passwd -apr1 -stdin < "$PASS_FILE")" > "$RUN/htpasswd"
)
chmod 644 "$RUN/htpasswd"
PASSWORD=$(cat "$PASS_FILE")

# ---- CREDENTIALS banner (docker/_common), once the app answers ----
LOG_TAG=icestore
AIO_CRED_FILE=$RUN/credentials
export AIO_CRED_FILE
. "${ICESTORE_LIB:-/usr/local/lib/icestore/lib.sh}"
cred_reset
cred_add URL "http://<your ZimaOS IP>:6195"
cred_add USERNAME "$USERNAME"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in PASSWORD)"
else
  cred_add PASSWORD "$PASSWORD"
  cred_note "Also saved in the data folder as icestore-password.txt"
fi
unset PASSWORD

if [ -n "${ICESTORE_DRY_RUN:-}" ]; then
  echo "would run: nginx -c /etc/nginx/icestore.conf; node server.js as node (data: $DATA)"
  exit 0
fi

# ---- the data folder belongs to the node user ----
if [ -n "$(find "$DATA" ! -user node -print -quit)" ]; then
  log "giving $DATA to the node user"
  chown -R node:node "$DATA"
fi

nginx -c /etc/nginx/icestore.conf
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:3000/api/revision &

cd /app
exec setpriv --reuid=node --regid=node --init-groups -- node server.js
