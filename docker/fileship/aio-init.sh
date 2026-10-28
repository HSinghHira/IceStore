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

# ---- public address ----
# Fileship follows the browser's address for everything except email links
# and single sign-on, which use its "dashboard address" (NUXT_SITE_URL).
# PUBLIC_URL becomes that address once it is not localhost; on localhost it
# is left blank, so email and single sign-on stay off until it is set.
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6131}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
SITE_URL=$PUBLIC_URL
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    SITE_URL=""
    log "PUBLIC_URL is $PUBLIC_URL. Fileship works from any address, but email links and"
    log "single sign-on need the real one: set PUBLIC_URL to something like http://192.168.1.20:6131" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/fileship"
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

# PG_PASSWORD: postgres superuser. FILESHIP_DB_PASSWORD: the "fileship" role.
# ADMIN_PASSWORD replaces the default admin / password login.
# Fileship makes its own encryption key (data/secret.key) on first start.
ensure_secret PG_PASSWORD 16
ensure_secret FILESHIP_DB_PASSWORD 16
ensure_secret ADMIN_PASSWORD 9
PG_PASSWORD=$(secret PG_PASSWORD)
FILESHIP_DB_PASSWORD=$(secret FILESHIP_DB_PASSWORD)

# Admin login: ADMIN_PASSWORD from the app settings wins; blank means the one
# made on first start. It only replaces the password while it is still
# upstream's "password"; after you change it in Fileship, this has no effect.
ADMIN_PW=${ADMIN_PASSWORD:-$(secret ADMIN_PASSWORD)}
ADMIN_LOGIN_FILE=$DATA/admin-password.txt
if [ -n "${ADMIN_PASSWORD:-}" ]; then
  log "Fileship login is admin / the ADMIN_PASSWORD you set (until you change the password in Fileship)"
else
  if [ ! -s "$ADMIN_LOGIN_FILE" ]; then
    printf 'Fileship first login\nusername: admin\npassword: %s\n' "$ADMIN_PW" > "$ADMIN_LOGIN_FILE"
    chmod 600 "$ADMIN_LOGIN_FILE"
  fi
  log "Fileship login is admin / $ADMIN_PW (until you change the password in Fileship; also in $ADMIN_LOGIN_FILE)"
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'fileship-blue' "$HOSTS"; then
  echo "127.0.0.1 postgres proxy fileship-blue fileship-green" >> "$HOSTS"
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

  # APP-SPECIFIC: Fileship keeps uploads, thumbnails, backups, AI models and
  # its encryption key (secret.key) in /fileship/data. It runs as root.
  if [ "$(basename "$d")" = fileship ]; then
    mkdir -p "$d/fileship/data"
    mountpoint -q "$d/fileship/data" || mount --bind "$DATA/fileship" "$d/fileship/data" \
      || log "warning: could not bind $DATA/fileship into $d/fileship/data"
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
INTERNAL_PORTS=" 3000 5432 8080 "
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

# From upstream's docker-compose.yml, with Postgres on 127.0.0.1 and the
# password made above. The updater-agent is left out: pointing at a closed
# port makes Fileship fall back to checking GitHub for new versions.
# NUXT_AI_PRESET defaults to low here (upstream: medium, 6 GB of memory).
write_env fileship "$TZV" \
  "NODE_ENV=production" \
  "HOST=127.0.0.1" \
  "PORT=3000" \
  "DATABASE_URL=postgresql://fileship:$FILESHIP_DB_PASSWORD@127.0.0.1:5432/fileship" \
  "NUXT_UPDATER_URL=http://127.0.0.1:9" \
  "NITRO_SHUTDOWN_TIMEOUT=25000" \
  "NUXT_AI_PRESET=${NUXT_AI_PRESET:-low}"
if [ -n "$SITE_URL" ]; then
  echo "NUXT_SITE_URL=$SITE_URL" >> "$RUN/fileship.env"
fi

# ---- settings: the README variables: list (Apps/fileship/) ----
# Fileship reads these itself on every start; blank ones are skipped, so they
# mean "default". A value saved in Administration -> Instance wins over them.
pass_env fileship 'NUXT_PUBLIC_SITE_NAME|NUXT_LOG_LEVEL|NUXT_TELEMETRY_ENABLED'
pass_env fileship 'NUXT_PUBLIC_REGISTRATION_ENABLED|NUXT_REGISTRATION_PERMISSIONS|NUXT_REGISTRATION_USABLE_SPACE'
pass_env fileship 'NUXT_SMTP_(HOST|PORT|SECURITY|USER|PASSWORD|FROM)'
pass_env fileship 'NUXT_OIDC_(ENABLED|ISSUER_URL|CLIENT_ID|CLIENT_SECRET|BUTTON_LABEL|AUTO_REGISTER)|NUXT_PASSWORD_LOGIN_ENABLED'
pass_env fileship 'NUXT_PUBLIC_TURNSTILE_SITE_KEY|NUXT_TURNSTILE_SECRET_KEY'
pass_env fileship 'NUXT_PUBLIC_AI_ENABLED|NUXT_AI_QUEUE_CONCURRENCY|NUXT_AI_INFERENCE_THREADS'
pass_env fileship 'NUXT_AVATAR_MAX_SIZE|NUXT_REMOVE_EXIF_DATA|NUXT_TRASH_RETENTION_DAYS|NUXT_SCHEDULED_BACKUPS_ENABLED'
pass_env fileship 'NUXT_PUBLIC_FILE_CHUNK_SIZE|NUXT_PUBLIC_RETURN_HTTPS'

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
id postgres >/dev/null
mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql "$DATA/postgres"
chmod 700 "$DATA/postgres"

pgbin=/usr/lib/postgresql/16/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE fileship LOGIN PASSWORD '${FILESHIP_DB_PASSWORD}';" \
    -c "CREATE DATABASE fileship OWNER fileship;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
