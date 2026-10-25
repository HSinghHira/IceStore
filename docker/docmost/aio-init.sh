#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each
# service's environment, prepares the database, then hands over to
# supervisord.
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

# ---- public address: Docmost's APP_URL (links in emails, sharing) ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6147}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. Links in emails only work on this server;"
    log "set PUBLIC_URL to the address you open Docmost at, like http://192.168.1.20:6147" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/storage"
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

# PG_PASSWORD: postgres superuser. DOCMOST_DB_PASSWORD: the "docmost" role.
# APP_SECRET signs sign-ins; changing it signs everyone out. MAIL_PASSWORD is
# the /mail viewer login.
ensure_secret PG_PASSWORD 16
ensure_secret DOCMOST_DB_PASSWORD 16
ensure_secret APP_SECRET 32
ensure_secret MAIL_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
DOCMOST_DB_PASSWORD=$(secret DOCMOST_DB_PASSWORD)
MAIL_PASSWORD=$(secret MAIL_PASSWORD)

# Mail viewer (/mail) login. It shows invite and password-reset emails, so it
# is never open: blank MP_UI_AUTH = user "admin" with a password made on first
# start, kept in the data folder. A value you set wins.
MAIL_LOGIN_FILE=$DATA/mail-password.txt
MAIL_UI_AUTH=${MP_UI_AUTH:-}
if [ -z "$MAIL_UI_AUTH" ]; then
  MAIL_UI_AUTH="admin:$MAIL_PASSWORD"
  if [ ! -s "$MAIL_LOGIN_FILE" ]; then
    printf 'Mail viewer (/mail) login\nusername: admin\npassword: %s\n' "$MAIL_PASSWORD" > "$MAIL_LOGIN_FILE"
    chmod 600 "$MAIL_LOGIN_FILE"
  fi
  log "mail viewer (/mail) login is admin / $MAIL_PASSWORD (also saved in $MAIL_LOGIN_FILE)"
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'docmost-mailpit' "$HOSTS"; then
  echo "127.0.0.1 db redis docmost docmost-mailpit" >> "$HOSTS"
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

  # APP-SPECIFIC: /data/storage is Docmost's /app/data/storage (uploads and
  # attachments, upstream's volume), owned by the image's "node" user.
  if [ "$(basename "$d")" = docmost ]; then
    mkdir -p "$d/app/data/storage"
    if ! mountpoint -q "$d/app/data/storage"; then
      mount --bind "$DATA/storage" "$d/app/data/storage" 2>/dev/null \
        || log "WARNING: could not bind $DATA/storage to $d/app/data/storage; uploads would be lost on update"
    fi
    uid=$(awk -F: '$1=="node"{print $3":"$4}' "$d/etc/passwd" 2>/dev/null || true)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/storage" 2>/dev/null || true
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
INTERNAL_PORTS=" 1025 3000 5432 6379 8025 "
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

# Email: with the smtp driver and no SMTP_HOST, emails go to the built-in
# mail viewer at /mail (nothing leaves the box). With a real server the port
# defaults to 587. MAIL_DRIVER=postmark uses POSTMARK_TOKEN instead.
MAIL_DRIVER_V=${MAIL_DRIVER:-smtp}
SMTP_HOST_V=${SMTP_HOST:-}
MAILVIEWER=0
if [ "$MAIL_DRIVER_V" = smtp ] && [ -z "$SMTP_HOST_V" ]; then
  log "no SMTP_HOST set: emails go to the mail viewer at $PUBLIC_URL/mail/"
  MAILVIEWER=1
  SMTP=("SMTP_HOST=127.0.0.1" "SMTP_PORT=1025" "SMTP_SECURE=false" "SMTP_IGNORETLS=true")
else
  SMTP=("SMTP_HOST=$SMTP_HOST_V" "SMTP_PORT=${SMTP_PORT:-587}")
fi

# From upstream's docker-compose.yml and .env.example, with Postgres and
# Redis on 127.0.0.1, files in /data/storage and the secret made above.
write_env docmost "$TZV" \
  "NODE_ENV=production" \
  "HOME=/home/node" \
  "PORT=3000" \
  "APP_URL=$PUBLIC_URL" \
  "APP_SECRET=$(secret APP_SECRET)" \
  "DATABASE_URL=postgresql://docmost:$DOCMOST_DB_PASSWORD@127.0.0.1:5432/docmost?schema=public" \
  "REDIS_URL=redis://127.0.0.1:6379" \
  "STORAGE_DRIVER=${STORAGE_DRIVER:-local}" \
  "MAIL_DRIVER=$MAIL_DRIVER_V" \
  "${SMTP[@]}" \
  "MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS:-noreply@docmost.local}" \
  "MAIL_FROM_NAME=${MAIL_FROM_NAME:-Docmost}"

# ---- settings: the README variables: list (Apps/docmost/) ----
# Docmost reads these itself on every start; blank ones are skipped, so they
# mean "default". With the mail viewer, the SMTP login and TLS settings are
# skipped: it needs none of them.
if [ "$MAILVIEWER" = 0 ]; then
  pass_env docmost 'SMTP_(USERNAME|PASSWORD|SECURE|IGNORETLS)|POSTMARK_TOKEN'
fi
pass_env docmost 'AWS_S3_[A-Z_]+|AZURE_STORAGE_[A-Z_]+|FILE_(UPLOAD|IMPORT)_SIZE_LIMIT'
pass_env docmost 'JWT_TOKEN_EXPIRES_IN|DRAWIO_URL|GOTENBERG_URL|DISABLE_TELEMETRY'
pass_env docmost 'IFRAME_EMBED_ALLOWED|IFRAME_ALLOWED_ORIGINS|ALLOWED_PRIVATE_NETWORKS'
pass_env docmost 'DEBUG_MODE|DEBUG_DB|LOG_HTTP'

write_env mailpit "$TZV" \
  "MP_SMTP_AUTH_ACCEPT_ANY=1" \
  "MP_SMTP_AUTH_ALLOW_INSECURE=1" \
  "MP_SMTP_BIND_ADDR=127.0.0.1:1025" \
  "MP_UI_BIND_ADDR=127.0.0.1:8025" \
  "MP_WEBROOT=/mail/" \
  "MP_UI_AUTH=$MAIL_UI_AUTH"
pass_env mailpit 'MP_MAX_MESSAGES'

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
id postgres >/dev/null
mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql "$DATA/postgres"
chmod 700 "$DATA/postgres"
chown redis:redis "$DATA/redis"

pgbin=/usr/lib/postgresql/18/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  # Upstream's "docmost" user is the Postgres superuser (POSTGRES_USER=docmost),
  # so it stays one here: its migrations create the unaccent and pg_trgm
  # extensions.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE docmost LOGIN SUPERUSER PASSWORD '${DOCMOST_DB_PASSWORD}';" \
    -c "CREATE DATABASE docmost OWNER docmost;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
