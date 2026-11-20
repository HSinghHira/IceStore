#!/bin/sh
# IceStore start script for BookStack. Runs as root before s6-overlay:
#
#   - APP_KEY: set in the app settings wins; blank means the key in
#     /config/.app_key, made on first start.
#   - The MariaDB password (inside the container only) is made on first start
#     and kept in /config/.db_password.
#   - ADMIN_PASSWORD: blank means the one in /config/.admin_password, made on
#     first start. It replaces BookStack's default "password" on
#     admin@admin.com, only while that account still has the default.
#   - APP_URL: blank means BookStack follows the address in the browser.
#
# Then it hands over to upstream's /init (s6-overlay) unchanged.
set -eu

CONFIG=/config
KEY_FILE=$CONFIG/.app_key
DBPASS_FILE=$CONFIG/.db_password
PASS_FILE=$CONFIG/.admin_password
log() { echo "[icestore] $*"; }

mkdir -p "$CONFIG/www"
umask 077

# ---- APP_KEY ----
if [ -n "${APP_KEY:-}" ]; then
  if [ -s "$KEY_FILE" ] && [ "$(cat "$KEY_FILE")" != "$APP_KEY" ]; then
    log "APP_KEY differs from the key used before; using APP_KEY (everyone has to sign in again)."
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

# ---- database (MariaDB inside the container) ----
if [ ! -s "$DBPASS_FILE" ]; then
  head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$DBPASS_FILE.tmp"
  mv "$DBPASS_FILE.tmp" "$DBPASS_FILE"
fi
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=bookstack
DB_USERNAME=bookstack
DB_PASSWORD=$(cat "$DBPASS_FILE")
export DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD

# ---- first admin ----
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
export ADMIN_PASSWORD

# ---- APP_URL ----
# BookStack builds every link from APP_URL when it is set, and from the
# browser's address when it is empty. The .env upstream copies in has
# APP_URL=https://example.com, so make the .env ourselves on first start.
if [ ! -s "$CONFIG/www/.env" ]; then
  sed 's|^APP_URL=.*|APP_URL=|' /app/www/.env.example > "$CONFIG/www/.env"
fi
[ -n "${APP_URL:-}" ] || unset APP_URL

# ZimaOS passes blank variables as empty strings: drop them so BookStack
# uses its defaults.
[ -n "${APP_TIMEZONE:-}" ] || APP_TIMEZONE=${TZ:-UTC}
[ -n "$APP_TIMEZONE" ] || APP_TIMEZONE=UTC
export APP_TIMEZONE
for v in APP_LANG APP_DEFAULT_DARK_MODE SESSION_LIFETIME QUEUE_CONNECTION \
         MAIL_DRIVER MAIL_HOST MAIL_PORT MAIL_USERNAME MAIL_PASSWORD MAIL_ENCRYPTION \
         MAIL_FROM MAIL_FROM_NAME MAIL_VERIFY_SSL \
         AUTH_METHOD OIDC_NAME OIDC_CLIENT_ID OIDC_CLIENT_SECRET OIDC_ISSUER \
         OIDC_ISSUER_DISCOVER OIDC_DISPLAY_NAME_CLAIMS OIDC_USER_TO_GROUPS OIDC_GROUPS_CLAIM \
         ALLOWED_IFRAME_HOSTS ALLOWED_IFRAME_SOURCES; do
  eval "val=\${$v:-}"
  # shellcheck disable=SC2154
  [ -n "$val" ] || unset "$v"
done
umask 022

# ---- CREDENTIALS banner (docker/_common) ----
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh
cred_reset
cred_add URL "http://<your ZimaOS IP>:6758"
cred_add EMAIL "admin@admin.com"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/bookstack/config/.admin_password"
fi
cred_note "Change the email and password in My Account after you sign in."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:80/login &

exec /init "$@"
