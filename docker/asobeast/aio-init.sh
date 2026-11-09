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

# Shared IceStore helpers: log, ensure_secret, secret, cred_add (docker/_common).
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# ---- public address: upstream's WEB_PUBLIC_URL. The app itself follows the
# ---- browser's address; this one is only used for links in emails and
# ---- alerts, and decides whether the sign-in cookie is marked secure. ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6700}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL: AsoBeast works from any address, but links in emails will say localhost;"
    log "set PUBLIC_URL to the address you open it at, like http://192.168.1.20:6700" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret PG_PASSWORD 16
# Signs sessions (upstream asks for openssl rand -hex 32).
ensure_secret AUTH_SECRET 32
# Encrypts the App Store Connect and Google Play credentials owners connect
# (upstream asks for openssl rand -base64 32). Changing it makes them unreadable.
ensure_b64 STORE_CONNECT_ENCRYPTION_KEY 32

PG_PASSWORD=$(secret PG_PASSWORD)

# ---- CREDENTIALS banner, printed on every boot once AsoBeast answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "Open the URL and create the owner account; sign-up then closes."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' redis api web' "$HOSTS"; then
  echo "127.0.0.1 postgres redis api web" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
# api and web keep nothing on disk (everything is in Postgres and Redis).
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 4000 5432 6379 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
# Secure sign-in cookie only when PUBLIC_URL is https (see nginx.conf.tpl).
case $PUBLIC_URL in
  https://*) COOKIE_FLAGS="" ;;
  *) COOKIE_FLAGS="proxy_cookie_flags ~ nosecure;"
     log "PUBLIC_URL is plain http, so the sign-in cookie is sent without the secure flag" ;;
esac
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@COOKIE_FLAGS@/$COOKIE_FLAGS/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# Upstream's api service. The gateway and the web app are two proxies in
# front of it (TRUST_PROXY counts the web app as one).
write_env api "$TZV" \
  "DATABASE_URL=postgresql://asobeast:$PG_PASSWORD@127.0.0.1:5432/asobeast" \
  "REDIS_HOST=127.0.0.1" \
  "REDIS_PORT=6379" \
  "PORT=4000" \
  "NODE_ENV=production" \
  "AUTH_SECRET=$(secret AUTH_SECRET)" \
  "AUTH_COOKIE_SECURE=true" \
  "STORE_CONNECT_ENCRYPTION_KEY=$(secret STORE_CONNECT_ENCRYPTION_KEY)" \
  "WEB_PUBLIC_URL=$PUBLIC_URL" \
  "TRUST_PROXY=${ASOBEAST_TRUST_PROXY:-2}" \
  "DEFAULT_COUNTRY=${DEFAULT_COUNTRY:-us}" \
  "LOG_LEVEL=${LOG_LEVEL:-log}"

# Upstream's web service.
write_env web "$TZV" \
  "API_INTERNAL_URL=http://127.0.0.1:4000" \
  "HOSTNAME=127.0.0.1" \
  "PORT=3000" \
  "NODE_ENV=production" \
  "TRUST_PROXY=${ASOBEAST_TRUST_PROXY_WEB:-1}"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional AsoBeast setting from the README Variables list, by its own
# name: sign-up, email, AI, scraping rates, schedules, retention, alerts,
# Apple Ads, Google Play sign-in, proxies.
pass_env api 'AUTH_(ALLOW_REGISTRATION|REGISTRATION_WORKSPACE|SESSION_DAYS)|SMTP_[A-Z_]+|OPENAI_(API_KEY|BASE_URL)|AI_MODEL|AI_CALLS_PER_MONTH|SCREENSHOT_OCR(_LANGUAGES)?|SCRAPE_(ITUNES|GPLAY)_RPM|CRON_[A-Z_]+|RETENTION_[A-Z_]+|ALERT_[A-Z_]+|WEBHOOK_ALLOW_PRIVATE_TARGETS|APPLE_ADS_[A-Z_]+|GOOGLE_PLAY_OAUTH_CLIENT_(ID|SECRET)|PROXY_[A-Z_]+|ACTIONS_[A-Z_]+|API_DOCS|BULL_BOARD_ENABLED|ACCOUNT_DELETION_GRACE_DAYS'
pass_env web 'API_PROXY_TIMEOUT_MS|STATUS_PAGE_URL'

# Files in /data/state/overrides/<service>.env are appended last, so users can
# change any service setting without rebuilding the image.
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

# ---- built-in data folders and first-start database ----
chown redis:redis "$DATA/redis"
pg_setup /usr/lib/postgresql/18/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb
  # Upstream's postgres image makes "asobeast" the owner of its database;
  # the api's Prisma migrations make the tables.
  pg_start_local
  pg_psql -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE asobeast LOGIN PASSWORD :'pw';
CREATE DATABASE asobeast OWNER asobeast;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
