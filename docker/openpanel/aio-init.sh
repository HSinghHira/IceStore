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

# ---- public address: OpenPanel's DASHBOARD_URL, with API_URL at /api. The
# ---- dashboard hands API_URL to the browser, and the tracking script on your
# ---- websites sends events to it, so it must be the address people open. ----
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6191}
PUBLIC_URL=${PUBLIC_URL%/}
# The compose file ships http://[ZIMAOS-IP-ADDRESS]:6191 so people see they
# must put their IP there. Until they do, run on localhost (so OpenPanel
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

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/clickhouse"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"
chown redis:redis "$DATA/redis" 2>/dev/null || true

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret PG_PASSWORD 16
# Signs the sign-in cookies; changing it signs everyone out.
ensure_b64 COOKIE_SECRET 32
# Encrypts integration tokens (Google Search Console and others).
ensure_secret ENCRYPTION_KEY 32

PG_PASSWORD=$(secret PG_PASSWORD)
COOKIE_SECRET=$(secret COOKIE_SECRET)
ENCRYPTION_KEY=$(secret ENCRYPTION_KEY)

# ---- CREDENTIALS banner, printed on every boot once OpenPanel answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "Open the URL and create your account: the first person to sign up becomes the owner."
cred_note "Sign-up closes after that; invite others from your organization's Members page."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' op-ch' "$HOSTS"; then
  echo "127.0.0.1 op-db op-kv op-ch op-api op-dashboard op-worker" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: ClickHouse keeps every event in /var/lib/clickhouse; its
  # own entrypoint gives the folder to the clickhouse user.
  if [ "$name" = clickhouse ]; then
    mkdir -p "$d/var/lib/clickhouse"
    mountpoint -q "$d/var/lib/clickhouse" || mount --bind "$DATA/clickhouse" "$d/var/lib/clickhouse" 2>/dev/null \
      || log "warning: could not mount $DATA/clickhouse into the clickhouse chroot"
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 3001 3002 5432 6379 8123 9000 9009 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

# The browser is told to call PUBLIC_URL/api, so with the default
# (localhost) anyone on another address gets a short note saying what to
# set instead. Requests to localhost/127.0.0.1 (the box itself, the
# healthcheck) still go through.
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "OpenPanel is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so the dashboard would call localhost and never load.\n\nOpen the OpenPanel app settings in ZimaOS, set PUBLIC_URL to http://$host:6191 and save. After the app restarts, open this page again.\n";
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

# Upstream's .env.template, shared by the API, the worker and the dashboard.
DB_URL="postgres://openpanel:$PG_PASSWORD@127.0.0.1:5432/openpanel?schema=public"
OP_ENV=(
  "$TZV"
  "NODE_ENV=production"
  "SELF_HOSTED=true"
  "BATCH_SIZE=5000"
  "BATCH_INTERVAL=10000"
  "ALLOW_REGISTRATION=${ALLOW_REGISTRATION:-false}"
  "ALLOW_INVITATION=${ALLOW_INVITATION:-true}"
  "REDIS_URL=redis://127.0.0.1:6379"
  "CLICKHOUSE_URL=http://127.0.0.1:8123/openpanel"
  "DATABASE_URL=$DB_URL"
  "DATABASE_URL_DIRECT=$DB_URL"
  "DASHBOARD_URL=$PUBLIC_URL"
  "API_URL=$PUBLIC_URL/api"
  "API_URL_SSR=http://127.0.0.1:3001"
  "COOKIE_SECRET=$COOKIE_SECRET"
  "ENCRYPTION_KEY=$ENCRYPTION_KEY"
  "EMAIL_SENDER=${EMAIL_SENDER:-hello@openpanel.dev}"
  "GOOGLE_REDIRECT_URI=$PUBLIC_URL/api/oauth/google/callback"
  "GITHUB_REDIRECT_URI=$PUBLIC_URL/api/oauth/github/callback"
  "GSC_GOOGLE_REDIRECT_URI=$PUBLIC_URL/api/gsc/callback"
)

write_env api "${OP_ENV[@]}" "API_PORT=3001"
write_env worker "${OP_ENV[@]}" "WORKER_PORT=3002"
write_env dashboard "${OP_ENV[@]}" "PORT=3000" "HOST=127.0.0.1"
write_env clickhouse "$TZV" "CLICKHOUSE_SKIP_USER_SETUP=1"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional OpenPanel setting from the README Variables list, by its own
# name: email, sign-in with Google/GitHub, AI, outbound calls, cookies.
pass_env api 'RESEND_API_KEY|SMTP_(HOST|PORT|SECURE|USER|PASS)|(GOOGLE|GITHUB)_(CLIENT_ID|CLIENT_SECRET|REDIRECT_URI)|GSC_GOOGLE_REDIRECT_URI|(OPENAI|ANTHROPIC)_API_KEY|OPENAI_BASE_URL|ANTHROPIC_BASE_URL|DISABLE_PING|DISABLE_FAVICON_FETCH|API_CORS_ORIGINS|COOKIE_TLDS|CUSTOM_COOKIE_DOMAIN|SLACK_(CLIENT_ID|CLIENT_SECRET|STATE_SECRET|OAUTH_REDIRECT_URL)'
pass_env worker 'RESEND_API_KEY|SMTP_(HOST|PORT|SECURE|USER|PASS)|(GOOGLE|GITHUB)_(CLIENT_ID|CLIENT_SECRET|REDIRECT_URI)|GSC_GOOGLE_REDIRECT_URI|(OPENAI|ANTHROPIC)_API_KEY|OPENAI_BASE_URL|ANTHROPIC_BASE_URL|DISABLE_PING|DISABLE_FAVICON_FETCH|API_CORS_ORIGINS|COOKIE_TLDS|CUSTOM_COOKIE_DOMAIN|SLACK_(CLIENT_ID|CLIENT_SECRET|STATE_SECRET|OAUTH_REDIRECT_URL)'
pass_env dashboard 'RESEND_API_KEY|SMTP_(HOST|PORT|SECURE|USER|PASS)|(GOOGLE|GITHUB)_(CLIENT_ID|CLIENT_SECRET|REDIRECT_URI)|GSC_GOOGLE_REDIRECT_URI|(OPENAI|ANTHROPIC)_API_KEY|OPENAI_BASE_URL|ANTHROPIC_BASE_URL|DISABLE_PING|DISABLE_FAVICON_FETCH|API_CORS_ORIGINS|COOKIE_TLDS|CUSTOM_COOKIE_DOMAIN|SLACK_(CLIENT_ID|CLIENT_SECRET|STATE_SECRET|OAUTH_REDIRECT_URL)'

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
pg_setup /usr/lib/postgresql/14/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb

  # OpenPanel's own role and database. Its migrations create the tables.
  pg_start_local
  pg_psql \
      -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE openpanel LOGIN PASSWORD :'pw';
CREATE DATABASE openpanel OWNER openpanel;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
