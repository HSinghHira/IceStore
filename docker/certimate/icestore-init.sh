#!/bin/sh
# IceStore start script for Certimate. Runs once per start:
#
#   - CERTIMATE_ADMIN_PASSWORD: set in the app settings wins; blank means the
#     one in /app/pb_data/.admin_password, made on first start. Certimate
#     only uses CERTIMATE_ADMIN_USERNAME and CERTIMATE_ADMIN_PASSWORD when it
#     makes its first admin (upstream's default is 1234567890).
#   - Blank variables are dropped, so Certimate uses its defaults
#     (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's command runs, unchanged.
set -eu

PASS_FILE=/app/pb_data/.admin_password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p /app/pb_data
umask 077
[ -n "${CERTIMATE_ADMIN_USERNAME:-}" ] || CERTIMATE_ADMIN_USERNAME=admin@example.com
PASSWORD_SET=
if [ -n "${CERTIMATE_ADMIN_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  CERTIMATE_ADMIN_PASSWORD=$(cat "$PASS_FILE")
else
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  CERTIMATE_ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in /app/pb_data/.admin_password."
fi
export CERTIMATE_ADMIN_USERNAME CERTIMATE_ADMIN_PASSWORD
umask 022

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6784"
cred_add EMAIL "$CERTIMATE_ADMIN_USERNAME"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in CERTIMATE_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$CERTIMATE_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/certimate/pb_data/.admin_password"
fi
cred_note "Only used for the first admin. Change it in Settings > Account after you sign in."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8090/api/health &

cd /app
exec "$@"
