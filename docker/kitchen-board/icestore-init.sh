#!/bin/sh
# IceStore start script for Kitchen Board. Makes sure /data/.secret_key
# holds the SECRET_KEY in use, then hands over to upstream's entrypoint
# (which fixes ownership of /data and runs the app as the kitchenboard user).
#
#   - SECRET_KEY set (from the app settings): that key is used and written
#     to the file.
#   - SECRET_KEY blank or missing: the key already in the file is used, or a
#     new random one is made on first start.
# The data path can be moved for testing outside Docker (ICESTORE_DATA).
set -eu

DATA=${ICESTORE_DATA:-/data}
KEY_FILE=$DATA/.secret_key
log() { echo "[icestore] $*"; }

mkdir -p "$DATA"
old_umask=$(umask)
umask 077
if [ -n "${SECRET_KEY:-}" ]; then
  if [ -s "$KEY_FILE" ] && [ "$(cat "$KEY_FILE")" != "$SECRET_KEY" ]; then
    log "SECRET_KEY differs from the one used before; using SECRET_KEY (everyone has to sign in again)."
    cp "$KEY_FILE" "$KEY_FILE.previous"
  fi
  printf '%s' "$SECRET_KEY" > "$KEY_FILE.tmp"
  mv "$KEY_FILE.tmp" "$KEY_FILE"
elif [ ! -s "$KEY_FILE" ]; then
  # 32 random bytes as 64 hex characters, like upstream's `openssl rand -hex 32`.
  head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$KEY_FILE.tmp"
  mv "$KEY_FILE.tmp" "$KEY_FILE"
  log "first start: made this install's SECRET_KEY in the data folder (.secret_key)."
fi
umask "$old_umask"
SECRET_KEY=$(cat "$KEY_FILE")
export SECRET_KEY

# Blank values from the app settings mean "use the default": drop them so
# Kitchen Board's own defaults apply (an empty number would stop it).
for name in DATABASE_URL KB_LANGUAGE ADMIN_EMAIL ADMIN_PASSWORD ALLOWED_HOSTS \
            ACCESS_TOKEN_EXPIRE_MINUTES SECURE_COOKIES TRUSTED_PROXY_IPS \
            FORWARDED_ALLOW_IPS APP_BASE_URL PASSWORD_RESET_EXPIRE_MINUTES \
            MAGIC_LOGIN_EXPIRE_MINUTES NIGHTLY_BACKUP_KEEP DB_WATCHDOG_EXIT_MINUTES \
            OIDC_ENABLED OIDC_ISSUER OIDC_CLIENT_ID OIDC_CLIENT_SECRET OIDC_DISPLAY_NAME \
            OIDC_SCOPES OIDC_REDIRECT_URI OIDC_AUTO_PROVISION OIDC_ENFORCE_LOCAL_MFA \
            OIDC_ALLOW_PRIVATE_NETWORK VAPID_PRIVATE_KEY VAPID_PUBLIC_KEY VAPID_EMAIL \
            APPRISE_URLS SMTP_HOST SMTP_PORT SMTP_USERNAME SMTP_PASSWORD SMTP_FROM \
            SMTP_ENCRYPTION SMTP_USE_TLS SMTP_AUTH_MODE SMTP_OAUTH_PROVIDER \
            SMTP_OAUTH_TOKEN_URL SMTP_OAUTH_CLIENT_ID SMTP_OAUTH_CLIENT_SECRET \
            SMTP_OAUTH_REFRESH_TOKEN SMTP_OAUTH_SCOPE SMTP_OAUTH_REDIRECT_URI; do
  eval "val=\${$name-unset}"
  [ -n "$val" ] || unset "$name"
done

if [ -n "${ICESTORE_DRY_RUN:-}" ]; then
  env | grep -E '^(SECRET_KEY|ADMIN_|KB_|SMTP_|ALLOWED_HOSTS)' | sort
  exit 0
fi

exec /entrypoint.sh "$@"
