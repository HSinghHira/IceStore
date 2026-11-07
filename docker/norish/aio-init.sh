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

# ---- public address (AUTH_URL upstream) ----
# Norish's sign-in only accepts forms from AUTH_URL (and TRUSTED_ORIGINS), so
# it must be the address people open. The compose file ships
# http://[ZIMAOS-IP-ADDRESS]:6134 so people see they must put their IP there.
# Until they do, run on localhost (so everything starts) and show the
# "set PUBLIC_URL" note to every other address (below).
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6134}
PUBLIC_URL=${PUBLIC_URL%/}
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
log "Norish address (AUTH_URL): $PUBLIC_URL"

# ---- one folder per stateful service under /data ----
#   postgres/  the database (recipes, households, settings, encrypted keys)
#   redis/     queues and real-time events
#   uploads/   recipe photos, avatars, videos (/app/uploads in the norish rootfs)
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/uploads"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# PG_PASSWORD: postgres superuser. NORISH_DB_PASSWORD: the "norish" role.
# MASTER_KEY (32 bytes, base64) encrypts stored keys and emails; changing it
# makes them unreadable, so it is made once and kept with the data.
# OBSCURA_CDP_TOKEN: shared by Norish and Obscura (at least 32 bytes).
ensure_secret PG_PASSWORD 16
ensure_secret NORISH_DB_PASSWORD 16
ensure_b64 MASTER_KEY 32
ensure_secret OBSCURA_CDP_TOKEN 32
PG_PASSWORD=$(secret PG_PASSWORD)
NORISH_DB_PASSWORD=$(secret NORISH_DB_PASSWORD)
MASTER_KEY=$(secret MASTER_KEY)
OBSCURA_CDP_TOKEN=$(secret OBSCURA_CDP_TOKEN)

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'obscura' "$HOSTS"; then
  echo "127.0.0.1 db redis obscura norish" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: Norish keeps uploads in /app/uploads. Its entrypoint (run
  # as root) gives the folder to its own user, then drops to that user.
  if [ "$(basename "$d")" = norish ]; then
    mkdir -p "$d/app/uploads"
    mountpoint -q "$d/app/uploads" || mount --bind "$DATA/uploads" "$d/app/uploads" \
      || log "warning: could not bind $DATA/uploads into $d/app/uploads"
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 5432 6379 8080 9222 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

# While PUBLIC_URL says localhost, sign-in from any other device fails. Then
# anyone opening Norish from another address gets a short note saying what to
# set instead. Requests to localhost/127.0.0.1 (the box itself and the
# healthcheck) still go through.
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    log "PUBLIC_URL uses localhost, so sign-in only works on this server; set it to http://[ZIMAOS-IP-ADDRESS]:6134 with your IP"
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Norish is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so sign-in would not work from here.\n\nOpen the Norish app settings in ZimaOS, set PUBLIC_URL to http://$host:6134 and save. After the app restarts, open http://$host:6134 again.\n";
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
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# From upstream's docker-compose.example.yml, with every service on 127.0.0.1.
write_env norish "$TZV" \
  "HOST=127.0.0.1" \
  "PORT=3000" \
  "AUTH_URL=$PUBLIC_URL" \
  "DATABASE_URL=postgres://norish:${NORISH_DB_PASSWORD}@127.0.0.1:5432/norish" \
  "REDIS_URL=redis://127.0.0.1:6379" \
  "MASTER_KEY=$MASTER_KEY" \
  "OBSCURA_ENDPOINT=ws://127.0.0.1:9222" \
  "OBSCURA_CDP_TOKEN=$OBSCURA_CDP_TOKEN" \
  "UPLOADS_DIR=/app/uploads"

write_env obscura "$TZV" \
  "OBSCURA_CDP_TOKEN=$OBSCURA_CDP_TOKEN"

# ---- settings: the README variables: list (Apps/norish/) ----
# Norish reads these itself; blank ones are skipped, so they mean "default".
# Sign-in providers, AI, video and transcription are copied into the database
# on the first start only; after that they are changed in Settings -> Admin.
pass_env norish 'TRUSTED_ORIGINS|NEXT_PUBLIC_LOG_LEVEL|DEFAULT_LOCALE|ENABLED_LOCALES'
pass_env norish 'OIDC_(NAME|ISSUER|CLIENT_ID|CLIENT_SECRET|WELLKNOWN|CLAIM_MAPPING_ENABLED|SCOPES|GROUPS_CLAIM|ADMIN_GROUP|HOUSEHOLD_GROUP_PREFIX)'
pass_env norish 'GITHUB_CLIENT_ID|GITHUB_CLIENT_SECRET|GOOGLE_CLIENT_ID|GOOGLE_CLIENT_SECRET'
pass_env norish 'AI_(ENABLED|PROVIDER|ENDPOINT|MODEL|API_KEY|TEMPERATURE|MAX_TOKENS|TIMEOUT_MS)'
pass_env norish 'TRANSCRIPTION_(PROVIDER|ENDPOINT|API_KEY|MODEL)'
pass_env norish 'VIDEO_PARSING_ENABLED|VIDEO_MAX_LENGTH_SECONDS|YT_DLP_PROXY'
pass_env norish 'PARSER_API_TIMEOUT_MS|OBSCURA_NAVIGATION_TIMEOUT_MS|INGREDIENT_CATALOGUE_URL|INGREDIENT_REVIEW_CONCURRENCY'
pass_env norish 'MAX_(AVATAR|IMAGE|VIDEO)_FILE_SIZE|SCHEDULER_CLEANUP_MONTHS'

# Files in /data/state/overrides/<service>.env are appended last, so users can
# change any service setting without rebuilding the image.
for f in "$STATE"/overrides/*.env; do
  [ -f "$f" ] || continue
  svc=$(basename "$f" .env)
  log "applying your overrides to $svc"
  cat "$f" >> "$RUN/$svc.env"
done

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "Make an account on first visit; the first account becomes the admin."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

# ---- built-in data folders and first-start database ----
pg_setup /usr/lib/postgresql/17/bin
chown redis:redis "$DATA/redis"

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums

  pg_start_local
  pg_psql \
    -c "CREATE ROLE norish LOGIN PASSWORD '${NORISH_DB_PASSWORD}';" \
    -c "CREATE DATABASE norish OWNER norish;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
