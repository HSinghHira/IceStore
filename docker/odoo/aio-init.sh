#!/bin/bash
# First thing that runs in the container. Makes secrets, writes Odoo's
# environment and config file, prepares the database, then hands over to
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

# ---- public address: only used so internal calls to it reach the gateway ----
# Odoo learns its own address (web.base.url) from the browser on the first
# admin sign-in, through the X-Forwarded-* headers nginx sets.
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6156}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac

# ---- one folder per stateful service under /data ----
# /data/odoo is Odoo's /var/lib/odoo (file store, sessions); /data/addons is
# its /mnt/extra-addons, for your own modules.
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/odoo" "$DATA/addons"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
NEW_MASTER=0
ensure_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -hex "$2")" >> "$SECRETS"
    [ "$1" = ODOO_MASTER_PASSWORD ] && NEW_MASTER=1
  fi
  return 0
}
secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# PG_PASSWORD: postgres superuser. ODOO_DB_PASSWORD: the "odoo" role.
# ODOO_MASTER_PASSWORD: Odoo's admin_passwd, which guards the database
# manager (create, copy, back up, restore and delete databases).
ensure_secret PG_PASSWORD 16
ensure_secret ODOO_DB_PASSWORD 16
ensure_secret ODOO_MASTER_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
ODOO_DB_PASSWORD=$(secret ODOO_DB_PASSWORD)
MASTER=$(secret ODOO_MASTER_PASSWORD)
if [ -n "${ODOO_MASTER_PASSWORD:-}" ]; then
  MASTER=$ODOO_MASTER_PASSWORD
elif [ "$NEW_MASTER" = 1 ]; then
  log "first start: Odoo master password is $MASTER (also saved in $SECRETS)"
fi

# ---- hostnames from the old two-container app, all pointed at 127.0.0.1 ----
if ! grep -q 'odoo-db' "$HOSTS"; then
  echo "127.0.0.1 db odoo-db" >> "$HOSTS"
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

  # APP-SPECIFIC: Odoo's two volumes, kept in /data so they survive updates,
  # and given to the image's odoo user.
  if [ "$(basename "$d")" = odoo ]; then
    for pair in "$DATA/odoo:var/lib/odoo" "$DATA/addons:mnt/extra-addons"; do
      src=${pair%%:*}
      dst=$d/${pair#*:}
      mkdir -p "$dst"
      mountpoint -q "$dst" || mount --bind "$src" "$dst" 2>/dev/null \
        || log "WARNING: could not bind $src to $dst; it would be lost on update"
    done
    uid=$(awk -F: '$1=="odoo"{print $3":"$4}' "$d/etc/passwd" 2>/dev/null || true)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/odoo" "$DATA/addons"
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

# ---- settings: the README variables: list (Apps/odoo/) ----
# Odoo has no environment variables for these; they are keys in its config
# file. The whole file is written again on every start, so a blank or removed
# variable really means "Odoo's default", and a change in ZimaOS takes effect
# after a restart.
ODOO_WORKERS=${ODOO_WORKERS:-}
if [ -n "$ODOO_WORKERS" ] && ! [[ $ODOO_WORKERS =~ ^[0-9]+$ ]]; then
  log "ODOO_WORKERS must be a number (got: $ODOO_WORKERS); using 0"
  ODOO_WORKERS=""
fi
# With workers, the websocket is served by the separate gevent process on 8072.
WS_PORT=8069
[ -n "$ODOO_WORKERS" ] && [ "$ODOO_WORKERS" -gt 0 ] && WS_PORT=8072

conf_dir=$ROOTFS/odoo/etc/odoo
mkdir -p "$conf_dir"
conf=$conf_dir/odoo.conf
opt() { [ -n "$2" ] && printf '%s = %s\n' "$1" "$2"; return 0; }
{
  echo "; Written by aio-init on every start. Change Odoo's settings with the"
  echo "; variables in the app settings (see the IceStore Odoo page), not here."
  echo "[options]"
  opt addons_path /mnt/extra-addons
  opt data_dir /var/lib/odoo
  opt http_interface 127.0.0.1
  opt http_port 8069
  opt gevent_port 8072
  opt proxy_mode True
  opt admin_passwd "$MASTER"
  opt workers "$ODOO_WORKERS"
  opt max_cron_threads "${ODOO_MAX_CRON_THREADS:-}"
  opt limit_time_cpu "${ODOO_LIMIT_TIME_CPU:-}"
  opt limit_time_real "${ODOO_LIMIT_TIME_REAL:-}"
  opt limit_memory_soft "${ODOO_LIMIT_MEMORY_SOFT:-}"
  opt limit_memory_hard "${ODOO_LIMIT_MEMORY_HARD:-}"
  opt list_db "${ODOO_LIST_DB:-}"
  opt dbfilter "${ODOO_DBFILTER:-}"
  opt email_from "${ODOO_EMAIL_FROM:-}"
  opt smtp_server "${ODOO_SMTP_SERVER:-}"
  opt smtp_port "${ODOO_SMTP_PORT:-}"
  opt smtp_user "${ODOO_SMTP_USER:-}"
  opt smtp_password "${ODOO_SMTP_PASSWORD:-}"
  opt smtp_ssl "${ODOO_SMTP_SSL:-}"
  opt log_level "${ODOO_LOG_LEVEL:-}"
} > "$conf"
chmod 600 "$conf"
uid=$(awk -F: '$1=="odoo"{print $3":"$4}' "$ROOTFS/odoo/etc/passwd" 2>/dev/null || true)
[ -n "$uid" ] && chown "$uid" "$conf"

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 5432 8069 8072 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@WS_PORT@/$WS_PORT/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# The official image's /entrypoint.sh turns HOST/PORT/USER/PASSWORD into
# Odoo's --db_host/--db_port/--db_user/--db_password. Odoo itself always works
# in UTC; TZ only changes the time in its log lines.
write_env odoo "$TZV" \
  "HOME=/var/lib/odoo" \
  "HOST=127.0.0.1" \
  "PORT=5432" \
  "USER=odoo" \
  "PASSWORD=$ODOO_DB_PASSWORD"

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

pgbin=/usr/lib/postgresql/16/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database server"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  # Upstream's "odoo" user is the Postgres superuser (POSTGRES_USER=odoo), so
  # it stays one here: Odoo creates its databases itself, adds extensions such
  # as unaccent, and backs up and restores with pg_dump/pg_restore. Odoo
  # refuses to connect as "postgres", which is why it gets its own role.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE odoo LOGIN SUPERUSER PASSWORD '${ODOO_DB_PASSWORD}';"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database server ready. Open Odoo and create your first database."
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
