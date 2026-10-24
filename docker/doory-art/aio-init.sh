#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each service's
# environment, prepares the database, then hands over to supervisord.
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

# ---- the site's public address (SITE_URL upstream) ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6143}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
ADMIN_PASSWORD_ENV=${ADMIN_PASSWORD:-}

# Doory uid/gid inside the doory-backend image (user "doory").
DOORY_UID=10001
DOORY_GID=10001

# ---- one folder per stateful service under /data ----
#   postgres/  the database
#   media/     uploads, fonts, elements, audio, models (/app/media in the api rootfs)
#   exports/   server-side exports waiting to be downloaded (/app/exports)
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/media" "$DATA/exports"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
NEW_ADMIN_PASSWORD=0
ensure_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -hex "$2")" >> "$SECRETS"
    [ "$1" = ADMIN_PASSWORD ] && NEW_ADMIN_PASSWORD=1
  fi
  return 0
}
secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# PG_PASSWORD: postgres superuser. DOORY_DB_PASSWORD: the "doory" role.
# DJANGO_SECRET_KEY signs sessions; changing it signs everyone out and makes
# stored AI provider secrets unreadable, so it is made once and kept.
# ADMIN_PASSWORD: used for the first admin when ADMIN_PASSWORD is blank.
ensure_secret PG_PASSWORD 16
ensure_secret DOORY_DB_PASSWORD 16
ensure_secret DJANGO_SECRET_KEY 32
ensure_secret ADMIN_PASSWORD 9
PG_PASSWORD=$(secret PG_PASSWORD)
DOORY_DB_PASSWORD=$(secret DOORY_DB_PASSWORD)
DJANGO_SECRET_KEY=$(secret DJANGO_SECRET_KEY)
ADMIN_PASSWORD=$(secret ADMIN_PASSWORD)
if [ -n "$ADMIN_PASSWORD_ENV" ]; then
  ADMIN_PASSWORD=$ADMIN_PASSWORD_ENV
elif [ "$NEW_ADMIN_PASSWORD" = 1 ]; then
  log "first start: admin email is $ADMIN_EMAIL"
  log "first start: admin password is $ADMIN_PASSWORD (also saved in $SECRETS)"
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
# doory-web is the gateway (8080), which serves render.html like upstream's web.
if ! grep -q 'doory-realtime' "$HOSTS"; then
  echo "127.0.0.1 db doory-api doory-realtime doory-mcp doory-web" >> "$HOSTS"
fi

# ---- generic: prepare every chroot filesystem under /opt/rootfs ----
for d in "$ROOTFS"/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
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
  # gunicorn's worker files and Chromium (server-side export) need a big
  # /dev/shm; upstream gives the api container shm_size 512m.
  mkdir -p "$d/dev/shm"
  mountpoint -q "$d/dev/shm" || mount -t tmpfs -o size=512m tmpfs "$d/dev/shm" 2>/dev/null || true
  chmod 1777 "$d/dev/shm" 2>/dev/null || true
  [ -e "$d/dev/fd" ] || ln -s /proc/self/fd "$d/dev/fd" 2>/dev/null || true
  if [ -f "$d/proc/version" ]; then
    log "$d procfs mounted successfully"
  else
    log "WARNING: $d procfs is NOT mounted"
  fi

  # APP-SPECIFIC: the api rootfs keeps its media and exports in /data.
  # Without these mounts the files would live in the image and vanish on update.
  if [ "$name" = api ]; then
    for m in media exports; do
      mkdir -p "$d/app/$m"
      if ! mountpoint -q "$d/app/$m"; then
        mount --bind "$DATA/$m" "$d/app/$m" 2>/dev/null \
          || log "WARNING: could not bind $DATA/$m to $d/app/$m; files will not survive an update"
      fi
    done
  fi

  [ -e "$d/dev/null" ]    || mknod -m 666 "$d/dev/null" c 1 3    2>/dev/null || log "warning: could not create $d/dev/null"
  [ -e "$d/dev/zero" ]    || mknod -m 666 "$d/dev/zero" c 1 5    2>/dev/null || true
  [ -e "$d/dev/random" ]  || mknod -m 666 "$d/dev/random" c 1 8  2>/dev/null || true
  [ -e "$d/dev/urandom" ] || mknod -m 666 "$d/dev/urandom" c 1 9 2>/dev/null || true
  [ -e "$d/dev/stdin" ] || : > "$d/dev/stdin"
  # APP-SPECIFIC: api, realtime and mcp share the api rootfs, so one set of
  # fifos would mix their logs. With /proc mounted, plain links to each
  # process's own fd 1/2 work and need no readers.
  if [ "$name" = api ] && [ -f "$d/proc/version" ]; then
    ln -sfn /proc/self/fd/1 "$d/dev/stdout"
    ln -sfn /proc/self/fd/2 "$d/dev/stderr"
    continue
  fi
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
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 8000 8001 8002 5432 "
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
# pass_env <file> <regex>: copy container variables whose NAME matches the
# regex into /run/aio/<file>.env. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# HTTPS switches follow PUBLIC_URL unless set: on for https:// (behind your
# reverse proxy), off for plain http:// on the local network.
case $PUBLIC_URL in https://*) HTTPS=true ;; *) HTTPS=false ;; esac

# From upstream's docker-compose.yml (api, realtime and mcp share it), with
# the database on 127.0.0.1 and the files under /data.
# DJANGO_ALLOWED_HOSTS defaults to * so the app opens from any address of the
# ZimaOS box; set it to your own host names to restrict it.
# The DOORY_SYNC_* first-run content is on by default here (off upstream), so
# a new install has icons, fonts, templates, audio and the background-removal
# model. A failed download is logged and never stops the server.
COMMON=(
  "$TZV"
  "DJANGO_SETTINGS_MODULE=doory.settings.prod"
  "DJANGO_SECRET_KEY=$DJANGO_SECRET_KEY"
  "SITE_URL=$PUBLIC_URL"
  "CSRF_TRUSTED_ORIGINS=$PUBLIC_URL"
  "DATABASE_URL=postgres://doory:${DOORY_DB_PASSWORD}@127.0.0.1:5432/doory"
  "CACHE_URL=dbcache://doory_cache"
  "MEDIA_ROOT=/app/media"
  "EXPORT_STORAGE_ROOT=/app/exports"
  "EXPORT_RENDER_PAGE_URL=http://127.0.0.1:$GATEWAY_PORT/render.html"
  "REDIS_URL="
  "DJANGO_ALLOWED_HOSTS=${DJANGO_ALLOWED_HOSTS:-*}"
  "SECURE_SSL_REDIRECT=${SECURE_SSL_REDIRECT:-$HTTPS}"
  "SECURE_COOKIES=${SECURE_COOKIES:-$HTTPS}"
  "NUM_PROXIES=${NUM_PROXIES:-1}"
  "VIDEO_ENABLED=${VIDEO_ENABLED:-true}"
  "DOORY_SYNC_ELEMENTS=${DOORY_SYNC_ELEMENTS:-true}"
  "DOORY_SYNC_FONTS=${DOORY_SYNC_FONTS:-true}"
  "DOORY_SEED_TEMPLATES=${DOORY_SEED_TEMPLATES:-true}"
  "DOORY_SYNC_MODELS=${DOORY_SYNC_MODELS:-true}"
  "DOORY_SYNC_AUDIO=${DOORY_SYNC_AUDIO:-true}"
)

write_env api "${COMMON[@]}" \
  "AIO_ADMIN_EMAIL=$ADMIN_EMAIL" \
  "AIO_ADMIN_PASSWORD=$ADMIN_PASSWORD"
write_env realtime "${COMMON[@]}" "HEALTH_PORT=8001" "REALTIME_WORKERS=1"
write_env mcp "${COMMON[@]}" "HEALTH_PORT=8002" "HEALTH_PATH=/mcp/health"

# ---- settings: the compose environment: plus the README variables: list (Apps/doory-art/) ----
# Doory reads all of these itself (doory/settings), and api, realtime and mcp
# load the same settings, so they get the same list. Things the AIO wires up
# above (database, cache, media paths, render page, Redis) are not in it.
pass_env settings 'LOG_LEVEL|WEB_CONCURRENCY|MAX_DESIGNS_PER_USER|MAX_API_TOKENS_PER_USER|USER_STORAGE_QUOTA_BYTES|DJANGO_SECRET_KEY_FALLBACKS|DOORY_(SYNC_[A-Z]+_ARGS|ELEMENTS_BRAND_LOGOS)|EMAIL_URL|EMAIL_SEND_ASYNC|DEFAULT_FROM_EMAIL|GOOGLE_CLIENT_ID|OIDC_[A-Z_]+|UNSPLASH_ACCESS_KEY|(PEXELS|PIXABAY|PEXELS_VIDEO|PIXABAY_VIDEO|FREESOUND)_API_KEY|FREESOUND_LICENSES|STOCK_[A-Z_]+|SERVER_(IMAGE|VIDEO)_EXPORT_ENABLED|SERVER_PDF_ENABLED|EXPORT_(IMAGE_[A-Z_]+|VIDEO_[A-Z_]+|FILENAME_[A-Z]+|MAX_CONCURRENCY|TIMEOUT_SECONDS)|IMAGE_OPTIMIZERS|IMAGE_OPTIMIZER_[A-Z_]+|TINYPNG_API_KEY|KRAKEN_API_(KEY|SECRET)|MAX_VIDEO_[A-Z_]+|VIDEO_(MAX_[A-Z_]+|TRANSCODE_TIMEOUT_SECONDS|DOWNLOAD_DEADLINE_SECONDS|FFMPEG_THREADS)|MCP_ENABLED|MCP_CALLS_PER_MINUTE|MCP_EXPORT_[A-Z_]+|BULK_FILL_MAX_ROWS|URL_IMAGE_UPLOADS|BACKGROUND_REMOVAL_[A-Z_]+|AI_[A-Z0-9_]+'
for s in api realtime mcp; do
  cat "$RUN/settings.env" >> "$RUN/$s.env"
done
rm -f "$RUN/settings.env"

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
# Doory writes media and exports as its own user; the gateway (www-data)
# reads media straight from /data/media, so it must stay world-readable.
chown "$DOORY_UID:$DOORY_GID" "$DATA/media" "$DATA/exports"
chmod 755 "$DATA/media"
chmod 750 "$DATA/exports"

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

  # Upstream's "doory" user is the Postgres superuser (POSTGRES_USER=doory),
  # and the migrations create extensions, so it stays a superuser here.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE doory LOGIN SUPERUSER PASSWORD '${DOORY_DB_PASSWORD}';" \
    -c "CREATE DATABASE doory OWNER doory;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready. Downloading the first-run content can take several minutes."
fi

# Services write files others must read (media for the gateway), so they
# start with the usual umask, not the 077 used for the env files above.
umask 022
exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
