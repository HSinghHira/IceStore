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

# ---- public address: NEXT_PUBLIC_WEBAPP_URL and NEXTAUTH_URL ----
# Cal.diy puts this address into every sign-in redirect, booking link and
# email, so it must be the address people type. The compose file ships the
# [ZIMAOS-IP-ADDRESS] placeholder; until it is replaced the app runs on
# localhost and other addresses get a "set PUBLIC_URL" note (guard below).
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6749}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "PUBLIC_URL is still $PUBLIC_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings"
    PUBLIC_URL=${PUBLIC_URL//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
host=${hostport%:*}
case $host in
  localhost|127.0.0.1)
    log "PUBLIC_URL uses localhost, so Cal.diy only works on this server; set it to http://[ZIMAOS-IP-ADDRESS]:6749 with your IP" ;;
  *) log "Cal.diy works at $PUBLIC_URL (open it at exactly that address)" ;;
esac

# ---- one folder per stateful service under /data ----
# Everything (users, bookings, avatars, app keys) is in the database.
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
# NEXTAUTH_SECRET signs sign-ins. CALENDSO_ENCRYPTION_KEY (32 characters)
# encrypts stored calendar and app keys and must never change once used.
# CRON_API_KEY guards the /api/cron endpoints. MAIL_PASSWORD is the /mail
# viewer login.
ensure_secret PG_PASSWORD 16
ensure_secret CAL_DB_PASSWORD 16
ensure_secret NEXTAUTH_SECRET 32
ensure_b64 CALENDSO_ENCRYPTION_KEY 24
ensure_secret CRON_API_KEY 16
ensure_secret MAIL_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
CAL_DB_PASSWORD=$(secret CAL_DB_PASSWORD)
MAIL_PASSWORD=$(secret MAIL_PASSWORD)

# Mail viewer (/mail) login: blank MP_UI_AUTH = user "admin" with a made
# password, kept in the data folder. A value you set wins.
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
  cred_add "MAIL VIEWER" "$SHOW_URL/mail/  (the login you set in MP_UI_AUTH)"
else
  cred_add "MAIL VIEWER" "$SHOW_URL/mail/  admin / $MAIL_PASSWORD"
  cred_note "Mail viewer login also saved in $MAIL_LOGIN_FILE"
fi
cred_note "First visit: the setup page makes the first admin account."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'calcom-api' "$HOSTS"; then
  echo "127.0.0.1 database redis calcom calcom-api mailpit" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
# Both chroot services are stateless (Cal.diy keeps everything in Postgres).
chroot_extra() {
  local d=$1 name=$2
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 1025 3000 5432 8025 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

# host is localhost: anyone on another address gets a note, not a redirect
# to localhost they cannot follow.
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Cal.diy is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so sign-in and booking links would send you to localhost.\n\nOpen the Cal.diy app settings in ZimaOS, set PUBLIC_URL to http://$host:6749 and save. The app restarts and then works here.\n";
}
EOF
    ;;
  *) : > "$GUARD_FILE" ;;
esac
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@GUARD_FILE@/$(sed_escape "$GUARD_FILE")/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# Email: blank EMAIL_SERVER_HOST = the built-in mail viewer at /mail (nothing
# leaves the box). With a real server, the port defaults to 587.
SMTP_HOST=${EMAIL_SERVER_HOST:-}
if [ -z "$SMTP_HOST" ]; then
  log "no EMAIL_SERVER_HOST set: emails go to the mail viewer at $PUBLIC_URL/mail/"
  SMTP=("EMAIL_SERVER_HOST=127.0.0.1" "EMAIL_SERVER_PORT=1025"
        "EMAIL_SERVER_USER=cal" "EMAIL_SERVER_PASSWORD=cal")
else
  SMTP=("EMAIL_SERVER_HOST=$SMTP_HOST" "EMAIL_SERVER_PORT=${EMAIL_SERVER_PORT:-587}")
fi

DB_URL="postgresql://calcom:$CAL_DB_PASSWORD@127.0.0.1:5432/calendso"

# From upstream's docker-compose.yml and .env.example, with the database on
# 127.0.0.1 and every secret made above. start.sh swaps the built
# http://localhost:3000 for NEXT_PUBLIC_WEBAPP_URL and waits for DATABASE_HOST.
write_env calcom "$TZV" \
  "NODE_ENV=production" \
  "PORT=3000" \
  "NEXT_PUBLIC_WEBAPP_URL=$PUBLIC_URL" \
  "NEXTAUTH_URL=$PUBLIC_URL" \
  "NEXT_PUBLIC_WEBSITE_URL=$PUBLIC_URL" \
  "NEXT_PUBLIC_EMBED_LIB_URL=$PUBLIC_URL/embed/embed.js" \
  "NEXT_PUBLIC_LICENSE_CONSENT=agree" \
  "NEXTAUTH_SECRET=$(secret NEXTAUTH_SECRET)" \
  "CALENDSO_ENCRYPTION_KEY=$(secret CALENDSO_ENCRYPTION_KEY)" \
  "CRON_API_KEY=$(secret CRON_API_KEY)" \
  "DATABASE_HOST=127.0.0.1:5432" \
  "DATABASE_URL=$DB_URL" \
  "DATABASE_DIRECT_URL=$DB_URL" \
  "CALCOM_TELEMETRY_DISABLED=${CALCOM_TELEMETRY_DISABLED:-1}" \
  "${SMTP[@]}" \
  "EMAIL_FROM=${EMAIL_FROM:-notifications@cal.local}" \
  "EMAIL_FROM_NAME=${EMAIL_FROM_NAME:-Cal.diy}"

# ---- settings: the README variables: list (Apps/cal-diy/) ----
# Cal.diy reads these itself on every start; blank ones are skipped, so they
# mean "default". With the mail viewer, SMTP user and password are skipped.
if [ -n "$SMTP_HOST" ]; then
  pass_env calcom 'EMAIL_SERVER_(USER|PASSWORD)'
fi
pass_env calcom 'GOOGLE_API_CREDENTIALS|GOOGLE_LOGIN_ENABLED|OUTLOOK_LOGIN_ENABLED|MS_GRAPH_CLIENT_(ID|SECRET)'
pass_env calcom 'ZOOM_CLIENT_(ID|SECRET)|DAILY_API_KEY|DAILY_SCALE_PLAN'
pass_env calcom 'BLACKLISTED_GUEST_EMAILS|ALLOWED_HOSTNAMES|NEXTAUTH_COOKIE_DOMAIN|RESEND_API_KEY'

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
pg_setup /usr/lib/postgresql/17/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums

  # Upstream's POSTGRES_USER owns the database and is a superuser; Prisma's
  # migrations expect that, so "calcom" is one here too.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE calcom LOGIN SUPERUSER PASSWORD '${CAL_DB_PASSWORD}';" \
    -c "CREATE DATABASE calendso OWNER calcom;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
