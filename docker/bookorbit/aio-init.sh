#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each service's
# environment, prepares the database, then hands over to supervisord.
set -euo pipefail

DATA=${AIO_DATA:-/data}
BOOKS=${AIO_BOOKS:-/books}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}
HOSTS=${AIO_HOSTS:-/etc/hosts}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/aio.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/aio.conf}
GATEWAY_PORT=8080

log() { echo "[init] $*"; }

# ---- public address: BookOrbit's APP_URL (links in emails, Kobo and OPDS) ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6124}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac

# ---- one folder per stateful service under /data ----
# bookorbit/ is the app's own /data: covers, cache, Book Dock, conversions.
# Your book files are the separate /books volume.
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/bookorbit" "$BOOKS"
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

# PG_PASSWORD: postgres superuser. BOOKORBIT_DB_PASSWORD: the "bookorbit" role.
# JWT_SECRET signs sign-ins. The *_ENCRYPTION_KEY values encrypt stored
# podcast URLs, SMTP, migration and download-client passwords; they must never
# change once used, so they are made once and kept.
# SETUP_BOOTSTRAP_TOKEN_GENERATED: used by the setup wizard when
# SETUP_BOOTSTRAP_TOKEN is blank.
ensure_secret PG_PASSWORD 16
ensure_secret BOOKORBIT_DB_PASSWORD 16
ensure_secret JWT_SECRET 32
ensure_secret PODCAST_ENCRYPTION_KEY 32
ensure_secret EMAIL_ENCRYPTION_KEY 32
ensure_secret MIGRATION_ENCRYPTION_KEY 32
ensure_secret BOOK_REQUEST_ENCRYPTION_KEY 32
ensure_secret SETUP_BOOTSTRAP_TOKEN_GENERATED 16
PG_PASSWORD=$(secret PG_PASSWORD)
BOOKORBIT_DB_PASSWORD=$(secret BOOKORBIT_DB_PASSWORD)

if [ -n "${SETUP_BOOTSTRAP_TOKEN:-}" ]; then
  SETUP_TOKEN=$SETUP_BOOTSTRAP_TOKEN
  log "the setup token is the one you set in SETUP_BOOTSTRAP_TOKEN"
else
  SETUP_TOKEN=$(secret SETUP_BOOTSTRAP_TOKEN_GENERATED)
  log "the setup token is: $SETUP_TOKEN (also saved in /data/state/secrets.env)"
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'bookorbit-db' "$HOSTS"; then
  echo "127.0.0.1 postgres bookorbit-db bookorbit-app" >> "$HOSTS"
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

  # APP-SPECIFIC: BookOrbit's /data lives in /data/bookorbit and its /books is
  # the container's /books volume. Without these mounts its files would live
  # in the image and vanish on update. Its entrypoint fixes the owner of /data.
  if [ "$(basename "$d")" = bookorbit ]; then
    for m in data:"$DATA/bookorbit" books:"$BOOKS"; do
      dst=$d/${m%%:*}
      src=${m#*:}
      mkdir -p "$dst"
      if ! mountpoint -q "$dst"; then
        mount --bind "$src" "$dst" 2>/dev/null \
          || log "WARNING: could not bind $src to $dst; files will not survive an update"
      fi
    done
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
INTERNAL_PORTS=" 3000 5432 "
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

# From upstream's docker-compose.yml and .env.example, with the database on
# 127.0.0.1 and every secret made above.
write_env bookorbit "$TZV" \
  "NODE_ENV=production" \
  "PORT=3000" \
  "HOST=127.0.0.1" \
  "POSTGRES_HOST=127.0.0.1" \
  "POSTGRES_PORT=5432" \
  "POSTGRES_USER=bookorbit" \
  "POSTGRES_PASSWORD=$BOOKORBIT_DB_PASSWORD" \
  "POSTGRES_DB=bookorbit" \
  "JWT_SECRET=$(secret JWT_SECRET)" \
  "PODCAST_ENCRYPTION_KEY=$(secret PODCAST_ENCRYPTION_KEY)" \
  "EMAIL_ENCRYPTION_KEY=$(secret EMAIL_ENCRYPTION_KEY)" \
  "MIGRATION_ENCRYPTION_KEY=$(secret MIGRATION_ENCRYPTION_KEY)" \
  "BOOK_REQUEST_ENCRYPTION_KEY=$(secret BOOK_REQUEST_ENCRYPTION_KEY)" \
  "SETUP_BOOTSTRAP_TOKEN=$SETUP_TOKEN" \
  "APP_URL=$PUBLIC_URL" \
  "CLIENT_URL=${CLIENT_URL:-$PUBLIC_URL}" \
  "LIBRARY_BROWSE_ROOT=${LIBRARY_BROWSE_ROOT:-/books}" \
  "NODE_MAX_OLD_SPACE_SIZE=${NODE_MAX_OLD_SPACE_SIZE:-auto}"

# ---- settings: the compose environment: plus the README variables: list (Apps/bookorbit/) ----
# BookOrbit reads these itself on every start; blank ones are skipped, so they
# mean "default". The database, secrets and URLs are wired up above.
pass_env bookorbit 'PUID|PGID|LOG_LEVEL|DISABLE_LOCAL_AUTH|OIDC_ALLOW_LOCAL_ISSUERS|BOOK_DOCK_PATH|GITHUB_RELEASES_TOKEN|CSP_ALLOW_CLOUDFLARE_INSIGHTS'

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

  # Upstream's "bookorbit" user is the Postgres superuser (POSTGRES_USER=bookorbit),
  # so it stays a superuser here and the migrations behave the same. The
  # extensions are the ones from upstream's docker/postgres/init.sql.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE bookorbit LOGIN SUPERUSER PASSWORD '${BOOKORBIT_DB_PASSWORD}';" \
    -c "CREATE DATABASE bookorbit OWNER bookorbit;"
  as_pg $pgbin/psql -h /run/postgresql -U postgres -d bookorbit -v ON_ERROR_STOP=1 -q \
    -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' \
    -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;' \
    -c 'CREATE EXTENSION IF NOT EXISTS unaccent;' \
    -c 'CREATE EXTENSION IF NOT EXISTS vector;'
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
