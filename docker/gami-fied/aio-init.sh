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

# ---- public address: upstream's BETTER_AUTH_URL and NEXT_PUBLIC_APP_URL,
# ---- one address here. Sign-in only accepts requests from it, so it must
# ---- be the address people open. ----
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6709}
PUBLIC_URL=${PUBLIC_URL%/}
# The compose file ships http://[ZIMAOS-IP-ADDRESS]:6709 so people see they
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
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/backups"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret PG_PASSWORD 16
ensure_secret REDIS_PASSWORD 16
# Signs sessions (upstream: openssl rand -base64 32).
ensure_b64 BETTER_AUTH_SECRET 32
# Encrypts stored credentials and webhook secrets (upstream: openssl rand -hex 32).
ensure_secret ENCRYPTION_MASTER_KEY 32
ensure_secret WEBHOOK_MASTER_KEY 32
# Claims the first platform admin at /admin.
ensure_secret PLATFORM_BOOTSTRAP_SECRET 16

PG_PASSWORD=$(secret PG_PASSWORD)
REDIS_PASSWORD=$(secret REDIS_PASSWORD)

# ---- CREDENTIALS banner, printed on every boot once Gami.Fied answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add "ADMIN SETUP" "$(cred_url "$PUBLIC_URL/admin")"
cred_add "BOOTSTRAP SECRET" "$(secret PLATFORM_BOOTSTRAP_SECRET)"
cred_note "Sign up, then open /admin and enter the bootstrap secret to become the platform admin."

# ---- hostnames from upstream's compose, all pointed at 127.0.0.1 ----
if ! grep -q ' redis api dashboard' "$HOSTS"; then
  echo "127.0.0.1 postgres redis api dashboard worker" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: the api keeps its backups in /app/storage/backups.
  if [ "$name" = api ]; then
    mkdir -p "$d/app/storage/backups"
    mountpoint -q "$d/app/storage/backups" || mount --bind "$DATA/backups" "$d/app/storage/backups" 2>/dev/null \
      || log "warning: could not mount $DATA/backups into the api chroot"
    uid=$(awk -F: '$1=="nodejs" {print $3":"$4; exit}' "$d/etc/passwd")
    [ -n "$uid" ] && chown -R "$uid" "$DATA/backups"
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 3001 5432 6379 "
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
    return 503 "Gami.Fied is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so sign-in would be refused here.\n\nOpen the Gami.Fied app settings in ZimaOS, set PUBLIC_URL to http://$host:6709 and save. After the app restarts, open this page again.\n";
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
rm -f "$RUN/migrated"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"
DB_URL="postgres://gami:$PG_PASSWORD@127.0.0.1:5432/gami_prod"

write_env redis "REDIS_PASSWORD=$REDIS_PASSWORD"
write_env migrate "DATABASE_URL=$DB_URL"

# Upstream's x-api-environment block, for the api and the worker.
APP_ENV=(
  "$TZV"
  "DATABASE_URL=$DB_URL"
  "REDIS_HOST=127.0.0.1"
  "REDIS_PORT=6379"
  "REDIS_PASSWORD=$REDIS_PASSWORD"
  "NODE_ENV=production"
  "BETTER_AUTH_SECRET=$(secret BETTER_AUTH_SECRET)"
  "BETTER_AUTH_URL=$PUBLIC_URL"
  "ENCRYPTION_MASTER_KEY=$(secret ENCRYPTION_MASTER_KEY)"
  "WEBHOOK_MASTER_KEY=$(secret WEBHOOK_MASTER_KEY)"
)
write_env api "${APP_ENV[@]}" \
  "PORT=3001" \
  "HOST=127.0.0.1" \
  "NEXT_PUBLIC_APP_URL=$PUBLIC_URL" \
  "PLATFORM_BOOTSTRAP_SECRET=$(secret PLATFORM_BOOTSTRAP_SECRET)" \
  "TRUST_PROXY=true" \
  "BACKUP_STORAGE_PATH=/app/storage/backups"
write_env worker "${APP_ENV[@]}" "OUTBOX_POLL_INTERVAL_MS=${OUTBOX_POLL_INTERVAL_MS:-1000}"
write_env dashboard "$TZV" "PORT=3000" "HOSTNAME=127.0.0.1" "API_URL=http://127.0.0.1:3001" "NODE_ENV=production"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional setting from the README Variables list, by its own name.
pass_env api    'SMTP_[A-Z_]+|TRUSTED_ORIGINS|RATE_LIMIT_(MAX|IP_MAX)|METRICS_BEARER_TOKEN|LOG_(LEVEL|FORMAT)|DATABASE_POOL_MAX'
pass_env worker 'SMTP_[A-Z_]+|LOG_(LEVEL|FORMAT)|WORKER_CONCURRENCY|DATABASE_POOL_MAX|OUTBOX_STEP_TIMEOUT_MS'

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
pg_setup /usr/lib/postgresql/17/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb
  # Upstream's postgres service: POSTGRES_USER gami, POSTGRES_DB gami_prod.
  pg_start_local
  pg_psql -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE gami LOGIN SUPERUSER PASSWORD :'pw';
CREATE DATABASE gami_prod OWNER gami;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
