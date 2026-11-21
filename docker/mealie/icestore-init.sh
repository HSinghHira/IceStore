#!/bin/bash
# IceStore start script for Mealie. Runs as root before upstream's run.sh:
#
#   - MEALIE_ADMIN_PASSWORD: blank means the one in /app/data/.admin_password,
#     made on first start. A one-shot (mealie-admin.py) puts it on Mealie's
#     seeded admin, changeme@example.com, while that account still has the
#     published default password "MyPassword". After anyone changes it, it
#     does nothing.
#   - Blank variables are dropped, so Mealie uses its defaults (ZimaOS passes
#     settings left empty as empty strings).
#
# Mealie makes its own secret keys in /app/data. Then upstream's run.sh runs
# unchanged (PUID/PGID, then Mealie).
set -eu

DATA=/app/data
PASS_FILE=$DATA/.admin_password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA"
PASSWORD_SET=
if [ -n "${MEALIE_ADMIN_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  MEALIE_ADMIN_PASSWORD=$(cat "$PASS_FILE")
else
  (umask 077; head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp")
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  MEALIE_ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in /app/data/.admin_password."
fi
export MEALIE_ADMIN_PASSWORD

for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6767"
cred_add EMAIL "changeme@example.com"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in MEALIE_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$MEALIE_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/mealie/data/.admin_password"
fi
cred_note "Change the email and password in your profile after you sign in."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:9000/api/app/about &

# The one-shot runs as the same user Mealie runs as, so the database files
# keep their owner.
(
  cd /app
  gosu "${PUID:-911}:${PGID:-911}" /opt/mealie/bin/python /usr/local/lib/icestore/mealie-admin.py \
    || log "could not check the admin password; see the lines above"
) &

exec /app/run.sh "$@"
