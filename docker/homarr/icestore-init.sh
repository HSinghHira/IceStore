#!/bin/bash
# IceStore start script for Homarr. Runs once per start:
#
#   - SECRET_ENCRYPTION_KEY: set in the app settings wins; blank means the
#     one in /appdata/secrets.env, made on first start (64 hex characters,
#     which Homarr needs to start).
#   - Every other blank variable is dropped, so Homarr uses its default
#     (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's /app/entrypoint.sh runs, unchanged.
set -euo pipefail

SECRETS=/appdata/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p /appdata
umask 077
touch "$SECRETS"
ensure_secret SECRET_ENCRYPTION_KEY 32
[ -n "${SECRET_ENCRYPTION_KEY:-}" ] || SECRET_ENCRYPTION_KEY=$(secret SECRET_ENCRYPTION_KEY)
if ! printf '%s' "$SECRET_ENCRYPTION_KEY" | grep -Eq '^[0-9a-fA-F]{64}$'; then
  log "SECRET_ENCRYPTION_KEY must be 64 hex characters; using the one made for this install instead."
  SECRET_ENCRYPTION_KEY=$(secret SECRET_ENCRYPTION_KEY)
fi
export SECRET_ENCRYPTION_KEY
umask 022

for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6774"
cred_note "No account yet: the onboarding page asks you to make the admin account."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:7575/api/health/live &

exec /app/entrypoint.sh "$@"
