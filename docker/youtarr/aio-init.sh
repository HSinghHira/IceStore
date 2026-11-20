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
# cred_add, prep_chroots.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# Youtarr follows the browser's address, so it needs no public URL. The
# banner shows the published port.
APP_URL=http://localhost:6755

# ---- one folder per stateful service under /data ----
# mariadb/ holds channels, videos and jobs; youtarr/ the config, job files and
# thumbnails (upstream's ./config, ./jobs and ./server/images). The videos go
# to /videos (/DATA/Media/YouTube by default).
STATE=$DATA/state
VIDEOS=${AIO_VIDEOS:-/videos}
mkdir -p "$STATE/overrides" "$DATA/mariadb" "$DATA/youtarr/config" \
         "$DATA/youtarr/jobs" "$DATA/youtarr/images"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret DB_PASSWORD 16
ensure_secret ADMIN_PASSWORD 9
DB_PASSWORD=$(secret DB_PASSWORD)

# The admin login. Youtarr sets AUTH_PRESET_* on every start, so the made
# password stays the login until you set your own in AUTH_PRESET_PASSWORD.
ADMIN_USER=${AUTH_PRESET_USERNAME:-admin}
ADMIN_PW=${AUTH_PRESET_PASSWORD:-$(secret ADMIN_PASSWORD)}

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$APP_URL")"
cred_add USERNAME "$ADMIN_USER"
if [ -n "${AUTH_PRESET_PASSWORD:-}" ]; then
  cred_add PASSWORD "(the one you set in AUTH_PRESET_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PW"
  cred_note "To change it, set AUTH_PRESET_PASSWORD (8 to 64 characters) in the app settings."
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'youtarr-db' "$HOSTS"; then
  echo "127.0.0.1 youtarr youtarr-db" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
bind_dir() {
  mkdir -p "$2"
  mountpoint -q "$2" || mount --bind "$1" "$2"
}
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: upstream's four bind mounts. Youtarr runs as root inside.
  if [ "$name" = youtarr ]; then
    bind_dir "$DATA/youtarr/config" "$d/app/config"
    bind_dir "$DATA/youtarr/jobs"   "$d/app/jobs"
    bind_dir "$DATA/youtarr/images" "$d/app/server/images"
    bind_dir "$VIDEOS"              "$d/usr/src/app/data"
  fi
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

# From upstream's docker-compose.yml, with MariaDB on 127.0.0.1.
write_env youtarr "$TZV" \
  "IN_DOCKER_CONTAINER=1" \
  "DB_HOST=127.0.0.1" \
  "DB_PORT=3306" \
  "DB_USER=youtarr" \
  "DB_PASSWORD=$DB_PASSWORD" \
  "DB_NAME=youtarr" \
  "AUTH_ENABLED=${AUTH_ENABLED:-true}" \
  "AUTH_PRESET_USERNAME=$ADMIN_USER" \
  "AUTH_PRESET_PASSWORD=$ADMIN_PW" \
  "YOUTUBE_OUTPUT_DIR=/DATA/Media/YouTube" \
  "LOG_LEVEL=${LOG_LEVEL:-info}"

# ---- settings: the README variables: list (Apps/youtarr/) ----
# Youtarr reads these itself on every start; blank ones are skipped, so they
# mean "default".
pass_env youtarr 'EXTERNAL_API_ENABLED|TRUST_PROXY|YOUTARR_COOKIES_FILE|LOG_FILE_MAX_SIZE|LOG_FILE_MAX_COUNT|OUTPUT_DIR_HEALTHCHECK_TIMEOUT'

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

# ---- first-start database ----
chown -R mysql:mysql "$DATA/mariadb"
if [ ! -d "$DATA/mariadb/mysql" ]; then
  log "first start: creating the database"
  mariadb-install-db --user=mysql --datadir="$DATA/mariadb" --auth-root-authentication-method=socket \
    --skip-test-db > /dev/null
  mkdir -p /run/mysqld
  chown mysql:mysql /run/mysqld
  setpriv --reuid=mysql --regid=mysql --init-groups /usr/sbin/mariadbd --datadir="$DATA/mariadb" \
    --skip-networking --socket=/run/mysqld/mysqld.sock &
  for _ in $(seq 60); do
    mariadb-admin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1 && break
    sleep 1
  done
  mariadb --socket=/run/mysqld/mysqld.sock <<SQL
CREATE DATABASE IF NOT EXISTS youtarr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'youtarr'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS 'youtarr'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON youtarr.* TO 'youtarr'@'127.0.0.1';
GRANT ALL PRIVILEGES ON youtarr.* TO 'youtarr'@'localhost';
FLUSH PRIVILEGES;
SQL
  mariadb-admin --socket=/run/mysqld/mysqld.sock shutdown
  wait || true
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
