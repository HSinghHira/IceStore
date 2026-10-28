#!/bin/bash
# First thing that runs in the container. Makes secrets, writes the backend's
# environment and the gateway config, prepares the database, then hands over
# to supervisord.
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
# MailFlow works from any address (the gateway handles the WebSocket origin
# check), so PUBLIC_URL is only used for links: invites, password resets,
# OIDC sign-in and the web push sender.
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6130}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis"
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

# DB_PASSWORD: Postgres. SESSION_SECRET signs the session cookie.
# ENCRYPTION_KEY (64 hex characters) encrypts the stored mail passwords and
# OAuth tokens. If it is lost, every mail account has to be signed in again,
# so back up /data/state with the database.
ensure_secret DB_PASSWORD 16
ensure_secret SESSION_SECRET 32
ensure_secret ENCRYPTION_KEY 32

# Web push keys (VAPID), so phone and desktop notifications work without
# setup. They must never change, or every device has to subscribe again.
b64url() { base64 -w0 | tr '+/' '-_' | tr -d '='; }
if ! grep -q '^VAPID_PRIVATE_KEY_GEN=' "$SECRETS"; then
  key=$(openssl ecparam -name prime256v1 -genkey -noout 2>/dev/null)
  priv=$(printf '%s\n' "$key" | openssl ec -outform DER 2>/dev/null | tail -c +8 | head -c 32 | b64url)
  pub=$(printf '%s\n' "$key" | openssl ec -pubout -outform DER 2>/dev/null | tail -c 65 | b64url)
  if [ ${#priv} -eq 43 ] && [ ${#pub} -eq 87 ]; then
    printf 'VAPID_PUBLIC_KEY_GEN=%s\nVAPID_PRIVATE_KEY_GEN=%s\n' "$pub" "$priv" >> "$SECRETS"
  else
    log "warning: could not make web push keys; push notifications stay off"
  fi
  unset key priv pub
fi

DB_PASSWORD=$(secret DB_PASSWORD)
SESSION_SECRET=$(secret SESSION_SECRET)
ENCRYPTION_KEY=$(secret ENCRYPTION_KEY)

# Your own push keys win, but only as a pair.
if [ -n "${VAPID_PUBLIC_KEY:-}" ] && [ -n "${VAPID_PRIVATE_KEY:-}" ]; then
  VAPID_PUB=$VAPID_PUBLIC_KEY
  VAPID_PRIV=$VAPID_PRIVATE_KEY
else
  VAPID_PUB=$(secret VAPID_PUBLIC_KEY_GEN)
  VAPID_PRIV=$(secret VAPID_PRIVATE_KEY_GEN)
fi
# The push sender must be a mailto: or https: address. Upstream falls back to
# APP_URL, which is http:// here, so give it a mailto: unless PUBLIC_URL is https.
case $PUBLIC_URL in
  https://*) VAPID_SUBJECT_DEFAULT=$PUBLIC_URL ;;
  *)         VAPID_SUBJECT_DEFAULT=mailto:admin@mailflow.local ;;
esac

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'mailflow-postgres' "$HOSTS"; then
  echo "127.0.0.1 postgres redis backend mailflow-postgres mailflow-redis mailflow-backend" >> "$HOSTS"
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
PUBLIC_ORIGIN=${PUBLIC_URL%%://*}://$hostport
EXTRA_LISTEN=""
# every port any service listens on inside the container
INTERNAL_PORTS=" 3000 5432 6379 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" \
    -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@PUBLIC_ORIGIN@/$(sed_escape "$PUBLIC_ORIGIN")/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# The backend, as in upstream's docker-compose.ghcr.yml. FRONTEND_URL is the
# CORS origin; the web app is served from the same address, so it only
# matters for other origins.
write_env backend "$TZV" \
  "NODE_ENV=production" \
  "PORT=3000" \
  "APP_URL=$PUBLIC_URL" \
  "FRONTEND_URL=$PUBLIC_URL" \
  "SESSION_SECRET=$SESSION_SECRET" \
  "ENCRYPTION_KEY=$ENCRYPTION_KEY" \
  "DB_HOST=127.0.0.1" \
  "DB_PORT=5432" \
  "DB_NAME=mailflow" \
  "DB_USER=mailflow" \
  "DB_PASSWORD=$DB_PASSWORD" \
  "REDIS_URL=redis://127.0.0.1:6379" \
  "VAPID_PUBLIC_KEY=$VAPID_PUB" \
  "VAPID_PRIVATE_KEY=$VAPID_PRIV" \
  "VAPID_SUBJECT=${VAPID_SUBJECT:-$VAPID_SUBJECT_DEFAULT}"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every README setting the backend reads by its own name.
pass_env backend 'TRUST_PROXY_HOPS|LOG_LEVEL|UPDATE_CHECK_DISABLED|IMAP_MAX_PERSISTENT_PER_HOST|IMAGE_CACHE_MAX_MB|ALLOW_PRIVATE_IMAP_HOSTS|MS_BUILTIN_APP|MS_CLIENT_ID|MS_CLIENT_SECRET|MS_TENANT_ID|MS_REDIRECT_URI|GOOGLE_CLIENT_ID|GOOGLE_CLIENT_SECRET|GOOGLE_REDIRECT_URI'

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

# Like upstream's postgres container: the superuser is "mailflow" and owns the
# "mailflow" database. pg_trgm (used for search) is made here too, though the
# backend's migrations would make it as well.
pgbin=/usr/lib/postgresql/16/bin
if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$DB_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/initdb -D "$DATA/postgres" -U mailflow -E UTF8 --locale=C.UTF-8 \
    --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  setpriv --reuid=postgres --regid=postgres --init-groups \
    psql -h /run/postgresql -U mailflow -d postgres -v ON_ERROR_STOP=1 -q -c "CREATE DATABASE mailflow OWNER mailflow;"
  setpriv --reuid=postgres --regid=postgres --init-groups \
    psql -h /run/postgresql -U mailflow -d mailflow -v ON_ERROR_STOP=1 -q -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
fi

log "MailFlow will be ready at $PUBLIC_URL in a minute. The first account you create becomes the admin."
exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
