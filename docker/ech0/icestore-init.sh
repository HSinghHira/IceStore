#!/bin/sh
# IceStore start script for Ech0. Runs once per start:
#
#   - JWT_SECRET: set in the app settings wins; blank means the one in
#     /app/data/secrets.env, made on first start, so sign-ins last across
#     restarts.
#   - Blank variables are dropped, so Ech0 uses its defaults
#     (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's /app/ech0 runs, unchanged.
set -eu

SECRETS=/app/data/secrets.env
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p /app/data
umask 077
touch "$SECRETS"
if ! grep -q '^JWT_SECRET=' "$SECRETS"; then
  echo "JWT_SECRET=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')" >> "$SECRETS"
fi
[ -n "${JWT_SECRET:-}" ] || JWT_SECRET=$(secret JWT_SECRET)
export JWT_SECRET
umask 022

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6782"
cred_note "No account yet: click Register. The first account is the owner."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:6277/ &

cd /app
exec /app/ech0 "$@"
