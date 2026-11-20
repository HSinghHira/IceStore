#!/bin/sh
# IceStore start script for Paperless-ngx. Runs as root before s6-overlay:
#
#   - PAPERLESS_SECRET_KEY: set in the app settings wins; blank means the key
#     in /usr/src/paperless/data/.secret_key, made on first start.
#   - PAPERLESS_ADMIN_USER (default admin) / PAPERLESS_ADMIN_PASSWORD: blank
#     password means the one in data/.admin_password, made on first start.
#     Paperless only creates that user when no user of that name exists, and
#     never changes an existing password.
#   - PAPERLESS_TIME_ZONE follows TZ unless set.
#
# Then it hands over to upstream's /init (s6-overlay) unchanged.
set -eu

DATA=${PAPERLESS_DATA_DIR:-/usr/src/paperless/data}
KEY_FILE=$DATA/.secret_key
PASS_FILE=$DATA/.admin_password
log() { echo "[icestore] $*"; }

mkdir -p "$DATA"
umask 077

# ---- secret key ----
if [ -n "${PAPERLESS_SECRET_KEY:-}" ]; then
  if [ -s "$KEY_FILE" ] && [ "$(cat "$KEY_FILE")" != "$PAPERLESS_SECRET_KEY" ]; then
    log "PAPERLESS_SECRET_KEY differs from the key used before; using PAPERLESS_SECRET_KEY (everyone has to sign in again)."
    cp "$KEY_FILE" "$KEY_FILE.previous"
  fi
  printf '%s' "$PAPERLESS_SECRET_KEY" > "$KEY_FILE.tmp"
  mv "$KEY_FILE.tmp" "$KEY_FILE"
elif [ ! -s "$KEY_FILE" ]; then
  head -c 48 /dev/urandom | base64 | tr -d '\n/+=' > "$KEY_FILE.tmp"
  mv "$KEY_FILE.tmp" "$KEY_FILE"
  log "first start: made this install's secret key in the data folder (.secret_key)."
fi
PAPERLESS_SECRET_KEY=$(cat "$KEY_FILE")
export PAPERLESS_SECRET_KEY

# ---- first admin ----
[ -n "${PAPERLESS_ADMIN_USER:-}" ] || PAPERLESS_ADMIN_USER=admin
PASSWORD_SET=
if [ -n "${PAPERLESS_ADMIN_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  PAPERLESS_ADMIN_PASSWORD=$(cat "$PASS_FILE")
else
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  PAPERLESS_ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in the data folder (.admin_password)."
fi
export PAPERLESS_ADMIN_USER PAPERLESS_ADMIN_PASSWORD

# ---- other defaults (ZimaOS passes blank variables as empty strings) ----
[ -n "${PAPERLESS_TIME_ZONE:-}" ] || PAPERLESS_TIME_ZONE=${TZ:-UTC}
[ -n "$PAPERLESS_TIME_ZONE" ] || PAPERLESS_TIME_ZONE=UTC
export PAPERLESS_TIME_ZONE
for v in PAPERLESS_URL PAPERLESS_OCR_LANGUAGE PAPERLESS_OCR_LANGUAGES USERMAP_UID USERMAP_GID; do
  eval "val=\${$v:-}"
  # shellcheck disable=SC2154
  [ -n "$val" ] || unset "$v"
done
umask 022

# ---- CREDENTIALS banner (docker/_common) ----
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh
cred_reset
cred_add URL "http://<your ZimaOS IP>:6748"
cred_add USERNAME "$PAPERLESS_ADMIN_USER"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in PAPERLESS_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$PAPERLESS_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/paperless-ngx/data/.admin_password"
fi
cred_note "Change the password in Profile after you sign in; this one is only used to create the first admin."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8000/accounts/login/ &

exec /init "$@"
