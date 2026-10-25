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

# ---- public address: IND_BASE_URL, FRONTEND_URL and CORS_ORIGINS ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6152}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. Sign-in only works at exactly this address;"
    log "set PUBLIC_URL to the address you open Indelible at, like http://192.168.1.20:6152" ;;
esac

# Development mode keeps sign-in cookies working over plain http on your
# network. Over https (behind your own reverse proxy) the default is
# production, which needs secure cookies.
case $PUBLIC_URL in
  https://*) IND_ENV_V=${IND_ENV:-production} ;;
  *)         IND_ENV_V=${IND_ENV:-development} ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/silo"
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
# AUTH_CREDENTIAL_KEY must be exactly 32 random bytes, base64 encoded.
ensure_b64_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -base64 "$2")" >> "$SECRETS"
  fi
  return 0
}
secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# PG_PASSWORD: postgres superuser. INDELIBLE_DB_PASSWORD: the "indelible"
# role. S3_SECRET: the Silo storage login. JWT/CSRF/ASSET_COOKIE secrets sign
# sign-ins and file links; changing them signs everyone out.
# AUTH_CREDENTIAL_KEY encrypts saved integration tokens (Notion...): never
# change it, or those integrations must be connected again.
ensure_secret PG_PASSWORD 16
ensure_secret INDELIBLE_DB_PASSWORD 16
ensure_secret S3_SECRET 20
ensure_secret JWT_SECRET 32
ensure_secret CSRF_SECRET 32
ensure_secret ASSET_COOKIE_SECRET 32
ensure_b64_secret AUTH_CREDENTIAL_KEY 32
PG_PASSWORD=$(secret PG_PASSWORD)
INDELIBLE_DB_PASSWORD=$(secret INDELIBLE_DB_PASSWORD)
S3_KEY=indelible
S3_SECRET=$(secret S3_SECRET)
S3_REGION=us-east-1
S3_BUCKET=indelible

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'ind-renderer' "$HOSTS"; then
  echo "127.0.0.1 postgres silo renderer ind-api ind-worker ind-renderer" >> "$HOSTS"
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
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 3100 5432 9000 9001 "
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

DB_URL="postgres://indelible:$INDELIBLE_DB_PASSWORD@127.0.0.1:5432/indelible"
S3=("S3_ENDPOINT=http://127.0.0.1:9000" "S3_REGION=$S3_REGION" "S3_BUCKET=$S3_BUCKET"
    "S3_ACCESS_KEY=$S3_KEY" "S3_SECRET_KEY=$S3_SECRET" "S3_FORCE_PATH_STYLE=true")

# CORS_ORIGINS: PUBLIC_URL, plus any other addresses you add (comma separated).
CORS_V=$PUBLIC_URL
[ -n "${CORS_ORIGINS:-}" ] && CORS_V="$CORS_V,$CORS_ORIGINS"

write_env silo "$TZV" \
  "MINIO_ROOT_USER=$S3_KEY" \
  "MINIO_ROOT_PASSWORD=$S3_SECRET" \
  "MINIO_SITE_REGION=$S3_REGION" \
  "MINIO_BROWSER=off"

# Read by run-svc.sh before the API starts, to make the bucket.
write_env s3 "S3_KEY=$S3_KEY" "S3_SECRET=$S3_SECRET" "S3_REGION=$S3_REGION" "S3_BUCKET=$S3_BUCKET"

# From upstream's docker-compose.yml, .env.example and production install
# guide, with everything on 127.0.0.1 and the secrets made above. The API
# moves to 3000 because the gateway has 8080.
write_env api "$TZV" \
  "IND_ENV=$IND_ENV_V" \
  "IND_HOST=127.0.0.1" \
  "IND_PORT=3000" \
  "IND_BASE_URL=$PUBLIC_URL" \
  "FRONTEND_URL=$PUBLIC_URL" \
  "CORS_ORIGINS=$CORS_V" \
  "DATABASE_URL=$DB_URL" \
  "${S3[@]}" \
  "JWT_SECRET=$(secret JWT_SECRET)" \
  "CSRF_SECRET=$(secret CSRF_SECRET)" \
  "ASSET_COOKIE_SECRET=$(secret ASSET_COOKIE_SECRET)" \
  "AUTH_CREDENTIAL_KEY=$(secret AUTH_CREDENTIAL_KEY)" \
  "TRUSTED_PROXIES=${TRUSTED_PROXIES:-127.0.0.1/32}" \
  "NOTION_REDIRECT_URL=${NOTION_REDIRECT_URL:-$PUBLIC_URL/api/v1/integrations/notion/callback}"

write_env worker "$TZV" \
  "IND_ENV=$IND_ENV_V" \
  "DATABASE_URL=$DB_URL" \
  "RENDERER_URL=http://127.0.0.1:3100" \
  "${S3[@]}" \
  "AUTH_CREDENTIAL_KEY=$(secret AUTH_CREDENTIAL_KEY)"

write_env renderer "$TZV" \
  "IND_ENV=$IND_ENV_V" \
  "RENDERER_HOST=127.0.0.1" \
  "RENDERER_PORT=3100" \
  "${S3[@]}"

# ---- settings: the README variables: list (Apps/indelible/) ----
# Indelible reads these itself on every start; blank ones are skipped, so
# they mean "default" (Indelible treats an empty value as set, so blanks must
# never reach it).
pass_env api 'AUTH_ALLOW_SIGNUPS|OIDC_[A-Z_]+|NOTION_CLIENT_(ID|SECRET)|EXTENSION_REDIRECT_URIS'
pass_env api 'EMAIL_(FEED|LIBRARY)_DOMAIN|EMAIL_INGEST_[A-Z_]+|RESEND_API_KEY'
pass_env api '(IMPORT_)?UPLOAD_MAX_BYTES'
pass_env worker 'EMAIL_INGEST_[A-Z_]+|RESEND_API_KEY|NOTION_[A-Z_]+|FEED_[A-Z_]+|TRASH_CLEANUP_[A-Z_]+|WORKER_MAX_CONCURRENCY'
pass_env renderer 'CAPTURE_(LOCALE|TIMEZONE|MAX_CONCURRENCY)'
pass_env api 'EGRESS_ALLOW_PRIVATE_TARGETS|WEBHOOKS_ALLOW_PRIVATE_TARGETS|RUST_LOG'
pass_env worker 'EGRESS_ALLOW_PRIVATE_TARGETS|WEBHOOKS_ALLOW_PRIVATE_TARGETS|RUST_LOG'
pass_env renderer 'EGRESS_ALLOW_PRIVATE_TARGETS|RUST_LOG'

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

  # Upstream's "indelible" user is the Postgres superuser
  # (POSTGRES_USER=indelible), so it stays one here. The vector extension is
  # upstream's docker/init-pgvector.sql.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE indelible LOGIN SUPERUSER PASSWORD '${INDELIBLE_DB_PASSWORD}';" \
    -c "CREATE DATABASE indelible OWNER indelible;"
  as_pg $pgbin/psql -h /run/postgresql -U postgres -d indelible -v ON_ERROR_STOP=1 -q \
    -c "CREATE EXTENSION IF NOT EXISTS vector;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
