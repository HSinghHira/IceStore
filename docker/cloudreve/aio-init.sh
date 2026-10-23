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

log() { echo "[init] $*"; }

# ---- public address: Cloudreve's "Site URL" (share links, WebDAV, emails) ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6125}
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

# ---- settings: the compose environment: plus the README variables: list (Apps/cloudreve/) ----
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

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

# ---- built-in data folders and first-start database ----
id postgres >/dev/null
id redis >/dev/null
mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql "$DATA/postgres"
chown redis:redis "$DATA/redis"
chmod 700 "$DATA/postgres"

pgbin=/usr/lib/postgresql/17/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  # trust = no password, as in upstream's compose. Postgres only listens on
  # 127.0.0.1 and the socket in /run/postgresql, inside this container.
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth=trust >/dev/null

  # Upstream's "cloudreve" user is the Postgres superuser (POSTGRES_USER=cloudreve).
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE cloudreve LOGIN SUPERUSER;" \
    -c "CREATE DATABASE cloudreve OWNER cloudreve;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
