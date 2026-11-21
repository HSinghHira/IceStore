#!/bin/sh
# IceStore start script for Nexterm. Runs once per start:
#
#   - ENCRYPTION_KEY: set in the app settings wins; blank means the one in
#     /app/data/secrets.env, made on first start (64 hex characters; it
#     encrypts the saved passwords and SSH keys).
#   - Every other blank variable is dropped, so Nexterm uses its default
#     (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's docker-start.sh runs, unchanged.
set -eu

SECRETS=/app/data/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p /app/data
umask 077
touch "$SECRETS"
ensure_secret ENCRYPTION_KEY 32
[ -n "${ENCRYPTION_KEY:-}" ] || ENCRYPTION_KEY=$(secret ENCRYPTION_KEY)
if ! printf '%s' "$ENCRYPTION_KEY" | grep -Eq '^[0-9a-fA-F]{64}$'; then
  log "ENCRYPTION_KEY must be 64 hex characters; using the one made for this install instead."
  ENCRYPTION_KEY=$(secret ENCRYPTION_KEY)
fi
export ENCRYPTION_KEY
umask 022

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6777"
cred_note "No account yet: the first page asks you to make the admin account."
/usr/local/lib/icestore/credentials.sh &

exec "$@"
