#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each service's
# environment, prepares the database, then hands over to supervisord.
set -euo pipefail

DATA=${AIO_DATA:-/data}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}
HOSTS=${AIO_HOSTS:-/etc/hosts}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/aio.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/aio.conf}
GATEWAY_PORT=8080

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

PUBLIC_URL=${PUBLIC_URL:-http://localhost:6101}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
WS_URL=${PUBLIC_URL/#http/ws}/ws/v2
ADMIN_EMAIL=${ADMIN_EMAIL:-CHANGEME@example.com}
ADMIN_PASSWORD_ENV=${ADMIN_PASSWORD:-}

STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/minio" "$DATA/search"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

ensure_secret PG_PASSWORD 16
ensure_secret S3_ACCESS_KEY 10
ensure_secret S3_SECRET_KEY 20
ensure_secret JWT_SECRET 32
ensure_secret ADMIN_PASSWORD 12
ensure_secret MAIL_PASSWORD 12

PG_PASSWORD=$(secret PG_PASSWORD)
S3_ACCESS_KEY=$(secret S3_ACCESS_KEY)
S3_SECRET_KEY=$(secret S3_SECRET_KEY)
JWT_SECRET=$(secret JWT_SECRET)
ADMIN_PASSWORD=$(secret ADMIN_PASSWORD)
MAIL_PASSWORD=$(secret MAIL_PASSWORD)

# Mail viewer (/mail) login. It shows password-reset emails, so it is never open:
# blank MP_UI_AUTH = user "admin" with a password made on first start, kept in
# the data folder where the Files app can open it. A value you set wins.
MAIL_LOGIN_FILE=$DATA/mail-password.txt
MAIL_UI_AUTH=${MP_UI_AUTH:-}
if [ -z "$MAIL_UI_AUTH" ]; then
  MAIL_UI_AUTH="admin:$MAIL_PASSWORD"
  if [ ! -s "$MAIL_LOGIN_FILE" ]; then
    printf 'Mail viewer (/mail) login\nusername: admin\npassword: %s\n' "$MAIL_PASSWORD" > "$MAIL_LOGIN_FILE"
    chmod 600 "$MAIL_LOGIN_FILE"
  fi
fi

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
SHOW_URL=$(cred_url "$PUBLIC_URL")
cred_reset
cred_add URL "$SHOW_URL"
cred_add "ADMIN EMAIL" "$ADMIN_EMAIL"
if [ -n "$ADMIN_PASSWORD_ENV" ]; then
  ADMIN_PASSWORD=$ADMIN_PASSWORD_ENV
  cred_add "ADMIN PASSWORD" "(the one you set in ADMIN_PASSWORD)"
else
  cred_add "ADMIN PASSWORD" "$ADMIN_PASSWORD"
fi
cred_add "ADMIN CONSOLE" "$SHOW_URL/console"
if [ -n "${MP_UI_AUTH:-}" ]; then
  cred_add "MAIL VIEWER" "$SHOW_URL/mail  (the login you set in MP_UI_AUTH)"
else
  cred_add "MAIL VIEWER" "$SHOW_URL/mail  admin / $MAIL_PASSWORD"
fi
cred_note "Also saved in $SECRETS (mail viewer: $MAIL_LOGIN_FILE)"

if ! grep -q 'appflowy_postgres' "$HOSTS"; then
  echo "127.0.0.1 appflowy_postgres appflowy_redis appflowy-minio appflowy-mailpit appflowy_gotrue appflowy_cloud appflowy_search appflowy_web appflowy_admin" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
prep_chroots

WEB_PORT=80
if [ -f "$META/web.json" ]; then
  WEB_PORT=$(jq -r '(.ExposedPorts // {} | keys | map(split("/")[0] | tonumber)) as $p
    | if ($p | index(80)) then 80 elif ($p | length) > 0 then $p[0] else 80 end' "$META/web.json")
fi
if [ "$WEB_PORT" = "$GATEWAY_PORT" ]; then
  log "the web image listens on $GATEWAY_PORT, which the gateway needs. Change GATEWAY_PORT in aio-init.sh."
  exit 1
fi
log "web service port: $WEB_PORT, gateway port: $GATEWAY_PORT"

hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case " $WEB_PORT 3000 3100 8000 9000 9001 9999 8025 1025 4002 5432 6379 " in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; the admin console may not reach $PUBLIC_URL" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so the admin console can reach $PUBLIC_URL" ;;
  esac
fi
sed -e "s/@WEB_PORT@/$WEB_PORT/g" -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

mkdir -p "$RUN"
umask 077
PGURL="postgres://postgres:${PG_PASSWORD}@appflowy_postgres:5432/postgres"
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

write_env silo "$TZV" \
  "MINIO_ROOT_USER=$S3_ACCESS_KEY" \
  "MINIO_ROOT_PASSWORD=$S3_SECRET_KEY" \
  "MINIO_BROWSER_REDIRECT_URL=$PUBLIC_URL/minio"

write_env mailpit "$TZV" \
  "MP_SMTP_AUTH_ACCEPT_ANY=1" \
  "MP_SMTP_AUTH_ALLOW_INSECURE=1" \
  "MP_SMTP_BIND_ADDR=127.0.0.1:1025" \
  "MP_WEBROOT=/mail/" \
  "MP_UI_AUTH=$MAIL_UI_AUTH"

# Email: blank SMTP_HOST = the built-in mail viewer at /mail (nothing leaves
# the box). With a real server, the port defaults to 465 and the TLS mode to
# what that port needs. Blank values always mean "use the default" (:-).
SMTP_HOST=${SMTP_HOST:-${GOTRUE_SMTP_HOST:-}}
if [ -z "$SMTP_HOST" ]; then
  SMTP_HOST=appflowy-mailpit
  SMTP_PORT=1025
  SMTP_TLS=none
else
  SMTP_PORT=${SMTP_PORT:-${GOTRUE_SMTP_PORT:-465}}
  if [ "$SMTP_PORT" = 465 ]; then SMTP_TLS=${SMTP_TLS:-wrapper}; else SMTP_TLS=${SMTP_TLS:-required}; fi
fi
SMTP_USER=${SMTP_USER:-${GOTRUE_SMTP_USER:-}}
SMTP_PASS=${SMTP_PASS:-${GOTRUE_SMTP_PASS:-}}
SMTP_EMAIL=${SMTP_EMAIL:-${GOTRUE_SMTP_ADMIN_EMAIL:-${SMTP_USER:-noreply@appflowy.local}}}
case $SMTP_TLS in
  none|wrapper|required|opportunistic) ;;
  *) log "SMTP_TLS must be none, wrapper, required or opportunistic (got: $SMTP_TLS); using wrapper"; SMTP_TLS=wrapper ;;
esac

write_env gotrue "$TZV" \
  "GOTRUE_ADMIN_EMAIL=$ADMIN_EMAIL" \
  "GOTRUE_ADMIN_PASSWORD=$ADMIN_PASSWORD" \
  "GOTRUE_DISABLE_SIGNUP=${GOTRUE_DISABLE_SIGNUP:-false}" \
  "GOTRUE_SITE_URL=${GOTRUE_SITE_URL:-appflowy-flutter://}" \
  "GOTRUE_URI_ALLOW_LIST=${GOTRUE_URI_ALLOW_LIST:-**}" \
  "GOTRUE_JWT_SECRET=$JWT_SECRET" \
  "GOTRUE_JWT_EXP=${GOTRUE_JWT_EXP:-604800}" \
  "GOTRUE_JWT_ADMIN_GROUP_NAME=supabase_admin" \
  "GOTRUE_DB_DRIVER=postgres" \
  "API_EXTERNAL_URL=$PUBLIC_URL/gotrue" \
  "DATABASE_URL=${PGURL}?search_path=auth" \
  "PORT=9999" \
  "GOTRUE_SMTP_HOST=$SMTP_HOST" \
  "GOTRUE_SMTP_PORT=$SMTP_PORT" \
  "GOTRUE_SMTP_USER=$SMTP_USER" \
  "GOTRUE_SMTP_PASS=$SMTP_PASS" \
  "GOTRUE_SMTP_ADMIN_EMAIL=$SMTP_EMAIL" \
  "GOTRUE_MAILER_URLPATHS_CONFIRMATION=/gotrue/verify" \
  "GOTRUE_MAILER_URLPATHS_INVITE=/gotrue/verify" \
  "GOTRUE_MAILER_URLPATHS_RECOVERY=/gotrue/verify" \
  "GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE=/gotrue/verify" \
  "GOTRUE_SMTP_MAX_FREQUENCY=1ns" \
  "GOTRUE_RATE_LIMIT_EMAIL_SENT=${GOTRUE_RATE_LIMIT_EMAIL_SENT:-100}" \
  "GOTRUE_MAILER_AUTOCONFIRM=${GOTRUE_MAILER_AUTOCONFIRM:-true}" \
  "GOTRUE_EXTERNAL_GOOGLE_REDIRECT_URI=${GOTRUE_EXTERNAL_GOOGLE_REDIRECT_URI:-$PUBLIC_URL/gotrue/callback}" \
  "GOTRUE_EXTERNAL_GITHUB_REDIRECT_URI=${GOTRUE_EXTERNAL_GITHUB_REDIRECT_URI:-$PUBLIC_URL/gotrue/callback}" \
  "GOTRUE_EXTERNAL_DISCORD_REDIRECT_URI=${GOTRUE_EXTERNAL_DISCORD_REDIRECT_URI:-$PUBLIC_URL/gotrue/callback}" \
  "GOTRUE_EXTERNAL_APPLE_REDIRECT_URI=${GOTRUE_EXTERNAL_APPLE_REDIRECT_URI:-$PUBLIC_URL/gotrue/callback}"

write_env cloud "$TZV" \
  "RUST_LOG=${RUST_LOG:-info}" \
  "APPFLOWY_ENVIRONMENT=${APPFLOWY_ENVIRONMENT:-production}" \
  "APPFLOWY_DATABASE_URL=$PGURL" \
  "APPFLOWY_REDIS_URI=redis://appflowy_redis:6379" \
  "APPFLOWY_GOTRUE_JWT_SECRET=$JWT_SECRET" \
  "APPFLOWY_GOTRUE_BASE_URL=http://appflowy_gotrue:9999" \
  "APPFLOWY_S3_CREATE_BUCKET=true" \
  "APPFLOWY_S3_USE_MINIO=true" \
  "APPFLOWY_S3_MINIO_URL=http://appflowy-minio:9000" \
  "APPFLOWY_S3_ACCESS_KEY=$S3_ACCESS_KEY" \
  "APPFLOWY_S3_SECRET_KEY=$S3_SECRET_KEY" \
  "APPFLOWY_S3_BUCKET=appflowy" \
  "APPFLOWY_S3_PRESIGNED_URL_ENDPOINT=$PUBLIC_URL/minio-api" \
  "APPFLOWY_MAILER_SMTP_HOST=${APPFLOWY_MAILER_SMTP_HOST:-$SMTP_HOST}" \
  "APPFLOWY_MAILER_SMTP_PORT=${APPFLOWY_MAILER_SMTP_PORT:-$SMTP_PORT}" \
  "APPFLOWY_MAILER_SMTP_USERNAME=${APPFLOWY_MAILER_SMTP_USERNAME:-$SMTP_USER}" \
  "APPFLOWY_MAILER_SMTP_EMAIL=${APPFLOWY_MAILER_SMTP_EMAIL:-$SMTP_EMAIL}" \
  "APPFLOWY_MAILER_SMTP_PASSWORD=${APPFLOWY_MAILER_SMTP_PASSWORD:-$SMTP_PASS}" \
  "APPFLOWY_MAILER_SMTP_TLS_KIND=${APPFLOWY_MAILER_SMTP_TLS_KIND:-$SMTP_TLS}" \
  "APPFLOWY_ACCESS_CONTROL=${APPFLOWY_ACCESS_CONTROL:-true}" \
  "APPFLOWY_NOTIFICATION_ENABLE_EMAIL=${APPFLOWY_NOTIFICATION_ENABLE_EMAIL:-false}" \
  "APPFLOWY_DATABASE_MAX_CONNECTIONS=${APPFLOWY_DATABASE_MAX_CONNECTIONS:-40}" \
  "APPFLOWY_WEB_URL=$PUBLIC_URL" \
  "APPFLOWY_BASE_URL=$PUBLIC_URL" \
  "APPFLOWY_SEARCH_SERVICE_URL=http://appflowy_search:4002" \
  "APPFLOWY_SEARCH_REQUEST_TIMEOUT_SECS=${APPFLOWY_SEARCH_REQUEST_TIMEOUT_SECS:-10}" \
  "AI_ENABLED=${AI_ENABLED:-false}" \
  "SIGNUP_WHITELIST_ENABLED=${SIGNUP_WHITELIST_ENABLED:-false}" \
  "GUEST_INVITES_REQUIRE_ADMIN_APPROVAL=${GUEST_INVITES_REQUIRE_ADMIN_APPROVAL:-false}"

write_env worker "$TZV" \
  "RUST_LOG=${RUST_LOG:-info}" \
  "APPFLOWY_ENVIRONMENT=${APPFLOWY_ENVIRONMENT:-production}" \
  "APPFLOWY_WORKER_ENVIRONMENT=${APPFLOWY_WORKER_ENVIRONMENT:-production}" \
  "APPFLOWY_WORKER_REDIS_URL=redis://appflowy_redis:6379" \
  "APPFLOWY_WORKER_DATABASE_URL=$PGURL" \
  "APPFLOWY_WORKER_DATABASE_NAME=postgres" \
  "APPFLOWY_WORKER_IMPORT_TICK_INTERVAL=${APPFLOWY_WORKER_IMPORT_TICK_INTERVAL:-30}" \
  "APPFLOWY_S3_USE_MINIO=true" \
  "APPFLOWY_S3_MINIO_URL=http://appflowy-minio:9000" \
  "APPFLOWY_S3_ACCESS_KEY=$S3_ACCESS_KEY" \
  "APPFLOWY_S3_SECRET_KEY=$S3_SECRET_KEY" \
  "APPFLOWY_S3_BUCKET=appflowy" \
  "APPFLOWY_MAILER_SMTP_HOST=${APPFLOWY_MAILER_SMTP_HOST:-$SMTP_HOST}" \
  "APPFLOWY_MAILER_SMTP_PORT=${APPFLOWY_MAILER_SMTP_PORT:-$SMTP_PORT}" \
  "APPFLOWY_MAILER_SMTP_USERNAME=${APPFLOWY_MAILER_SMTP_USERNAME:-$SMTP_USER}" \
  "APPFLOWY_MAILER_SMTP_EMAIL=${APPFLOWY_MAILER_SMTP_EMAIL:-$SMTP_EMAIL}" \
  "APPFLOWY_MAILER_SMTP_PASSWORD=${APPFLOWY_MAILER_SMTP_PASSWORD:-$SMTP_PASS}" \
  "APPFLOWY_MAILER_SMTP_TLS_KIND=${APPFLOWY_MAILER_SMTP_TLS_KIND:-$SMTP_TLS}"

write_env search "$TZV" \
  "RUST_LOG=${RUST_LOG:-info}" \
  "APPFLOWY_SEARCH_HOST=[::]" \
  "APPFLOWY_SEARCH_PORT=4002" \
  "APPFLOWY_SEARCH_DATABASE_URL=$PGURL" \
  "APPFLOWY_SEARCH_REDIS_URL=redis://appflowy_redis:6379" \
  "APPFLOWY_S3_USE_MINIO=true" \
  "APPFLOWY_S3_MINIO_URL=http://appflowy-minio:9000" \
  "APPFLOWY_S3_ACCESS_KEY=$S3_ACCESS_KEY" \
  "APPFLOWY_S3_SECRET_KEY=$S3_SECRET_KEY" \
  "APPFLOWY_S3_BUCKET=appflowy" \
  "APPFLOWY_BACKGROUND_INDEXER_ENABLED=true" \
  "APPFLOWY_INDEXER_DATABASE_ENABLED=false" \
  "APPFLOWY_KEYWORD_SEARCH_ENABLED=true" \
  "APPFLOWY_KEYWORD_WORKER_ENABLED=true" \
  "APPFLOWY_KEYWORD_INDEX_MAP_SIZE_BYTES=2147483648" \
  "APPFLOWY_KEYWORD_INDEX_DIR=$DATA/search" \
  "APPFLOWY_GOTRUE_JWT_SECRET=$JWT_SECRET"

write_env admin "$TZV" \
  "APPFLOWY_GOTRUE_BASE_URL=http://appflowy_gotrue:9999" \
  "APPFLOWY_BASE_URL=$PUBLIC_URL" \
  "PORT=3100"

write_env web "$TZV" \
  "APPFLOWY_BASE_URL=$PUBLIC_URL" \
  "APPFLOWY_GOTRUE_BASE_URL=$PUBLIC_URL/gotrue" \
  "APPFLOWY_WS_BASE_URL=$WS_URL"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Upstream names the services read themselves: sign-in providers and any other
# GOTRUE_* setting go to gotrue, APPFLOWY_* to the API (worker settings to the
# worker), MP_* to the mail viewer, MINIO_*/SILO_* to file storage.
pass_env gotrue  'GOTRUE_[A-Z0-9_]+'
pass_env cloud   'APPFLOWY_[A-Z0-9_]+'
pass_env worker  'APPFLOWY_WORKER_[A-Z0-9_]+'
pass_env mailpit 'MP_[A-Z0-9_]+'
pass_env silo    '(MINIO|SILO)_[A-Z0-9_]+'

for f in "$STATE"/overrides/*.env; do
  [ -f "$f" ] || continue
  svc=$(basename "$f" .env)
  log "applying your overrides to $svc"
  cat "$f" >> "$RUN/$svc.env"
done

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

pg_setup /usr/lib/postgresql/16/bin
chown redis:redis "$DATA/redis"

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
