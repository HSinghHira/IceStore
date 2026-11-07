#!/bin/bash
# First thing that runs in the container. Writes each service's environment,
# prepares the database, then hands over to supervisord.
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

# ---- public address: Cloudreve's "Site URL" (share links, WebDAV, emails) ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6127}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac

# ---- one folder per stateful service under /data ----
# cloudreve/ is the app's own /cloudreve/data: conf.ini (with its session
# secret), uploads under the Local storage policy, avatars, thumbnails, temp.
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/cloudreve"

# ---- secrets ----
# None to make here. Like upstream's compose (POSTGRES_HOST_AUTH_METHOD=trust),
# PostgreSQL and Redis only listen on 127.0.0.1 inside this container and need
# no password. Cloudreve makes its own session secret (in conf.ini) and
# signing key (in the database) on first start.

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'postgresql' "$HOSTS"; then
  echo "127.0.0.1 postgresql postgres redis cloudreve-backend" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: Cloudreve's /cloudreve/data lives in /data/cloudreve.
  # Without this mount its files would live in the image and vanish on update.
  if [ "$(basename "$d")" = cloudreve ]; then
    mkdir -p "$d/cloudreve/data"
    if ! mountpoint -q "$d/cloudreve/data"; then
      mount --bind "$DATA/cloudreve" "$d/cloudreve/data" 2>/dev/null \
        || log "WARNING: could not bind $DATA/cloudreve to $d/cloudreve/data; files will not survive an update"
    fi
    # aria2 keeps its temp files here (upstream's Dockerfile makes it).
    mkdir -p "$DATA/cloudreve/temp/aria2"
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
INTERNAL_PORTS=" 5212 5432 6379 6800 6888 "
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

# From upstream's docker-compose.yml, with the database and Redis on 127.0.0.1.
# CR_CONF_<Section>.<Key> overrides a key in conf.ini on every start.
# CR_SETTING_DEFAULT_<name> is only used when Cloudreve creates its settings on
# the very first start; after that, the Site URL is changed in the admin panel.
write_env cloudreve "$TZV" \
  "CR_CONF_Database.Type=postgres" \
  "CR_CONF_Database.Host=127.0.0.1" \
  "CR_CONF_Database.Port=5432" \
  "CR_CONF_Database.User=cloudreve" \
  "CR_CONF_Database.Name=cloudreve" \
  "CR_CONF_Redis.Server=127.0.0.1:6379" \
  "CR_CONF_System.Listen=127.0.0.1:5212" \
  "CR_CONF_System.ProxyHeader=X-Forwarded-For" \
  "CR_SETTING_DEFAULT_siteURL=$PUBLIC_URL"

# ---- settings: the compose environment: plus the README variables: list (Apps/cloudreve-pro/) ----
# Cloudreve reads these itself; blank ones are skipped, so they mean "default".
pass_env cloudreve 'CR_CONF_System\.LogLevel|CR_SETTING_DEFAULT_(siteName|register_enabled|email_active|login_captcha|reg_captcha)'

# Files in /data/state/overrides/<service>.env are appended last, so users can
# change any service setting without rebuilding the image.
for f in "$STATE"/overrides/*.env; do
  [ -f "$f" ] || continue
  svc=$(basename "$f" .env)
  log "applying your overrides to $svc"
  cat "$f" >> "$RUN/$svc.env"
done

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "Sign up on first visit; the first account becomes the admin."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

# ---- built-in data folders and first-start database ----
pg_setup /usr/lib/postgresql/17/bin
id redis >/dev/null
chown redis:redis "$DATA/redis"

if pg_is_new; then
  log "first start: creating the database"
  # trust = no password, as in upstream's compose. Postgres only listens on
  # 127.0.0.1 and the socket in /run/postgresql, inside this container.
  as_pg "$PGBIN/initdb" -D "$PG_DIR" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth=trust >/dev/null

  # Upstream's "cloudreve" user is the Postgres superuser (POSTGRES_USER=cloudreve).
  pg_start_local
  pg_psql \
    -c "CREATE ROLE cloudreve LOGIN SUPERUSER;" \
    -c "CREATE DATABASE cloudreve OWNER cloudreve;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
