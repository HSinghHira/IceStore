#!/bin/bash
# First thing that runs in the container. Makes secrets, hashes the admin
# password, writes each service's environment, then hands over to supervisord.
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

# ---- public address: allowed browser origin (CORS) and the OIDC callback ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6151}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/homelable"
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

# SECRET_KEY signs sign-ins (32 bytes, enough for OIDC mode too); changing it
# signs everyone out. GENERATED_ADMIN_PASSWORD is used while ADMIN_PASSWORD is
# blank.
ensure_secret SECRET_KEY 32
ensure_secret GENERATED_ADMIN_PASSWORD 9

# ---- admin login ----
# Homelable wants a bcrypt hash of the password (AUTH_PASSWORD_HASH). It is
# made here on every start from ADMIN_PASSWORD, so changing ADMIN_PASSWORD in
# the app settings changes the password. Blank = the password made on first
# start, printed below and kept in the data folder. A hash you set yourself in
# AUTH_PASSWORD_HASH wins over both.
ADMIN_LOGIN_FILE=$DATA/admin-password.txt
AUTH_USERNAME_V=${AUTH_USERNAME:-admin}
ADMIN_PASSWORD_V=${ADMIN_PASSWORD:-}
if [ -z "$ADMIN_PASSWORD_V" ]; then
  ADMIN_PASSWORD_V=$(secret GENERATED_ADMIN_PASSWORD)
  if [ -z "${AUTH_PASSWORD_HASH:-}" ]; then
    printf 'Homelable login\nusername: %s\npassword: %s\n' "$AUTH_USERNAME_V" "$ADMIN_PASSWORD_V" > "$ADMIN_LOGIN_FILE"
    chmod 600 "$ADMIN_LOGIN_FILE"
    log "admin login is $AUTH_USERNAME_V / $ADMIN_PASSWORD_V (also saved in $ADMIN_LOGIN_FILE)"
  fi
else
  rm -f "$ADMIN_LOGIN_FILE"
fi
PASSWORD_HASH=${AUTH_PASSWORD_HASH:-}
if [ -z "$PASSWORD_HASH" ]; then
  if command -v htpasswd >/dev/null; then
    # htpasswd writes "$2y$"; bcrypt in Python reads "$2b$". Same algorithm.
    PASSWORD_HASH=$(htpasswd -nbBC 12 "" "$ADMIN_PASSWORD_V" | tr -d ':\r\n' | sed 's/^\$2y\$/$2b$/')
  else
    log "warning: htpasswd not found; the admin password could not be set"
  fi
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'homelable-backend' "$HOSTS"; then
  echo "127.0.0.1 backend homelable-backend" >> "$HOSTS"
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


  # APP-SPECIFIC: /data/homelable is the backend's /app/data (SQLite database
  # and uploaded floor plans, upstream's volume). The image runs as root.
  if [ "$(basename "$d")" = backend ]; then
    mkdir -p "$d/app/data"
    if ! mountpoint -q "$d/app/data"; then
      mount --bind "$DATA/homelable" "$d/app/data" 2>/dev/null \
        || log "WARNING: could not bind $DATA/homelable to $d/app/data; your diagrams would be lost on update"
    fi
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
INTERNAL_PORTS=" 8000 "
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

# The browser talks to the API through the gateway (same address), so CORS
# only needs PUBLIC_URL; the localhost entry keeps the default address working.
CORS_DEFAULT="[\"$PUBLIC_URL\",\"http://localhost:6151\"]"

# From upstream's docker-compose.yml and .env.example, with the database in
# /data/homelable and the secret and password hash made above.
write_env backend "$TZV" \
  "SQLITE_PATH=/app/data/homelab.db" \
  "SECRET_KEY=$(secret SECRET_KEY)" \
  "AUTH_USERNAME=$AUTH_USERNAME_V" \
  "AUTH_PASSWORD_HASH=$PASSWORD_HASH" \
  "CORS_ORIGINS=${CORS_ORIGINS:-$CORS_DEFAULT}" \
  "AUTH_MODE=${AUTH_MODE:-local}" \
  "OIDC_REDIRECT_URI=${OIDC_REDIRECT_URI:-$PUBLIC_URL/api/v1/auth/oidc/callback}"

# ---- settings: the README variables: list (Apps/homelable/) ----
# Homelable reads these itself on every start; blank ones are skipped, so
# they mean "default".
pass_env backend 'OIDC_(DISCOVERY_URL|CLIENT_ID|CLIENT_SECRET|SCOPES|COOKIE_SECURE|SESSION_EXPIRE_MINUTES|TRANSACTION_EXPIRE_SECONDS)'
pass_env backend 'ACCESS_TOKEN_EXPIRE_MINUTES|SCANNER_[A-Z_]+|STATUS_CHECKER_[A-Z_]+'
pass_env backend 'LIVEVIEW_KEY|DOCS_VIEW_KEY|HOMEPAGE_API_KEY'
pass_env backend 'PROXMOX_[A-Z_]+|UNRAID_[A-Z_]+|ZIGBEE_[A-Z_]+|ZWAVE_[A-Z_]+|MQTT_RESPONSE_TIMEOUT'

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
