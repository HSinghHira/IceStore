#!/bin/sh
# IceStore start script for HomeBox. Runs once per start:
#
#   - HBOX_AUTH_API_KEY_PEPPER: set in the app settings wins; blank means the
#     one in /data/secrets.env, made on first start (HomeBox refuses to start
#     without at least 32 bytes, and changing it voids every API key).
#   - Blank variables are dropped, so HomeBox uses its defaults
#     (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's /app/api runs, unchanged.
set -eu

SECRETS=/data/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p /data
umask 077
touch "$SECRETS"
if ! grep -q '^HBOX_AUTH_API_KEY_PEPPER=' "$SECRETS"; then
  echo "HBOX_AUTH_API_KEY_PEPPER=$(head -c 48 /dev/urandom | od -An -tx1 | tr -d ' \n')" >> "$SECRETS"
fi
[ -n "${HBOX_AUTH_API_KEY_PEPPER:-}" ] || HBOX_AUTH_API_KEY_PEPPER=$(secret HBOX_AUTH_API_KEY_PEPPER)
if [ ${#HBOX_AUTH_API_KEY_PEPPER} -lt 32 ]; then
  log "HBOX_AUTH_API_KEY_PEPPER must be at least 32 characters; using the one made for this install instead."
  HBOX_AUTH_API_KEY_PEPPER=$(secret HBOX_AUTH_API_KEY_PEPPER)
fi
export HBOX_AUTH_API_KEY_PEPPER
umask 022

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6781"
cred_note "No account yet: click Register. The first account owns your home."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:7745/api/v1/status &

exec /app/api "$@"
