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

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

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
# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add EMAIL "$ADMIN_EMAIL"
if [ -n "$ADMIN_PASSWORD_ENV" ]; then
  ADMIN_PASSWORD=$ADMIN_PASSWORD_ENV
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PASSWORD"
  cred_note "Also saved in $SECRETS"
fi
cred_note "Changed it in Doory? Your new password is the one that works."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
# doory-web is the gateway (8080), which serves render.html like upstream's web.
if ! grep -q 'doory-realtime' "$HOSTS"; then
  echo "127.0.0.1 db doory-api doory-realtime doory-mcp doory-web" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
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
  return 0
}
# gunicorn's worker files and Chromium (server-side export) need a big
# /dev/shm; upstream gives the api container shm_size 512m.
CHROOT_SHM_SIZE=512m
prep_chroots
# APP-SPECIFIC: api, realtime and mcp share the api rootfs, so one set of
# fifos would mix their logs. With /proc mounted, plain links to each
# process's own fd 1/2 work and need no readers.
if [ -f "$ROOTFS/api/proc/version" ]; then
  ln -sfn /proc/self/fd/1 "$ROOTFS/api/dev/stdout"
  ln -sfn /proc/self/fd/2 "$ROOTFS/api/dev/stderr"
fi

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

pg_setup /usr/lib/postgresql/16/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums

  # Upstream's "doory" user is the Postgres superuser (POSTGRES_USER=doory),
  # and the migrations create extensions, so it stays a superuser here.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE doory LOGIN SUPERUSER PASSWORD '${DOORY_DB_PASSWORD}';" \
    -c "CREATE DATABASE doory OWNER doory;"
  pg_stop_local
  log "first start: database ready. Downloading the first-run content can take several minutes."
fi

# Services write files others must read (media for the gateway), so they
# start with the usual umask, not the 077 used for the env files above.
umask 022
exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
