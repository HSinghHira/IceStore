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

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

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

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
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

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "Register on first visit; the first account becomes the admin."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

# ---- built-in data folders and first-start database ----
pg_setup /usr/lib/postgresql/16/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums

  # Upstream's "gamevault" user is the Postgres superuser
  # (POSTGRES_USER=gamevault), so it stays one here: its migrations and
  # built-in backups (pg_dump/pg_restore) expect that.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE gamevault LOGIN SUPERUSER PASSWORD '${GAMEVAULT_DB_PASSWORD}';" \
    -c "CREATE DATABASE gamevault OWNER gamevault;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
