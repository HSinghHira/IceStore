#!/bin/sh
# IceStore start script for Speedtest Tracker. Runs as root before
# s6-overlay:
#
#   - APP_KEY: set in the app settings wins; blank means the key in
#     /config/.app_key, made on first start (upstream's init halts without
#     one).
#   - ADMIN_PASSWORD: blank means the one in /config/.admin_password, made on
#     first start. Speedtest Tracker only uses ADMIN_EMAIL and ADMIN_PASSWORD
#     when it makes its first user.
#   - Blank variables are dropped, so Speedtest Tracker uses its defaults
#     (ZimaOS passes settings left empty as empty strings).
#
# Then it hands over to upstream's /init (s6-overlay) unchanged.
set -eu

CONFIG=/config
KEY_FILE=$CONFIG/.app_key
PASS_FILE=$CONFIG/.admin_password
log() { echo "[icestore] $*"; }

mkdir -p "$CONFIG"
umask 077

if [ -n "${APP_KEY:-}" ]; then
  if [ -s "$KEY_FILE" ] && [ "$(cat "$KEY_FILE")" != "$APP_KEY" ]; then
    log "APP_KEY differs from the key used before; using APP_KEY (stored secrets made with the old key can't be read)."
    cp "$KEY_FILE" "$KEY_FILE.previous"
  fi
  printf '%s' "$APP_KEY" > "$KEY_FILE.tmp"
  mv "$KEY_FILE.tmp" "$KEY_FILE"
elif [ ! -s "$KEY_FILE" ]; then
  printf 'base64:%s' "$(head -c 32 /dev/urandom | base64 | tr -d '\n')" > "$KEY_FILE.tmp"
  mv "$KEY_FILE.tmp" "$KEY_FILE"
  log "first start: made this install's APP_KEY in /config/.app_key."
fi
APP_KEY=$(cat "$KEY_FILE")
export APP_KEY

[ -n "${ADMIN_EMAIL:-}" ] || ADMIN_EMAIL=admin@example.com
PASSWORD_SET=
if [ -n "${ADMIN_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  ADMIN_PASSWORD=$(cat "$PASS_FILE")
else
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in /config/.admin_password."
fi
export ADMIN_EMAIL ADMIN_PASSWORD
umask 022

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done
[ -n "${DISPLAY_TIMEZONE:-}" ] || DISPLAY_TIMEZONE=${TZ:-Etc/UTC}
[ -n "$DISPLAY_TIMEZONE" ] || DISPLAY_TIMEZONE=Etc/UTC
export DISPLAY_TIMEZONE

LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh
cred_reset
cred_add URL "http://<your ZimaOS IP>:6768"
cred_add EMAIL "$ADMIN_EMAIL"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/speedtest-tracker/config/.admin_password"
fi
cred_note "Only used for the first user. Change it in your profile after you sign in."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:80/api/healthcheck &

exec /init "$@"
