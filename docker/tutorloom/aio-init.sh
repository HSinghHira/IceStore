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
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }

# ---- public address: TutorLoom's FRONTEND_URL (links in invite and
# ---- password-reset emails). The web app itself follows the browser's
# ---- address: it calls the API at /api on the same address.
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6177}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. Links in emails only work on this server;"
    log "set PUBLIC_URL to the address you open TutorLoom at, like http://192.168.1.20:6177" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/media"
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

# PG_PASSWORD: postgres superuser. DB_PASSWORD: the "tutorloom" role.
# SECRET_KEY signs sign-in tokens and invite links; changing it signs
# everyone out. ADMIN_PASSWORD: the first admin account, when none is set.
ensure_secret PG_PASSWORD 16
ensure_secret DB_PASSWORD 16
ensure_secret SECRET_KEY 32
ensure_secret ADMIN_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
DB_PASSWORD=$(secret DB_PASSWORD)

# First admin account, made once by the setup job: ADMIN_EMAIL and
# ADMIN_PASSWORD from the app settings, or the password made on first start.
ADMIN_EMAIL_V=${ADMIN_EMAIL:-CHANGEME@example.com}
ADMIN_PW=${ADMIN_PASSWORD:-$(secret ADMIN_PASSWORD)}
ADMIN_FILE=$DATA/admin-password.txt
if [ -z "${ADMIN_PASSWORD:-}" ] && [ ! -s "$ADMIN_FILE" ]; then
  printf 'TutorLoom first admin login\nemail: %s\npassword: %s\n' "$ADMIN_EMAIL_V" "$ADMIN_PW" > "$ADMIN_FILE"
  chmod 600 "$ADMIN_FILE"
fi
log "TutorLoom login is $ADMIN_EMAIL_V / $ADMIN_PW (set on the first start only; change it in TutorLoom)"

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' backend celery' "$HOSTS"; then
  echo "127.0.0.1 db redis backend celery frontend" >> "$HOSTS"
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

  # APP-SPECIFIC: /data/media is TutorLoom's /app/media (uploads: course
  # thumbnails, logos, submissions, certificates), owned by the image's
  # "app" user. nginx serves it at /media/ straight from /data/media.
  if [ "$(basename "$d")" = api ]; then
    mkdir -p "$d/app/media"
    if ! mountpoint -q "$d/app/media"; then
      mount --bind "$DATA/media" "$d/app/media" 2>/dev/null \
        || log "WARNING: could not bind $DATA/media to $d/app/media; uploads would be lost on update"
    fi
    uid=$(awk -F: '$1=="app"{print $3":"$4}' "$d/etc/passwd" 2>/dev/null || true)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/media" 2>/dev/null || true
    chmod 755 "$DATA" "$DATA/media" 2>/dev/null || true
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
INTERNAL_PORTS=" 5432 6379 8000 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@MEDIA_ROOT@/$(sed_escape "$DATA/media")/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# Email: with no EMAIL_HOST (and no Amazon SES keys), emails are printed to
# the app log instead of being sent, as in upstream's compose.
if [ -n "${EMAIL_HOST:-}" ]; then
  EMAIL_BACKEND_V=django.core.mail.backends.smtp.EmailBackend
else
  EMAIL_BACKEND_V=django.core.mail.backends.console.EmailBackend
  [ -n "${AWS_SES_ACCESS_KEY_ID:-}" ] || log "no EMAIL_HOST set: invite and password-reset emails are printed in the app log"
fi

# From upstream's docker-compose.yml and .env.example, with Postgres and
# Redis on 127.0.0.1, uploads in /data/media and the secrets made above.
TL_ENV=("$TZV"
  "SECRET_KEY=$(secret SECRET_KEY)"
  "DEBUG=False"
  "ALLOWED_HOSTS=${ALLOWED_HOSTS:-*}"
  "DB_NAME=tutorloom"
  "DB_USER=tutorloom"
  "DB_PASSWORD=$DB_PASSWORD"
  "DB_HOST=127.0.0.1"
  "DB_PORT=5432"
  "REDIS_URL=redis://127.0.0.1:6379/1"
  "CELERY_BROKER_URL=redis://127.0.0.1:6379/0"
  "CELERY_RESULT_BACKEND=django-db"
  "FRONTEND_URL=$PUBLIC_URL"
  "BACKEND_PUBLIC_URL=$PUBLIC_URL"
  "NUM_PROXIES=${NUM_PROXIES:-1}"
  "EMAIL_BACKEND=$EMAIL_BACKEND_V"
  "USE_S3=${USE_S3:-False}"
  "TUTORLOOM_WEB_WORKERS=${TUTORLOOM_WEB_WORKERS:-3}"
  "TUTORLOOM_WORKER_CONCURRENCY=${TUTORLOOM_WORKER_CONCURRENCY:-2}")

# ---- settings: the README variables: list (Apps/tutorloom/) ----
# TutorLoom reads these itself on every start; blank ones are skipped, so
# they mean "default".
write_env api "${TL_ENV[@]}"
pass_env api 'EMAIL_(HOST|PORT|USE_TLS|HOST_USER|HOST_PASSWORD)|DEFAULT_FROM_EMAIL|AWS_SES_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|REGION)'
pass_env api 'AWS_S3_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|REGION_NAME)|AWS_STORAGE_BUCKET_NAME|THROTTLE_RATE_(LOGIN|PASSWORD_RESET_EMAIL|AUTH_TOKEN)'

write_env worker "${TL_ENV[@]}"
pass_env worker 'EMAIL_(HOST|PORT|USE_TLS|HOST_USER|HOST_PASSWORD)|DEFAULT_FROM_EMAIL|AWS_SES_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|REGION)'
pass_env worker 'AWS_S3_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|REGION_NAME)|AWS_STORAGE_BUCKET_NAME|THROTTLE_RATE_(LOGIN|PASSWORD_RESET_EMAIL|AUTH_TOKEN)'

write_env setup "${TL_ENV[@]}" \
  "ADMIN_EMAIL=$ADMIN_EMAIL_V" \
  "ADMIN_PASSWORD=$ADMIN_PW" \
  "TUTORLOOM_ORG_NAME=${TUTORLOOM_ORG_NAME:-My Academy}" \
  "TUTORLOOM_BATCH_NAME=${TUTORLOOM_BATCH_NAME:-Batch 1}"
pass_env setup 'EMAIL_(HOST|PORT|USE_TLS|HOST_USER|HOST_PASSWORD)|DEFAULT_FROM_EMAIL|AWS_SES_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|REGION)'
pass_env setup 'AWS_S3_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|REGION_NAME)|AWS_STORAGE_BUCKET_NAME|THROTTLE_RATE_(LOGIN|PASSWORD_RESET_EMAIL|AUTH_TOKEN)'

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

pgbin=/usr/lib/postgresql/16/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE tutorloom LOGIN PASSWORD '${DB_PASSWORD}';" \
    -c "CREATE DATABASE tutorloom OWNER tutorloom;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
