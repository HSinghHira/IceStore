#!/bin/sh
# IceStore start script for NoteDiscovery. Runs once per start:
#
#   - AUTHENTICATION_ENABLED: blank means true (upstream's default is off).
#   - AUTHENTICATION_PASSWORD: set in the app settings wins; blank means the
#     one in /app/data/.icestore/password, made on first start (upstream's
#     default is admin).
#   - AUTHENTICATION_SECRET_KEY: kept in /app/data/.icestore/secrets.env, so
#     sign-ins last across restarts.
#   - Blank variables are dropped, so NoteDiscovery uses its defaults
#     (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's command runs, unchanged.
set -eu

DIR=/app/data/.icestore
SECRETS=$DIR/secrets.env
PASS_FILE=$DIR/password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

rand() { python -c "import secrets; print(secrets.token_hex($1))"; }

mkdir -p "$DIR"
umask 077
touch "$SECRETS"
grep -q '^AUTHENTICATION_SECRET_KEY=' "$SECRETS" || echo "AUTHENTICATION_SECRET_KEY=$(rand 32)" >> "$SECRETS"
[ -n "${AUTHENTICATION_SECRET_KEY:-}" ] || AUTHENTICATION_SECRET_KEY=$(secret AUTHENTICATION_SECRET_KEY)

PASSWORD_SET=
if [ -n "${AUTHENTICATION_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  AUTHENTICATION_PASSWORD=$(cat "$PASS_FILE")
else
  rand 12 > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  AUTHENTICATION_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the password in /app/data/.icestore/password."
fi
[ -n "${AUTHENTICATION_ENABLED:-}" ] || AUTHENTICATION_ENABLED=true
export AUTHENTICATION_SECRET_KEY AUTHENTICATION_PASSWORD AUTHENTICATION_ENABLED
umask 022

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6788"
if [ "$AUTHENTICATION_ENABLED" = "true" ]; then
  if [ -n "$PASSWORD_SET" ]; then
    cred_add PASSWORD "(the one you set in AUTHENTICATION_PASSWORD)"
  else
    cred_add PASSWORD "$AUTHENTICATION_PASSWORD"
    cred_note "Also saved in /DATA/AppData/notediscovery/data/.icestore/password"
  fi
  cred_note "To change it, set AUTHENTICATION_PASSWORD in the app settings."
else
  cred_note "The login is off (AUTHENTICATION_ENABLED=false): anyone on your network can open your notes."
fi
/usr/local/lib/icestore/credentials.sh &

exec "$@"
