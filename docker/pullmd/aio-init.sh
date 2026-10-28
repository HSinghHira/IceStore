#!/bin/bash
# First thing that runs in the container. Makes the admin password, writes
# each service's environment, then hands over to supervisord.
set -euo pipefail

DATA=${AIO_DATA:-/data}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}
HOSTS=${AIO_HOSTS:-/etc/hosts}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/aio.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/aio.conf}
GATEWAY_PORT=8080

log() { echo "[init] $*"; }

# ---- public address ----
# PullMD follows the browser's address when PUBLIC_URL is not set. It only
# uses PUBLIC_URL for the links on the help page, the downloadable skill and
# OAuth. So on localhost it is left out, and every device sees its own address.
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6132}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
APP_PUBLIC_URL=$PUBLIC_URL
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*) APP_PUBLIC_URL="" ;;
esac

# ---- sign-in ----
# Upstream's default is no sign-in (disabled). single-admin and multi-user
# need a first admin; a blank password means "make one and print it".
AUTH_MODE=${PULLMD_AUTH_MODE:-disabled}
case $AUTH_MODE in
  disabled|single-admin|multi-user) ;;
  *) log "PULLMD_AUTH_MODE must be disabled, single-admin or multi-user (got: $AUTH_MODE)"; exit 1 ;;
esac
ADMIN_EMAIL=${PULLMD_ADMIN_EMAIL:-admin@example.com}

# ---- one folder per stateful service under /data ----
#   pullmd/  the SQLite cache, accounts, API keys, share links (/data in its rootfs)
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/pullmd"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -hex "$2")" >> "$SECRETS"
  fi
  return 0
}
secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# ADMIN_PASSWORD: the first admin's password when PULLMD_ADMIN_PASSWORD is
# blank. PullMD only reads it while there is no admin yet.
ensure_secret ADMIN_PASSWORD 9
ADMIN_PASSWORD=${PULLMD_ADMIN_PASSWORD:-$(secret ADMIN_PASSWORD)}
if [ "$AUTH_MODE" != disabled ]; then
  if [ -n "${PULLMD_ADMIN_PASSWORD:-}" ]; then
    log "sign-in is on ($AUTH_MODE): admin email is $ADMIN_EMAIL, password is the PULLMD_ADMIN_PASSWORD you set"
  else
    log "sign-in is on ($AUTH_MODE): admin email is $ADMIN_EMAIL"
    log "admin password is $ADMIN_PASSWORD (also saved in $SECRETS)"
  fi
  log "these only make the first admin; change the password later in PullMD's settings"
else
  log "sign-in is off (PULLMD_AUTH_MODE=disabled): anyone who can reach port 6132 can use PullMD"
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'trafilatura' "$HOSTS"; then
  echo "127.0.0.1 pullmd trafilatura markitdown" >> "$HOSTS"
fi

# ---- generic: prepare every chroot filesystem under /opt/rootfs ----
for d in "$ROOTFS"/*/; do
  [ -d "$d" ] || continue
  mkdir -p "$d/dev" "$d/etc" "$d/tmp" "$d/proc" "$d/sys"
  chmod 1777 "$d/tmp"
  cat "$HOSTS" > "$d/etc/hosts"
  [ -f /etc/resolv.conf ] && cat /etc/resolv.conf > "$d/etc/resolv.conf"

  if ! mountpoint -q "$d/proc"; then
    mount -t proc proc "$d/proc" 2>/dev/null || mount --rbind /proc "$d/proc" 2>/dev/null || {
      err=$(mount --rbind /proc "$d/proc" 2>&1 || true)
      log "warning: could not mount proc into $d/proc: $err"
    }
  fi
  mountpoint -q "$d/sys" || mount --rbind /sys "$d/sys" 2>/dev/null || true
  mkdir -p "$d/dev/shm"
  mountpoint -q "$d/dev/shm" || mount -t tmpfs tmpfs "$d/dev/shm" 2>/dev/null || true
  chmod 1777 "$d/dev/shm" 2>/dev/null || true
  [ -e "$d/dev/fd" ] || ln -s /proc/self/fd "$d/dev/fd" 2>/dev/null || true
  if [ -f "$d/proc/version" ]; then
    log "$d procfs mounted successfully"
  else
    log "WARNING: $d procfs is NOT mounted"
  fi

  # APP-SPECIFIC: PullMD keeps its SQLite cache (and site-recipes.json, if you
  # add one) in /data. Its entrypoint gives the folder to its "app" user.
  if [ "$(basename "$d")" = pullmd ]; then
    mkdir -p "$d/data"
    mountpoint -q "$d/data" || mount --bind "$DATA/pullmd" "$d/data" \
      || log "warning: could not bind $DATA/pullmd into $d/data"
  fi

  [ -e "$d/dev/null" ]    || mknod -m 666 "$d/dev/null" c 1 3    2>/dev/null || log "warning: could not create $d/dev/null"
  [ -e "$d/dev/zero" ]    || mknod -m 666 "$d/dev/zero" c 1 5    2>/dev/null || true
  [ -e "$d/dev/random" ]  || mknod -m 666 "$d/dev/random" c 1 8  2>/dev/null || true
  [ -e "$d/dev/urandom" ] || mknod -m 666 "$d/dev/urandom" c 1 9 2>/dev/null || true
  [ -e "$d/dev/stdin" ] || : > "$d/dev/stdin"
  for f in stdout stderr; do
    [ -p "$d/dev/$f" ] && continue
    rm -f "$d/dev/$f"
    mkfifo -m 666 "$d/dev/$f" 2>/dev/null || : > "$d/dev/$f"
  done
done

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 8001 8003 8080 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# From upstream's docker-compose.yml, with the sidecars on 127.0.0.1 and no
# Playwright. The gateway on 127.0.0.1 is the only proxy, so PullMD trusts
# its X-Forwarded-For (loopback) and rate limits see the real client address.
# MARKITDOWN_YOUTUBE is on here (upstream: off), since the sidecar is inside.
write_env pullmd "$TZV" \
  "PORT=3000" \
  "CACHE_DB=/data/cache.db" \
  "TRAFILATURA_URL=http://127.0.0.1:8001/extract" \
  "MARKITDOWN_URL=http://127.0.0.1:8003/convert" \
  "MARKITDOWN_YOUTUBE=${MARKITDOWN_YOUTUBE:-true}" \
  "PULLMD_TRUST_PROXY=${PULLMD_TRUST_PROXY:-loopback}" \
  "PULLMD_AUTH_MODE=$AUTH_MODE"
if [ -n "$APP_PUBLIC_URL" ]; then
  echo "PUBLIC_URL=$APP_PUBLIC_URL" >> "$RUN/pullmd.env"
fi
if [ "$AUTH_MODE" != disabled ]; then
  printf '%s\n' "PULLMD_ADMIN_EMAIL=$ADMIN_EMAIL" "PULLMD_ADMIN_PASSWORD=$ADMIN_PASSWORD" >> "$RUN/pullmd.env"
fi

write_env trafilatura "$TZV"
write_env markitdown "$TZV"

# ---- settings: the README variables: list (Apps/pullmd/) ----
# Each service reads these itself on every start; blank ones are skipped, so
# they mean "default".
pass_env pullmd 'PULLMD_ALLOW_SIGNUP|DISABLE_PUBLIC_HISTORY|OAUTH_JWT_SECRET|PULLMD_AUTH_TOKEN'
pass_env pullmd 'PULLMD_CACHE_RETENTION_DAYS|PULLMD_ALLOWED_HOSTS|PULLMD_LLM_RATE_LIMIT|PULLMD_MAX_FETCH_BYTES'
pass_env pullmd 'PULLMD_(VISION|STT|PDF_OCR)_(API_KEY|BASE_URL|MODEL)|PULLMD_LLM_(API_KEY|BASE_URL)'
pass_env pullmd 'PULLMD_EMBEDDED_IMAGES|PULLMD_EMBEDDED_IMAGES_MAX'
pass_env pullmd 'REDDIT_CLIENT_ID|REDDIT_CLIENT_SECRET|REDDIT_USER_AGENT|PULLMD_USER_AGENT|PULLMD_UA_FEED_URL'
pass_env pullmd 'PULLMD_SITE_RECIPES|PULLMD_SOURCE_HEADER|PULLMD_FRONTMATTER_FIELDS|PULLMD_COVERAGE_GUARD|PULLMD_FILENAME_DATE_PREFIX'
pass_env markitdown 'MARKITDOWN_YT_(TIMECODES|CHUNK|LANGS|PROXY)|MARKITDOWN_CONVERT_TIMEOUT|MARKITDOWN_MEM_LIMIT_MB'

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

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
