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

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

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
else
  SETUP_TOKEN=$(secret SETUP_BOOTSTRAP_TOKEN_GENERATED)
fi

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
if [ -n "${SETUP_BOOTSTRAP_TOKEN:-}" ]; then
  cred_add "SETUP TOKEN" "(the one you set in SETUP_BOOTSTRAP_TOKEN)"
else
  cred_add "SETUP TOKEN" "$SETUP_TOKEN"
  cred_note "Also saved in $SECRETS (SETUP_BOOTSTRAP_TOKEN_GENERATED)"
fi
cred_note "Enter the setup token on first visit to make the admin account."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'bookorbit-db' "$HOSTS"; then
  echo "127.0.0.1 postgres bookorbit-db bookorbit-app" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
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
  return 0
}
prep_chroots

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
pg_setup /usr/lib/postgresql/18/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums

  # Upstream's "bookorbit" user is the Postgres superuser (POSTGRES_USER=bookorbit),
  # so it stays a superuser here and the migrations behave the same. The
  # extensions are the ones from upstream's docker/postgres/init.sql.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE bookorbit LOGIN SUPERUSER PASSWORD '${BOOKORBIT_DB_PASSWORD}';" \
    -c "CREATE DATABASE bookorbit OWNER bookorbit;"
  pg_psql -d bookorbit \
    -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' \
    -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;' \
    -c 'CREATE EXTENSION IF NOT EXISTS unaccent;' \
    -c 'CREATE EXTENSION IF NOT EXISTS vector;'
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
