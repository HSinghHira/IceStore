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

# ---- public address: upstream's BETTER_AUTH_URL. Sign-in only accepts
# ---- requests from it, so it must be the address people open. ----
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6716}
PUBLIC_URL=${PUBLIC_URL%/}
# The compose file ships http://[ZIMAOS-IP-ADDRESS]:6716 so people see they
# must put their IP there. Until they do, run on localhost (so it starts)
# and show the "set PUBLIC_URL" note to every other address (below).
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
mkdir -p "$STATE/overrides" "$DATA/postgres"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret PG_PASSWORD 16
# Signs sessions (upstream: openssl rand -hex 32).
ensure_secret BETTER_AUTH_SECRET 32
# Encrypts the environment secrets people store with their pastes.
ensure_secret ENV_SECRETS_KEY 32
PG_PASSWORD=$(secret PG_PASSWORD)

# ---- CREDENTIALS banner, printed on every boot once Sniptide answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "Sign up to make your account; set ALLOW_SIGN_UP=false afterwards to close sign-up."

# ---- hostnames from upstream's compose, all pointed at 127.0.0.1 ----
if ! grep -q ' db app proxy' "$HOSTS"; then
  echo "127.0.0.1 db app proxy" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
# The app keeps nothing on disk (everything is in Postgres).
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 5432 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

# Sign-in only works on PUBLIC_URL, so with the default (localhost) anyone on
# another address gets a short note saying what to set instead.
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Sniptide is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so sign-in would be refused here.\n\nOpen the Sniptide app settings in ZimaOS, set PUBLIC_URL to http://$host:6716 and save. After the app restarts, open this page again.\n";
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

write_env postgres "$TZV"

# Upstream's app service. The gateway is the one proxy in front.
write_env sniptide "$TZV" \
  "DATABASE_URL=postgres://sniptide:$PG_PASSWORD@127.0.0.1:5432/sniptide" \
  "HOSTNAME=127.0.0.1" \
  "BETTER_AUTH_SECRET=$(secret BETTER_AUTH_SECRET)" \
  "BETTER_AUTH_URL=$PUBLIC_URL" \
  "ENV_SECRETS_KEY=$(secret ENV_SECRETS_KEY)" \
  "ALLOW_SIGN_UP=${ALLOW_SIGN_UP:-true}" \
  "CLIENT_IP_SOURCE=x-forwarded-for" \
  "TRUSTED_PROXIES=${TRUSTED_PROXIES:-private}"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional Sniptide setting from the README Variables list, by its own name.
pass_env sniptide 'ALLOWED_EMAILS|(GITHUB|GOOGLE)_CLIENT_(ID|SECRET)|BETTER_AUTH_TRUSTED_ORIGINS|SHARE_URL|MAX_PASTE_SIZE|GITHUB_TOKEN|SLACK_WEBHOOK_URL|DISCORD_WEBHOOK_URL|SMTP_[A-Z_]+|ACCOUNT_(STORAGE_BYTES|PASTE_LIMIT)|VIEW_HISTORY_RETENTION_DAYS|ANALYTICS_RETENTION_DAYS|METRICS_TOKEN|NODE_OPTIONS'

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
pg_setup /usr/lib/postgresql/17/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb
  # Upstream's db service: POSTGRES_USER and POSTGRES_DB sniptide.
  pg_start_local
  pg_psql -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE sniptide LOGIN SUPERUSER PASSWORD :'pw';
CREATE DATABASE sniptide OWNER sniptide;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
