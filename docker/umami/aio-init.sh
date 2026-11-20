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

# Umami follows the browser's address (dashboard, tracker script and collect
# endpoint are all relative), so it needs no public URL. The banner shows the
# published port.
APP_URL=http://localhost:6750

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
# APP_SECRET signs sign-in tokens and share links. TWO_FACTOR_ENCRYPTION_KEY
# (64 hex characters) encrypts two-factor secrets and must never change once
# used. ADMIN_PASSWORD replaces the built-in admin/umami login (run-svc.sh
# "admin").
ensure_secret PG_PASSWORD 16
ensure_secret UMAMI_DB_PASSWORD 16
ensure_secret APP_SECRET 32
ensure_secret TWO_FACTOR_ENCRYPTION_KEY 32
ensure_secret ADMIN_PASSWORD 9
PG_PASSWORD=$(secret PG_PASSWORD)
UMAMI_DB_PASSWORD=$(secret UMAMI_DB_PASSWORD)

# ADMIN_PASSWORD from the app settings wins over the made one. Either is only
# set while admin still has the built-in password.
ADMIN_PW=${ADMIN_PASSWORD:-$(secret ADMIN_PASSWORD)}

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$APP_URL")"
cred_add USERNAME admin
if [ -n "${ADMIN_PASSWORD:-}" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PW"
fi
cred_note "This replaces Umami's built-in admin/umami login on first start. Once you change it in Profile, Umami keeps yours."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -qw 'umami' "$HOSTS"; then
  echo "127.0.0.1 db umami" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
# Umami keeps everything in Postgres; its chroot is stateless.
chroot_extra() {
  local d=$1 name=$2
  return 0
}
prep_chroots

# ---- gateway ----
# Nothing inside calls the public address, so the gateway listens on 8080 only.
EXTRA_LISTEN=""
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# From upstream's docker-compose.yml, with the database on 127.0.0.1 and
# every secret made above. DISABLE_TELEMETRY defaults to on here.
write_env umami "$TZV" \
  "NODE_ENV=production" \
  "PORT=3000" \
  "HOSTNAME=0.0.0.0" \
  "DATABASE_URL=postgresql://umami:$UMAMI_DB_PASSWORD@127.0.0.1:5432/umami" \
  "APP_SECRET=$(secret APP_SECRET)" \
  "TWO_FACTOR_ENCRYPTION_KEY=$(secret TWO_FACTOR_ENCRYPTION_KEY)" \
  "DISABLE_TELEMETRY=${DISABLE_TELEMETRY:-1}"

# ---- settings: the README variables: list (Apps/umami/) ----
# Umami reads these itself on every start; blank ones are skipped, so they
# mean "default".
pass_env umami 'DISABLE_UPDATES|DISABLE_BOT_CHECK|DISABLE_LOGIN|PRIVATE_MODE|FORCE_SSL'
pass_env umami 'TRACKER_SCRIPT_NAME|COLLECT_API_ENDPOINT|CLIENT_IP_HEADER|IGNORE_IP|CORS_MAX_AGE'
pass_env umami 'DEFAULT_LOCALE|DEFAULT_CURRENCY|LOG_QUERY|DEBUG'

# The admin job (built-in, see run-svc.sh) reads only this.
write_env admin "UMAMI_ADMIN_PASSWORD=$ADMIN_PW"

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
pg_setup /usr/lib/postgresql/15/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql \
    -c "CREATE ROLE umami LOGIN PASSWORD '${UMAMI_DB_PASSWORD}';" \
    -c "CREATE DATABASE umami OWNER umami;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
