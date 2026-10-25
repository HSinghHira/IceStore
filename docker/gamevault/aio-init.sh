#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each
# service's environment, prepares the database, then hands over to
# supervisord.
set -euo pipefail

DATA=${AIO_DATA:-/data}
FILES=${AIO_FILES:-/files}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}
HOSTS=${AIO_HOSTS:-/etc/hosts}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/aio.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/aio.conf}
GATEWAY_PORT=8080

log() { echo "[init] $*"; }

# ---- public address: used for the OAuth2 sign-in callback ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6149}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac

# ---- one folder per stateful service under /data ----
# GameVault's own folders (config, media, savefiles, logs, plugins) live in
# /data/gamevault; the game library is the separate /files volume.
STATE=$DATA/state
GV=$DATA/gamevault
GV_DIRS="config media savefiles logs plugins"
mkdir -p "$STATE/overrides" "$DATA/postgres" "$FILES"
for x in $GV_DIRS; do mkdir -p "$GV/$x"; done
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

# PG_PASSWORD: postgres superuser. GAMEVAULT_DB_PASSWORD: the "gamevault"
# role. AUTH_SEED signs sign-in tokens; kept so a restart keeps everyone
# signed in.
ensure_secret PG_PASSWORD 16
ensure_secret GAMEVAULT_DB_PASSWORD 16
ensure_secret AUTH_SEED 32
PG_PASSWORD=$(secret PG_PASSWORD)
GAMEVAULT_DB_PASSWORD=$(secret GAMEVAULT_DB_PASSWORD)

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'gamevault-backend' "$HOSTS"; then
  echo "127.0.0.1 db gamevault-db gamevault-backend" >> "$HOSTS"
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

  # APP-SPECIFIC: GameVault's volumes. /data/gamevault/<x> is its /<x>, and
  # the /files volume (the game library) is its /files. Its own entrypoint
  # gives them to PUID:PGID on every start, as upstream does.
  if [ "$(basename "$d")" = gamevault ]; then
    for x in $GV_DIRS; do
      mkdir -p "$d/$x"
      mountpoint -q "$d/$x" || mount --bind "$GV/$x" "$d/$x" 2>/dev/null \
        || log "WARNING: could not bind $GV/$x to $d/$x; it would be lost on update"
    done
    mkdir -p "$d/files"
    mountpoint -q "$d/files" || mount --bind "$FILES" "$d/files" 2>/dev/null \
      || log "WARNING: could not bind $FILES to $d/files; GameVault will not see your games"
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
INTERNAL_PORTS=" 5432 8081 8443 "
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

# From upstream's docker-compose.yml and configuration docs, with the
# database on 127.0.0.1, GameVault on 8081 (8080 is the gateway's) and the
# secrets made above. Save file syncing is on, as in the old IceStore app.
write_env gamevault "$TZV" \
  "PUID=${PUID:-1000}" \
  "PGID=${PGID:-1000}" \
  "SERVER_PORT=8081" \
  "DB_SYSTEM=POSTGRESQL" \
  "DB_HOST=127.0.0.1" \
  "DB_PORT=5432" \
  "DB_USERNAME=gamevault" \
  "DB_PASSWORD=$GAMEVAULT_DB_PASSWORD" \
  "DB_DATABASE=gamevault" \
  "AUTH_SEED=$(secret AUTH_SEED)" \
  "SAVEFILES_ENABLED=${SAVEFILES_ENABLED:-true}" \
  "AUTH_OAUTH2_CALLBACK_URL=${AUTH_OAUTH2_CALLBACK_URL:-$PUBLIC_URL/api/auth/oauth2/login}"

# ---- settings: the README variables: list (Apps/gamevault/) ----
# GameVault reads these itself on every start; blank ones are skipped, so
# they mean "default". Database, ports, volumes and the token seed are wired
# up above.
pass_env gamevault 'SERVER_(LOG_LEVEL|LOG_FILES_ENABLED|REGISTRATION_DISABLED|ACCOUNT_ACTIVATION_DISABLED|ADMIN_USERNAME|ADMIN_PASSWORD|MAX_DOWNLOAD_BANDWIDTH_IN_KBPS|ONLINE_ACTIVITIES_DISABLED|CORS_ALLOWED_ORIGINS)'
pass_env gamevault 'USERS_REQUIRE_[A-Z_]+|PARENTAL_[A-Z_]+'
pass_env gamevault 'GAMES_[A-Z_]+|MEDIA_[A-Z_]+|SAVEFILES_MAX_[A-Z_]+|METADATA_[A-Z0-9_]+'
pass_env gamevault 'AUTH_(ACCESS|REFRESH)_TOKEN_EXPIRES_IN|AUTH_(BASIC_AUTH|API_KEY)_ENABLED'
pass_env gamevault 'AUTH_OAUTH2_(ENABLED|SCOPES|AUTH_URL|TOKEN_URL|USERINFO_URL|CLIENT_ID|CLIENT_SECRET)'

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

  # Upstream's "gamevault" user is the Postgres superuser
  # (POSTGRES_USER=gamevault), so it stays one here: its migrations and
  # built-in backups (pg_dump/pg_restore) expect that.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE gamevault LOGIN SUPERUSER PASSWORD '${GAMEVAULT_DB_PASSWORD}';" \
    -c "CREATE DATABASE gamevault OWNER gamevault;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
