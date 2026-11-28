#!/bin/sh
# IceStore start script for CommaFeed. Upstream makes a new session key on
# every start, which signs everyone out after each restart or update. This
# makes one key per install, keeps it in /commafeed/data, and hands over to
# upstream's own start command.
#   - QUARKUS_HTTP_AUTH_SESSION_ENCRYPTION_KEY set in the app settings is
#     used and saved.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/commafeed/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(\(COMMAFEED\|QUARKUS\)_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$DIR"
f="$DIR/.icestore-session-key"
( umask 077
  if [ -n "${QUARKUS_HTTP_AUTH_SESSION_ENCRYPTION_KEY:-}" ]; then
    printf '%s' "$QUARKUS_HTTP_AUTH_SESSION_ENCRYPTION_KEY" > "$f.tmp" && mv "$f.tmp" "$f"
  elif [ ! -s "$f" ]; then
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$f.tmp" && mv "$f.tmp" "$f"
    log "first start: made the session key ($f)"
  fi )
QUARKUS_HTTP_AUTH_SESSION_ENCRYPTION_KEY=$(cat "$f")
export QUARKUS_HTTP_AUTH_SESSION_ENCRYPTION_KEY

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:6887"
cred_note "First visit: make the admin account on the setup page."
/usr/local/lib/icestore/credentials.sh &

exec "$@"
