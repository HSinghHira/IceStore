#!/bin/sh
# IceStore start script for AI Gude. On the first start (no user files yet)
# it puts upstream's sample show (hack/users/demo.toml) in the users folder as
# a starting point, gives the folders to the service's user (upstream's
# deploy does that too) and starts the service as that user.
set -eu

LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

USERS=${AIGUDE_USERS_DIR:-/etc/aigude/users}
DATA=${AIGUDE_DATA_DIR:-/var/lib/aigude/data}
mkdir -p "$USERS" "$DATA"
if [ -z "$(ls -A "$USERS" 2>/dev/null)" ]; then
  cp /usr/share/aigude/starter.toml "$USERS/me.toml"
  log "first start: put a sample show in the users folder (me.toml); edit it on the app's config page or in the Files app"
fi
chown -R aigude:aigude "$USERS" "$DATA"

# ZimaOS passes settings left empty as empty strings; drop them.
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do unset "$v"; done
[ -n "${GEMINI_API_KEY:-}" ] || log "GEMINI_API_KEY is not set: no Episodes can be made until you add it in the app settings"

cred_reset
cred_add URL "http://<your ZimaOS IP>:6724"
cred_note "AI Gude has no sign-in: keep it on your home network."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/healthz &

exec su-exec aigude /usr/local/bin/aigude "$@"
