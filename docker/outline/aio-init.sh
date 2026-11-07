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
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# ---- public address: Outline's URL (links, sign-in callbacks, cookies) ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6155}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. Outline only works at exactly this address;"
    log "set PUBLIC_URL to the address you open Outline at, like http://192.168.1.20:6155" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/redis" "$DATA/storage"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----

# PG_PASSWORD: postgres superuser. OUTLINE_DB_PASSWORD: the "outline" role.
# SECRET_KEY (32 bytes hex, as Outline wants) and UTILS_SECRET sign sessions
# and links; changing them signs everyone out. MAIL_PASSWORD is the /mail
# viewer login.
ensure_secret PG_PASSWORD 16
ensure_secret OUTLINE_DB_PASSWORD 16
ensure_secret SECRET_KEY 32
ensure_secret UTILS_SECRET 32
ensure_secret MAIL_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
OUTLINE_DB_PASSWORD=$(secret OUTLINE_DB_PASSWORD)
MAIL_PASSWORD=$(secret MAIL_PASSWORD)

# Mail viewer (/mail) login. It shows sign-in links, so it is never open:
# blank MP_UI_AUTH = user "admin" with a password made on first start, kept in
# the data folder. A value you set wins.
MAIL_LOGIN_FILE=$DATA/mail-password.txt
MAIL_UI_AUTH=${MP_UI_AUTH:-}
if [ -z "$MAIL_UI_AUTH" ]; then
  MAIL_UI_AUTH="admin:$MAIL_PASSWORD"
  if [ ! -s "$MAIL_LOGIN_FILE" ]; then
    printf 'Mail viewer (/mail) login\nusername: admin\npassword: %s\n' "$MAIL_PASSWORD" > "$MAIL_LOGIN_FILE"
    chmod 600 "$MAIL_LOGIN_FILE"
  fi
fi

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
SHOW_URL=$(cred_url "$PUBLIC_URL")
cred_reset
cred_add URL "$SHOW_URL"
if [ -n "${MP_UI_AUTH:-}" ]; then
  cred_add "MAIL VIEWER" "$SHOW_URL/mail  (the login you set in MP_UI_AUTH)"
else
  cred_add "MAIL VIEWER" "$SHOW_URL/mail  admin / $MAIL_PASSWORD"
  cred_note "Mail viewer login also saved in $MAIL_LOGIN_FILE"
fi
cred_note "Sign in with your email on first visit; the sign-in link lands in the mail viewer."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'outline-mailpit' "$HOSTS"; then
  echo "127.0.0.1 postgres redis outline outline-mailpit" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: /data/storage is Outline's /var/lib/outline/data (uploads,
  # avatars and attachments, upstream's volume), owned by the image's
  # "nodejs" user.
  if [ "$(basename "$d")" = outline ]; then
    mkdir -p "$d/var/lib/outline/data"
    if ! mountpoint -q "$d/var/lib/outline/data"; then
      mount --bind "$DATA/storage" "$d/var/lib/outline/data" 2>/dev/null \
        || log "WARNING: could not bind $DATA/storage to $d/var/lib/outline/data; uploads would be lost on update"
    fi
    uid=$(awk -F: '$1=="nodejs"{print $3":"$4}' "$d/etc/passwd" 2>/dev/null || true)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/storage" 2>/dev/null || true
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
INTERNAL_PORTS=" 1025 3000 5432 6379 8025 "
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

# Email: with no SMTP_HOST or SMTP_SERVICE, emails (sign-in links, invites)
# go to the built-in mail viewer at /mail and nothing leaves the box. That
# also turns on Outline's email sign-in, so it works without Google, Slack or
# OIDC.
MAILVIEWER=0
if [ -z "${SMTP_HOST:-}" ] && [ -z "${SMTP_SERVICE:-}" ]; then
  log "no SMTP_HOST set: emails go to the mail viewer at $PUBLIC_URL/mail/"
  MAILVIEWER=1
  SMTP=("SMTP_HOST=127.0.0.1" "SMTP_PORT=1025" "SMTP_SECURE=false" "SMTP_DISABLE_STARTTLS=true")
else
  SMTP=()
fi

# HTTPS is done by your reverse proxy, if you have one. Outline's own https
# redirect (FORCE_HTTPS) is off by default here, or plain-http use on your
# network would not work.
FORCE_HTTPS_V=${FORCE_HTTPS:-false}

# From upstream's .env.sample, with Postgres and Redis on 127.0.0.1, files
# in /data/storage and the secrets made above.
write_env outline "$TZV" \
  "NODE_ENV=production" \
  "HOME=/home/nodejs" \
  "PORT=3000" \
  "URL=$PUBLIC_URL" \
  "SECRET_KEY=$(secret SECRET_KEY)" \
  "UTILS_SECRET=$(secret UTILS_SECRET)" \
  "DATABASE_URL=postgres://outline:$OUTLINE_DB_PASSWORD@127.0.0.1:5432/outline" \
  "PGSSLMODE=disable" \
  "REDIS_URL=redis://127.0.0.1:6379" \
  "FILE_STORAGE=${FILE_STORAGE:-local}" \
  "FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data" \
  "FORCE_HTTPS=$FORCE_HTTPS_V" \
  "DEFAULT_LANGUAGE=${DEFAULT_LANGUAGE:-en_US}" \
  "SMTP_FROM_EMAIL=${SMTP_FROM_EMAIL:-noreply@outline.local}" \
  "${SMTP[@]}"

# ---- settings: the README variables: list (Apps/outline/) ----
# Outline reads these itself on every start; blank ones are skipped, so they
# mean "default". With the mail viewer, the SMTP login and TLS settings are
# skipped: it needs none of them.
if [ "$MAILVIEWER" = 0 ]; then
  pass_env outline 'SMTP_(HOST|SERVICE|PORT|USERNAME|PASSWORD|SECURE|DISABLE_STARTTLS|NAME|REPLY_EMAIL|TLS_CIPHERS)'
fi
pass_env outline '(SLACK|GOOGLE|AZURE|DISCORD|OIDC)_[A-Z_]+'
pass_env outline '(GITHUB|GITLAB|LINEAR|FIGMA|NOTION|IFRAMELY)_[A-Z_]+|DROPBOX_APP_KEY'
pass_env outline 'FILE_STORAGE_(UPLOAD|IMPORT|WORKSPACE_IMPORT)_MAX_SIZE|AWS_[A-Z0-9_]+'
pass_env outline 'RATE_LIMITER_[A-Z_]+|WEB_CONCURRENCY|ENABLE_UPDATES|LOG_LEVEL|DEBUG'

write_env mailpit "$TZV" \
  "MP_SMTP_AUTH_ACCEPT_ANY=1" \
  "MP_SMTP_AUTH_ALLOW_INSECURE=1" \
  "MP_SMTP_BIND_ADDR=127.0.0.1:1025" \
  "MP_UI_BIND_ADDR=127.0.0.1:8025" \
  "MP_WEBROOT=/mail/" \
  "MP_UI_AUTH=$MAIL_UI_AUTH"
pass_env mailpit 'MP_MAX_MESSAGES'

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
pg_setup /usr/lib/postgresql/16/bin
chown redis:redis "$DATA/redis"

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums

  # Upstream's "outline" user is the Postgres superuser (POSTGRES_USER=outline),
  # so it stays one here: its migrations create extensions.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE outline LOGIN SUPERUSER PASSWORD '${OUTLINE_DB_PASSWORD}';" \
    -c "CREATE DATABASE outline OWNER outline;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
