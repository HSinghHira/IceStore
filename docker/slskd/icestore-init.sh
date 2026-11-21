#!/bin/sh
# IceStore start script for slskd. Runs as root, once per start:
#
#   - SLSKD_PASSWORD: set in the app settings wins; blank means the one in
#     /app/.web_password, made on first start (upstream's default is slskd).
#   - SLSKD_JWT_KEY: kept in /app/secrets.env, so sign-ins last across
#     restarts.
#   - Blank variables are dropped, so slskd uses its defaults
#     (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's /entrypoint.sh runs, unchanged (it applies PUID/PGID).
set -eu

SECRETS=/app/secrets.env
PASS_FILE=/app/.web_password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

rand() { head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; }

mkdir -p /app
umask 077
touch "$SECRETS"
grep -q '^SLSKD_JWT_KEY=' "$SECRETS" || echo "SLSKD_JWT_KEY=$(rand 32)" >> "$SECRETS"
[ -n "${SLSKD_JWT_KEY:-}" ] || SLSKD_JWT_KEY=$(secret SLSKD_JWT_KEY)

[ -n "${SLSKD_USERNAME:-}" ] || SLSKD_USERNAME=slskd
PASSWORD_SET=
if [ -n "${SLSKD_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  SLSKD_PASSWORD=$(cat "$PASS_FILE")
else
  rand 12 > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  SLSKD_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the web UI password in /app/.web_password."
fi
export SLSKD_JWT_KEY SLSKD_USERNAME SLSKD_PASSWORD
umask 022

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done

# Folders and options-from-the-web-UI, unless set in the app settings.
[ -n "${SLSKD_DOWNLOADS_DIR:-}" ] || SLSKD_DOWNLOADS_DIR=/downloads
[ -n "${SLSKD_INCOMPLETE_DIR:-}" ] || SLSKD_INCOMPLETE_DIR=/downloads/incomplete
[ -n "${SLSKD_SHARED_DIR:-}" ] || SLSKD_SHARED_DIR=/music
[ -n "${SLSKD_REMOTE_CONFIGURATION:-}" ] || SLSKD_REMOTE_CONFIGURATION=true
export SLSKD_DOWNLOADS_DIR SLSKD_INCOMPLETE_DIR SLSKD_SHARED_DIR SLSKD_REMOTE_CONFIGURATION

if [ -z "${SLSKD_SLSK_USERNAME:-}" ]; then
  log "SLSKD_SLSK_USERNAME is empty: slskd starts, but it can't join the Soulseek network until you set SLSKD_SLSK_USERNAME and SLSKD_SLSK_PASSWORD in the app settings (or in the web UI's Options)."
fi

cred_reset
cred_add URL "http://<your ZimaOS IP>:6779"
cred_add USERNAME "$SLSKD_USERNAME"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in SLSKD_PASSWORD)"
else
  cred_add PASSWORD "$SLSKD_PASSWORD"
  cred_note "Also saved in /DATA/AppData/slskd/app/.web_password"
fi
cred_note "This is the web UI login. Your Soulseek account goes in SLSKD_SLSK_USERNAME and SLSKD_SLSK_PASSWORD."
/usr/local/lib/icestore/credentials.sh &

exec /entrypoint.sh "$@"
