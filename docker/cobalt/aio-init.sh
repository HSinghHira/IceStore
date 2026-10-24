#!/bin/bash
# First thing that runs in the container. Makes secrets, writes the api's
# environment and the gateway config, then hands over to supervisord.
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

# ---- public address: default MUST use the app's ledger port ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6144}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac

# ---- APP-SPECIFIC: one folder per stateful service under /data ----
# /data/config is where people drop cookies.json and keys.json; the api sees it as /config.
STATE=$DATA/state
CONFIG=$DATA/config
mkdir -p "$STATE/overrides" "$CONFIG"
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

# APP-SPECIFIC: JWT_SECRET signs session tokens. cobalt only uses it once
# Turnstile bot protection is set up, but having it ready means people only
# need to add the two Turnstile keys.
ensure_secret JWT_SECRET 32
JWT_SECRET_GEN=$(secret JWT_SECRET)

# ---- APP-SPECIFIC: hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'cobalt-api' "$HOSTS"; then
  echo "127.0.0.1 cobalt-api" >> "$HOSTS"
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

  # APP-SPECIFIC: /data/config → /config in the api, owned by its "node" user
  # (cobalt writes refreshed cookies back to cookies.json).
  if [ "$(basename "$d")" = api ]; then
    mkdir -p "$d/config"
    mountpoint -q "$d/config" || mount --bind "$CONFIG" "$d/config"
    uid=$(awk -F: '$1=="node"{print $3":"$4}' "$d/etc/passwd")
    [ -n "$uid" ] && chown -R "$uid" "$CONFIG"
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
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
# APP-SPECIFIC: every port any service listens on inside the container
INTERNAL_PORTS=" 9000 "
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
TZV="TZ=${TZ:-UTC}"

# APP-SPECIFIC: the api. API_URL is what download (tunnel) links are built
# from, so it is the address people open in the browser; the gateway sends
# /tunnel on that address to the api.
write_env api "$TZV" \
  "API_URL=$PUBLIC_URL/" \
  "API_PORT=9000" \
  "API_LISTEN_ADDRESS=127.0.0.1" \
  "JWT_SECRET=${JWT_SECRET:-$JWT_SECRET_GEN}"

# Files dropped in /data/config are picked up on the next start.
if [ -f "$CONFIG/cookies.json" ]; then
  echo "COOKIE_PATH=/config/cookies.json" >> "$RUN/api.env"
  log "using cookies from $CONFIG/cookies.json"
fi
if [ -n "${API_KEY_URL:-}" ]; then
  echo "API_KEY_URL=$API_KEY_URL" >> "$RUN/api.env"
elif [ -f "$CONFIG/keys.json" ]; then
  echo "API_KEY_URL=file:///config/keys.json" >> "$RUN/api.env"
  log "using API keys from $CONFIG/keys.json"
fi

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# APP-SPECIFIC: every README setting the api reads by its own name.
pass_env api 'DISABLED_SERVICES|FORCE_LOCAL_PROCESSING|PROCESSING_PRIORITY|DURATION_LIMIT|TUNNEL_LIFESPAN|(SESSION_|TUNNEL_)?RATELIMIT_(WINDOW|MAX)|HTTPS?_PROXY|NO_PROXY|CORS_WILDCARD|CORS_URL|TURNSTILE_SITEKEY|TURNSTILE_SECRET|JWT_EXPIRY|API_AUTH_REQUIRED|CUSTOM_INNERTUBE_CLIENT|YOUTUBE_SESSION_SERVER|YOUTUBE_SESSION_INNERTUBE_CLIENT|YOUTUBE_PLAYER_ID|YOUTUBE_ALLOW_BETTER_AUDIO|ENABLE_DEPRECATED_YOUTUBE_HLS'

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
