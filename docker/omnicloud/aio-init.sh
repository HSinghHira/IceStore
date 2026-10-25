#!/bin/bash
# First thing that runs in the container. Makes secrets, writes the API's
# environment, then hands over to supervisord.
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

# ---- public address: CORS, sign-in cookies and the cloud sign-in callbacks ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6154}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. Cloud sign-in callbacks only work on this server;"
    log "set PUBLIC_URL to the address you open OmniCloud at, like http://192.168.1.20:6154" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/omnicloud"
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

# OMNICLOUD_SECRET_HALF encrypts the saved cloud logins: never change it, or
# every account must be connected again. AUTH_SECRET signs sign-ins (hosted
# mode); changing it signs everyone out.
ensure_secret OMNICLOUD_SECRET_HALF 32
ensure_secret AUTH_SECRET 32

# OmniCloud mixes the machine's host name into the encryption key, and a
# container gets a new host name every time it is recreated (each update).
# A fixed host name keeps the saved cloud logins readable.
if [ "${AIO_DRY_RUN:-}" != 1 ] && [ "$(hostname)" != omnicloud ]; then
  hostname omnicloud 2>/dev/null || log "WARNING: could not set the host name; saved cloud logins may stop working after an update"
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'omnicloud-api' "$HOSTS"; then
  echo "127.0.0.1 api omnicloud-api omnicloud" >> "$HOSTS"
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


  # APP-SPECIFIC: /data/omnicloud is the API's /app/data (the SQLite database
  # with your accounts and file list, upstream's volume), owned by the Node
  # image's "node" user.
  if [ "$(basename "$d")" = api ]; then
    mkdir -p "$d/app/data"
    if ! mountpoint -q "$d/app/data"; then
      mount --bind "$DATA/omnicloud" "$d/app/data" 2>/dev/null \
        || log "WARNING: could not bind $DATA/omnicloud to $d/app/data; your accounts would be lost on update"
    fi
    uid=$(awk -F: '$1=="node"{print $3":"$4}' "$d/etc/passwd" 2>/dev/null || true)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/omnicloud" 2>/dev/null || true
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
INTERNAL_PORTS=" 8787 "
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

# From upstream's docker-compose.yml and backend/.env.example. The browser
# reaches the API through the gateway, so CORS and every sign-in callback use
# PUBLIC_URL.
CB=$PUBLIC_URL/api/accounts
write_env api "$TZV" \
  "PORT=8787" \
  "DATABASE_PATH=/app/data/omnicloud.db" \
  "APP_MODE=${APP_MODE:-local}" \
  "CORS_ORIGIN=$PUBLIC_URL" \
  "FRONTEND_URL=$PUBLIC_URL" \
  "OMNICLOUD_SECRET_HALF=$(secret OMNICLOUD_SECRET_HALF)" \
  "AUTH_SECRET=$(secret AUTH_SECRET)" \
  "GOOGLE_REDIRECT_URI=${GOOGLE_REDIRECT_URI:-$CB/google/callback}" \
  "ONEDRIVE_REDIRECT_URI=${ONEDRIVE_REDIRECT_URI:-$CB/onedrive/callback}" \
  "DROPBOX_REDIRECT_URI=${DROPBOX_REDIRECT_URI:-$CB/dropbox/callback}" \
  "YANDEX_REDIRECT_URI=${YANDEX_REDIRECT_URI:-$CB/yandex/callback}"

# ---- settings: the README variables: list (Apps/omnicloud/) ----
# OmniCloud reads these itself on every start; blank ones are skipped, so
# they mean "default".
pass_env api '(GOOGLE|ONEDRIVE|DROPBOX|YANDEX)_CLIENT_(ID|SECRET)|ONEDRIVE_TENANT_ID'
pass_env api 'SYNC_INTERVAL_MINUTES|AUTH_SESSION_TTL_HOURS|AUTH_COOKIE_NAME'

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
