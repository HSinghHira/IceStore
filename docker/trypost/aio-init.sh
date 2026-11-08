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

# ---- public address: TryPost's APP_URL. Uploaded images and videos are
# ---- linked from it, and so are the sign-in callbacks of every social
# ---- network, so it must be the address people open. ----
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6190}
PUBLIC_URL=${PUBLIC_URL%/}
# The compose file ships http://[ZIMAOS-IP-ADDRESS]:6190 so people see they
# must put their IP there. Until they do, run on localhost (so TryPost
# starts) and show the "set PUBLIC_URL" note to every other address (below).
case $PUBLIC_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "PUBLIC_URL is still $PUBLIC_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings"
    PUBLIC_URL=${PUBLIC_URL//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
host=${hostport%:*}
ADMIN_EMAIL=${ADMIN_EMAIL:-CHANGEME@example.com}
ADMIN_PASSWORD_ENV=${ADMIN_PASSWORD:-}

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/storage"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"
chown redis:redis "$DATA/redis" 2>/dev/null || true

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret PG_PASSWORD 16
# Laravel's APP_KEY encrypts sessions and the social network tokens kept in
# the database: changing it later signs everyone out and disconnects every
# channel.
ensure_b64 APP_KEY_B64 32
ensure_secret REVERB_APP_SECRET 24
ensure_secret ADMIN_PASSWORD 9

PG_PASSWORD=$(secret PG_PASSWORD)
APP_KEY="base64:$(secret APP_KEY_B64)"
REVERB_APP_SECRET=$(secret REVERB_APP_SECRET)
ADMIN_PASSWORD=$(secret ADMIN_PASSWORD)
[ -z "$ADMIN_PASSWORD_ENV" ] || ADMIN_PASSWORD=$ADMIN_PASSWORD_ENV

# Passport (API keys and MCP sign-in) signs tokens with an RSA key pair.
# Upstream wants them in the environment, with \n for each line break.
PASSPORT_KEY=$STATE/passport-private.key
PASSPORT_PUB=$STATE/passport-public.key
if [ ! -s "$PASSPORT_KEY" ] || [ ! -s "$PASSPORT_PUB" ]; then
  log "first start: making the Passport keys for API and MCP tokens"
  (umask 077; openssl genrsa -out "$PASSPORT_KEY" 4096 2>/dev/null)
  openssl rsa -in "$PASSPORT_KEY" -pubout -out "$PASSPORT_PUB" 2>/dev/null
fi
one_line() { awk '{printf "%s\\n", $0}' "$1"; }
PASSPORT_PRIVATE_KEY=$(one_line "$PASSPORT_KEY")
PASSPORT_PUBLIC_KEY=$(one_line "$PASSPORT_PUB")

# ---- CREDENTIALS banner, printed on every boot once TryPost answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add EMAIL "$ADMIN_EMAIL"
if [ -n "$ADMIN_PASSWORD_ENV" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PASSWORD"
fi
cred_note "This account is made on the first start. Invite your team from Settings, Members."
cred_note "Changed the password in TryPost? Your new password is the one that works."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' trypost-pgsql' "$HOSTS"; then
  echo "127.0.0.1 pgsql redis trypost trypost-pgsql trypost-redis" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: uploaded media (storage/app, the "storage" volume in
  # upstream's compose) lives in /data/storage. Upstream's entrypoint gives
  # it to www-data.
  if [ "$name" = trypost ]; then
    local s="$d/var/www/html/storage/app"
    mkdir -p "$s"
    mountpoint -q "$s" || mount --bind "$DATA/storage" "$s" 2>/dev/null \
      || log "warning: could not mount $DATA/storage into the trypost chroot"
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 80 5432 6379 8081 9000 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

# Media links and social sign-in callbacks are built from PUBLIC_URL, so with
# the default (localhost) anyone on another address gets a short note saying
# what to set instead. Requests to localhost/127.0.0.1 (the box itself, the
# healthcheck) still go through.
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "TryPost is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so images and social network sign-ins would point at localhost.\n\nOpen the TryPost app settings in ZimaOS, set PUBLIC_URL to http://$host:6190 and save. After the app restarts, open this page again.\n";
}
EOF
    ;;
  *) : > "$GUARD_FILE" ;;
esac
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@GUARD_FILE@/$(sed_escape "$GUARD_FILE")/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# Same environment as upstream's compose.prod.yaml. Reverb listens on 8081
# here (the Dockerfile moves it); the browser reaches it through /app/ on the
# address it opened, so REVERB_HOST/PORT are only the server-side address.
# Every social network's sign-in callback is PUBLIC_URL/accounts/<name>/callback,
# as in upstream's .env.example.
write_env trypost "$TZV" \
  "APP_NAME=TryPost" \
  "APP_ENV=production" \
  "APP_DEBUG=false" \
  "APP_KEY=$APP_KEY" \
  "APP_URL=$PUBLIC_URL" \
  "SELF_HOSTED=true" \
  "TRYPOST_TARGET=production" \
  "DB_CONNECTION=pgsql" \
  "DB_HOST=127.0.0.1" \
  "DB_PORT=5432" \
  "DB_DATABASE=trypost" \
  "DB_USERNAME=trypost" \
  "DB_PASSWORD=$PG_PASSWORD" \
  "REDIS_HOST=127.0.0.1" \
  "REDIS_PORT=6379" \
  "QUEUE_CONNECTION=redis" \
  "CACHE_STORE=redis" \
  "SESSION_DRIVER=database" \
  "BROADCAST_CONNECTION=reverb" \
  "REVERB_APP_ID=1001" \
  "REVERB_APP_KEY=trypost-reverb-key" \
  "REVERB_APP_SECRET=$REVERB_APP_SECRET" \
  "REVERB_HOST=127.0.0.1" \
  "REVERB_PORT=8081" \
  "REVERB_SERVER_PORT=8081" \
  "REVERB_SCHEME=http" \
  "PASSPORT_PRIVATE_KEY=$PASSPORT_PRIVATE_KEY" \
  "PASSPORT_PUBLIC_KEY=$PASSPORT_PUBLIC_KEY" \
  "FILESYSTEM_DISK=public" \
  "MAIL_MAILER=${MAIL_MAILER:-log}" \
  "MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS:-hello@example.com}" \
  "MAIL_FROM_NAME=TryPost" \
  "LINKEDIN_CLIENT_REDIRECT=$PUBLIC_URL/accounts/linkedin/callback" \
  "X_CLIENT_REDIRECT=$PUBLIC_URL/accounts/x/callback" \
  "TIKTOK_CLIENT_REDIRECT=$PUBLIC_URL/accounts/tiktok/callback" \
  "FACEBOOK_CLIENT_REDIRECT=$PUBLIC_URL/accounts/facebook/callback" \
  "INSTAGRAM_CLIENT_REDIRECT=$PUBLIC_URL/accounts/instagram/callback" \
  "THREADS_CLIENT_REDIRECT=$PUBLIC_URL/accounts/threads/callback" \
  "GOOGLE_CLIENT_REDIRECT=$PUBLIC_URL/accounts/youtube/callback" \
  "GOOGLE_AUTH_CALLBACK=$PUBLIC_URL/auth/google/callback" \
  "GOOGLE_BUSINESS_CLIENT_REDIRECT=$PUBLIC_URL/accounts/google-business/callback" \
  "GITHUB_AUTH_CALLBACK=$PUBLIC_URL/auth/github/callback" \
  "PINTEREST_CLIENT_REDIRECT=$PUBLIC_URL/accounts/pinterest/callback" \
  "DISCORD_CLIENT_REDIRECT=$PUBLIC_URL/accounts/discord/callback" \
  "GOOGLE_MEDIA_CLIENT_REDIRECT=$PUBLIC_URL/integrations/google/callback"

# The first account (run-svc's admin job). Only used while no account exists.
write_env admin \
  "ADMIN_EMAIL=$ADMIN_EMAIL" \
  "ADMIN_PASSWORD=$ADMIN_PASSWORD"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional TryPost setting from the README Variables list, by its own
# name: email, each social network's app keys, sign-in with Google/GitHub,
# AI providers, media sources, language and log level. Upstream reads them
# when it caches its config on every start.
pass_env trypost 'MAIL_(HOST|PORT|USERNAME|PASSWORD|SCHEME|FROM_NAME)|(LINKEDIN|X|TIKTOK|FACEBOOK|INSTAGRAM|THREADS|PINTEREST|GOOGLE|GOOGLE_BUSINESS|GITHUB|DISCORD|GOOGLE_MEDIA|CANVA)_CLIENT_(ID|SECRET|REDIRECT)|GOOGLE_AUTH_(ENABLED|CALLBACK)|GITHUB_AUTH_(ENABLED|CALLBACK)|DISCORD_BOT_TOKEN|TELEGRAM_(BOT_TOKEN|BOT_USERNAME|WEBHOOK_SECRET)|(OPENAI|ANTHROPIC|GEMINI|OPENROUTER|ELEVENLABS)_API_KEY|AI_(TEXT|AUDIO)_PROVIDER|UNSPLASH_(ACCESS|SECRET)_KEY|GOOGLE_MEDIA_(API_KEY|APP_ID)|GOOGLE_(DRIVE|PHOTOS)_ENABLED|CANVA_ENABLED|APP_LOCALE|LOG_LEVEL|POST_HISTORY_RETENTION_DAYS'
pass_env admin 'ADMIN_NAME'

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
pg_setup /usr/lib/postgresql/16/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb

  # TryPost's own role and database (upstream's postgres service makes them
  # from POSTGRES_USER/POSTGRES_DB). Its migrations create the tables.
  pg_start_local
  pg_psql \
      -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE trypost LOGIN PASSWORD :'pw';
CREATE DATABASE trypost OWNER trypost;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
