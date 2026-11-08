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

# Shared IceStore helpers: log, ensure_secret, secret, cred_add (docker/_common).
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# ---- public address: Tolgee's frontEndUrl. The web app follows the
# ---- browser's own address; this is only used for links in emails and
# ---- for sign-in with GitHub, Google or OAuth2. ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6192}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost:*|*://localhost|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. That is fine on your network; set it to http://<your ZimaOS IP>:6192 for working links in emails." ;;
esac
ADMIN_USERNAME=${TOLGEE_AUTHENTICATION_INITIAL_USERNAME:-admin}
ADMIN_PASSWORD_ENV=${ADMIN_PASSWORD:-}

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/tolgee"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
# Tolgee makes its own JWT secret in its data folder (/data/tolgee/jwt.secret).
ensure_secret PG_PASSWORD 16
ensure_secret ADMIN_PASSWORD 12

PG_PASSWORD=$(secret PG_PASSWORD)
ADMIN_PASSWORD=$(secret ADMIN_PASSWORD)
[ -z "$ADMIN_PASSWORD_ENV" ] || ADMIN_PASSWORD=$ADMIN_PASSWORD_ENV

# ---- CREDENTIALS banner, printed on every boot once Tolgee answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add USERNAME "$ADMIN_USERNAME"
if [ -n "$ADMIN_PASSWORD_ENV" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PASSWORD"
fi
cred_note "Also saved in $SECRETS"
cred_note "Changed it in Tolgee? Your new password is the one that works."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' tolgee-db' "$HOSTS"; then
  echo "127.0.0.1 db tolgee-db app" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: Tolgee keeps uploads, screenshots, its JWT secret and
  # initial.pwd in /data (tolgee.file-storage.fs-data-path).
  if [ "$name" = tolgee ]; then
    mkdir -p "$d/data"
    mountpoint -q "$d/data" || mount --bind "$DATA/tolgee" "$d/data" 2>/dev/null \
      || log "warning: could not mount $DATA/tolgee into the tolgee chroot"
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 8081 5432 "
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
TZV="TZ=${TZ:-UTC}"

# Upstream's "external PostgreSQL" setup: the bundled database is switched
# off and Tolgee uses the one here. Sign-in is on (upstream's Docker image
# turns it off, which makes everyone on the network an admin).
write_env tolgee "$TZV" \
  "SERVER_PORT=8081" \
  "TOLGEE_POSTGRES_AUTOSTART_ENABLED=false" \
  "SPRING_DATASOURCE_URL=jdbc:postgresql://127.0.0.1:5432/tolgee" \
  "SPRING_DATASOURCE_USERNAME=tolgee" \
  "SPRING_DATASOURCE_PASSWORD=$PG_PASSWORD" \
  "TOLGEE_FILE_STORAGE_FS_DATA_PATH=/data" \
  "TOLGEE_FRONT_END_URL=$PUBLIC_URL" \
  "TOLGEE_AUTHENTICATION_ENABLED=${TOLGEE_AUTHENTICATION_ENABLED:-true}" \
  "TOLGEE_AUTHENTICATION_INITIAL_USERNAME=$ADMIN_USERNAME" \
  "TOLGEE_AUTHENTICATION_INITIAL_PASSWORD=$ADMIN_PASSWORD"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional Tolgee setting from the README Variables list, by its own
# name (Spring's TOLGEE_<SECTION>_<KEY> form): sign-up, email, sign-in with
# GitHub, Google or OAuth2, machine translation, JVM memory.
pass_env tolgee 'TOLGEE_AUTHENTICATION_(REGISTRATIONS_ALLOWED|NEEDS_EMAIL_VERIFICATION|USER_CAN_CREATE_ORGANIZATIONS|CREATE_DEMO_FOR_INITIAL_USER|NATIVE_ENABLED|GITHUB_[A-Z_]+|GOOGLE_[A-Z_]+|OAUTH2_[A-Z_]+)|TOLGEE_SMTP_[A-Z_]+|TOLGEE_MACHINE_TRANSLATION_[A-Z_]+|TOLGEE_MAX_UPLOAD_FILE_SIZE|JAVA_OPTS'

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
pg_setup /usr/lib/postgresql/17/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb

  # Tolgee's own role and database. Its migrations create the tables.
  pg_start_local
  pg_psql \
      -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE tolgee LOGIN PASSWORD :'pw';
CREATE DATABASE tolgee OWNER tolgee;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
