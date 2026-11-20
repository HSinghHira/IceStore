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

# ---- public address: PENPOT_PUBLIC_URI ----
# The backend builds asset links, email links and sign-in redirects from it,
# and the exporter opens it, so it must be the address people type. The
# compose file ships the [ZIMAOS-IP-ADDRESS] placeholder; until it is
# replaced Penpot runs on localhost and other addresses get a note.
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6751}
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
    log "PUBLIC_URL uses localhost, so Penpot only works on this server; set it to http://[ZIMAOS-IP-ADDRESS]:6751 with your IP" ;;
  *) log "Penpot works at $PUBLIC_URL (open it at exactly that address)" ;;
esac

# ---- one folder per stateful service under /data ----
# postgres/ holds every design, assets/ the uploaded images and fonts.
STATE=$DATA/state
ASSETS=$DATA/assets
mkdir -p "$STATE/overrides" "$DATA/postgres" "$ASSETS"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
# PENPOT_SECRET_KEY signs sessions and tokens and is shared by the backend and
# the exporter. MAIL_PASSWORD is the /mail viewer login.
ensure_secret PG_PASSWORD 16
ensure_secret PENPOT_DB_PASSWORD 16
ensure_b64 PENPOT_SECRET_KEY 64
ensure_secret MAIL_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
PENPOT_DB_PASSWORD=$(secret PENPOT_DB_PASSWORD)
MAIL_PASSWORD=$(secret MAIL_PASSWORD)

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
cred_note "Create your account on first visit (Create an account). No email check is needed."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'penpot-backend' "$HOSTS"; then
  echo "127.0.0.1 penpot-frontend penpot-backend penpot-exporter penpot-postgres penpot-valkey penpot-mailpit" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2 uid
  # APP-SPECIFIC: the backend writes uploads to /opt/data/assets and the
  # frontend's nginx serves them from there (upstream shares one volume).
  case $name in
    backend|frontend)
      mkdir -p "$d/opt/data/assets"
      mountpoint -q "$d/opt/data/assets" || mount --bind "$ASSETS" "$d/opt/data/assets"
      if [ "$name" = backend ]; then
        uid=$(awk -F: '$1=="penpot"{print $3":"$4}' "$d/etc/passwd")
        [ -n "$uid" ] && chown -R "$uid" "$ASSETS"
      fi
      ;;
  esac
  # APP-SPECIFIC: the frontend image's nginx listens on 8080, the gateway's
  # port. Move it to 9001 in the template its entrypoint renders.
  if [ "$name" = frontend ] && [ -f "$d/tmp/nginx.conf.template" ]; then
    sed -i -e 's/listen 8080 default_server/listen 9001 default_server/' "$d/tmp/nginx.conf.template"
  fi
  return 0
}
CHROOT_SHM_SIZE=512m
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container (the exporter) reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 1025 5432 6060 6061 6379 8025 8082 9001 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Penpot is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so images, exports and sign-in would point at localhost.\n\nOpen the Penpot app settings in ZimaOS, set PUBLIC_URL to http://$host:6751 and save. The app restarts and then works here.\n";
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

# Flags: upstream's compose set, minus the admin console, MCP and prepl
# server (left out here). Session cookies are only marked Secure on https.
# PENPOT_FLAGS from the app settings is added after these, and in Penpot the
# last enable-/disable- of a name wins.
FLAGS="enable-registration enable-login-with-password disable-email-verification enable-smtp disable-admin-console"
case $PUBLIC_URL in
  https://*) ;;
  *) FLAGS="$FLAGS disable-secure-session-cookies" ;;
esac
[ -n "${PENPOT_FLAGS:-}" ] && FLAGS="$FLAGS $PENPOT_FLAGS"

# Email: blank PENPOT_SMTP_HOST = the built-in mail viewer at /mail.
SMTP_HOST=${PENPOT_SMTP_HOST:-}
if [ -z "$SMTP_HOST" ]; then
  log "no PENPOT_SMTP_HOST set: emails go to the mail viewer at $PUBLIC_URL/mail/"
  SMTP=("PENPOT_SMTP_HOST=127.0.0.1" "PENPOT_SMTP_PORT=1025" "PENPOT_SMTP_TLS=false" "PENPOT_SMTP_SSL=false")
else
  SMTP=("PENPOT_SMTP_HOST=$SMTP_HOST" "PENPOT_SMTP_PORT=${PENPOT_SMTP_PORT:-587}")
fi

# From upstream's docker/images/docker-compose.yaml, with every address on
# 127.0.0.1 and the secrets made above.
write_env backend "$TZV" \
  "PENPOT_FLAGS=$FLAGS" \
  "PENPOT_PUBLIC_URI=$PUBLIC_URL" \
  "PENPOT_SECRET_KEY=$(secret PENPOT_SECRET_KEY)" \
  "PENPOT_DATABASE_URI=postgresql://127.0.0.1:5432/penpot" \
  "PENPOT_DATABASE_USERNAME=penpot" \
  "PENPOT_DATABASE_PASSWORD=$PENPOT_DB_PASSWORD" \
  "PENPOT_REDIS_URI=redis://127.0.0.1:6379/0" \
  "PENPOT_HTTP_SERVER_MAX_BODY_SIZE=367001600" \
  "PENPOT_HTTP_SERVER_MAX_MULTIPART_BODY_SIZE=367001600" \
  "PENPOT_OBJECTS_STORAGE_BACKEND=fs" \
  "PENPOT_OBJECTS_STORAGE_FS_DIRECTORY=/opt/data/assets" \
  "PENPOT_TELEMETRY_ENABLED=${PENPOT_TELEMETRY_ENABLED:-false}" \
  "PENPOT_TELEMETRY_REFERER=icestore" \
  "${SMTP[@]}" \
  "PENPOT_SMTP_DEFAULT_FROM=${PENPOT_SMTP_DEFAULT_FROM:-no-reply@penpot.local}" \
  "PENPOT_SMTP_DEFAULT_REPLY_TO=${PENPOT_SMTP_DEFAULT_REPLY_TO:-no-reply@penpot.local}"

# ---- settings: the README variables: list (Apps/penpot/) ----
# The backend reads these itself on every start; blank ones are skipped, so
# they mean "default". With the mail viewer, SMTP login and TLS are skipped.
if [ -n "$SMTP_HOST" ]; then
  pass_env backend 'PENPOT_SMTP_(USERNAME|PASSWORD|TLS|SSL)'
fi
pass_env backend 'PENPOT_OIDC_[A-Z_]+|PENPOT_GOOGLE_CLIENT_(ID|SECRET)|PENPOT_GITHUB_CLIENT_(ID|SECRET)'
pass_env backend 'PENPOT_GITLAB_(BASE_URI|CLIENT_ID|CLIENT_SECRET)|PENPOT_LDAP_[A-Z_]+'
pass_env backend 'PENPOT_REGISTRATION_DOMAIN_WHITELIST|PENPOT_DEFAULT_QUOTE_[A-Z_]+|PENPOT_QUOTES_[A-Z_]+'

write_env exporter "$TZV" \
  "PENPOT_FLAGS=$FLAGS" \
  "PENPOT_PUBLIC_URI=$PUBLIC_URL" \
  "PENPOT_INTERNAL_URI=http://127.0.0.1:9001" \
  "PENPOT_SECRET_KEY=$(secret PENPOT_SECRET_KEY)" \
  "PENPOT_REDIS_URI=redis://127.0.0.1:6379/0"

# The frontend's entrypoint fills its nginx config from these. Upstream
# proxies to hostnames through a DNS resolver, which never reads /etc/hosts,
# so the backend and exporter are given as 127.0.0.1.
write_env frontend "$TZV" \
  "PENPOT_FLAGS=$FLAGS" \
  "PENPOT_PUBLIC_URI=$PUBLIC_URL" \
  "PENPOT_BACKEND_URI=http://127.0.0.1:6060" \
  "PENPOT_EXPORTER_URI=http://127.0.0.1:6061" \
  "PENPOT_HTTP_SERVER_MAX_BODY_SIZE=367001600" \
  "PENPOT_HTTP_SERVER_WORKER_PROCESSES=2" \
  "PENPOT_HTTP_SERVER_WORKER_CONNECTIONS=4096" \
  "PENPOT_DISABLE_IPV6_LISTEN=true"
pass_env frontend 'PENPOT_OIDC_NAME'

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
pg_setup /usr/lib/postgresql/15/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  # Upstream's POSTGRES_USER=penpot is the superuser; the migrations create
  # extensions, so "penpot" is one here too.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE penpot LOGIN SUPERUSER PASSWORD '${PENPOT_DB_PASSWORD}';" \
    -c "CREATE DATABASE penpot OWNER penpot;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
