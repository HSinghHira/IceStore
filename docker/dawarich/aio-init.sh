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

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# ---- public address: only used for links in emails (DOMAIN) and to turn on
# ---- HTTPS-only mode for an https:// address. The app itself follows the
# ---- browser's address (APPLICATION_HOSTS is left empty: any host works).
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6175}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. Links in emails only work on this server;"
    log "set PUBLIC_URL to the address you open Dawarich at, like http://192.168.1.20:6175" ;;
esac
scheme=${PUBLIC_URL%%://*}
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/storage" "$DATA/watched"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----

# PG_PASSWORD: postgres superuser. DB_PASSWORD: the "dawarich" role.
# SECRET_KEY_BASE signs sessions (changing it signs everyone out). The three
# OTP keys encrypt two-factor secrets: never change them, or 2FA stops
# working. The JWT keys sign mobile-app and account-link tokens.
ensure_secret PG_PASSWORD 16
ensure_secret DB_PASSWORD 16
ensure_secret SECRET_KEY_BASE 64
ensure_secret OTP_PRIMARY_KEY 32
ensure_secret OTP_DETERMINISTIC_KEY 32
ensure_secret OTP_SALT 32
ensure_secret JWT_SECRET_KEY 32
ensure_secret AUTH_JWT_SECRET_KEY 32
ensure_secret ADMIN_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
DB_PASSWORD=$(secret DB_PASSWORD)

# Admin password for the seeded demo@dawarich.app account: ADMIN_PASSWORD
# from the app settings, or the one made on first start.
ADMIN_PW=${ADMIN_PASSWORD:-$(secret ADMIN_PASSWORD)}
ADMIN_FILE=$DATA/admin-password.txt
if [ -z "${ADMIN_PASSWORD:-}" ] && [ ! -s "$ADMIN_FILE" ]; then
  printf 'Dawarich login\nemail: demo@dawarich.app\npassword: %s\n' "$ADMIN_PW" > "$ADMIN_FILE"
  chmod 600 "$ADMIN_FILE"
fi

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add EMAIL demo@dawarich.app
if [ -n "${ADMIN_PASSWORD:-}" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PW"
  cred_note "Also saved in $ADMIN_FILE"
fi
cred_note "Changed it in Dawarich? Your new password is the one that works."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'dawarich_redis' "$HOSTS"; then
  echo "127.0.0.1 dawarich_db dawarich_redis dawarich_app" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: upstream's volumes. /data/storage is /var/app/storage
  # (imports, exports, route videos) and /data/watched is
  # /var/app/tmp/imports/watched (drop files there to import them). The app
  # runs as root, as in upstream's compose.
  if [ "$(basename "$d")" = dawarich ]; then
    for pair in "storage:var/app/storage" "watched:var/app/tmp/imports/watched"; do
      src=$DATA/${pair%%:*}
      dst=$d/${pair#*:}
      mkdir -p "$dst"
      if ! mountpoint -q "$dst"; then
        mount --bind "$src" "$dst" 2>/dev/null \
          || log "WARNING: could not bind $src to $dst; files there would be lost on update"
      fi
    done
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 5432 6379 "
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

# From upstream's docker/docker-compose.yml, with Postgres and Redis on
# 127.0.0.1 and the secrets made above. Jobs run inside the web process
# (SIDEKIQ_EMBEDDED), as upstream's compose does.
write_env dawarich "$TZV" \
  "TIME_ZONE=${TZ:-UTC}" \
  "RAILS_ENV=production" \
  "RAILS_LOG_TO_STDOUT=true" \
  "SELF_HOSTED=true" \
  "REDIS_URL=redis://127.0.0.1:6379" \
  "DATABASE_HOST=127.0.0.1" \
  "DATABASE_PORT=5432" \
  "DATABASE_USERNAME=dawarich" \
  "DATABASE_PASSWORD=$DB_PASSWORD" \
  "DATABASE_NAME=dawarich_production" \
  "APPLICATION_PROTOCOL=$scheme" \
  "APPLICATION_HOSTS=${APPLICATION_HOSTS:-}" \
  "DOMAIN=$hostport" \
  "SECRET_KEY_BASE=$(secret SECRET_KEY_BASE)" \
  "OTP_ENCRYPTION_PRIMARY_KEY=$(secret OTP_PRIMARY_KEY)" \
  "OTP_ENCRYPTION_DETERMINISTIC_KEY=$(secret OTP_DETERMINISTIC_KEY)" \
  "OTP_ENCRYPTION_KEY_DERIVATION_SALT=$(secret OTP_SALT)" \
  "JWT_SECRET_KEY=$(secret JWT_SECRET_KEY)" \
  "AUTH_JWT_SECRET_KEY=$(secret AUTH_JWT_SECRET_KEY)" \
  "PROMETHEUS_EXPORTER_ENABLED=false" \
  "SIDEKIQ_EMBEDDED=true" \
  "WEB_CONCURRENCY=0" \
  "BACKGROUND_PROCESSING_CONCURRENCY=${BACKGROUND_PROCESSING_CONCURRENCY:-2}" \
  "STORE_GEODATA=${STORE_GEODATA:-true}" \
  "STORAGE_BACKEND=${STORAGE_BACKEND:-local}"

# ---- settings: the README variables: list (Apps/dawarich/) ----
# Dawarich reads these itself on every start; blank ones are skipped, so
# they mean "default".
pass_env dawarich 'SMTP_(SERVER|PORT|DOMAIN|USERNAME|PASSWORD|FROM|SSL|STARTTLS|AUTHENTICATION|OPENSSL_VERIFY_MODE)'
pass_env dawarich 'OIDC_(CLIENT_ID|CLIENT_SECRET|ISSUER|REDIRECT_URI|PROVIDER_NAME|AUTO_REGISTER|PKCE_ENABLED)'
pass_env dawarich 'ALLOW_EMAIL_PASSWORD_(REGISTRATION|LOGIN)'
pass_env dawarich 'PHOTON_API_(HOST|KEY|USE_HTTPS|LANGUAGE)|NOMINATIM_API_(HOST|KEY|USE_HTTPS)'
pass_env dawarich 'GEOAPIFY_API_KEY|LOCATIONIQ_API_KEY|REVERSE_GEOCODING_(RPS|CONCURRENCY)'
pass_env dawarich 'AWS_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|REGION|BUCKET|ENDPOINT_URL)'
pass_env dawarich 'VIDEO_RETENTION_DAYS|VIDEO_MAX_PER_USER|SKIP_VISITS_FLEET_REDETECT|VECTOR_TILES_QUERY_TIMEOUT_MS'

write_env admin "ADMIN_PASSWORD=$ADMIN_PW"

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
pg_setup /usr/lib/postgresql/17/bin
chown redis:redis "$DATA/redis"

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums

  # Upstream connects as the Postgres superuser (POSTGRES_USER=postgres), so
  # the "dawarich" role is one too: its migrations create the postgis
  # extension.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE dawarich LOGIN SUPERUSER PASSWORD '${DB_PASSWORD}';" \
    -c "CREATE DATABASE dawarich_production OWNER dawarich;"
  pg_psql -d dawarich_production \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
