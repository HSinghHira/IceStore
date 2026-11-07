#!/bin/bash
# First thing that runs in the container. Makes secrets and the signing
# certificate, writes each service's environment, prepares the database, then
# hands over to supervisord.
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

# ---- public address: Documenso's NEXT_PUBLIC_WEBAPP_URL (links in emails) ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6142}
PUBLIC_URL=${PUBLIC_URL%/}
# The compose file ships http://[SERVER-IP]:6142 as a fill-in-the-blank. Left
# as is, it is not a valid address, so fall back to localhost (works on the
# server itself) and say what to change.
case $PUBLIC_URL in
  *"[SERVER-IP]"*|*SERVER-IP*)
    log "WARNING: PUBLIC_URL still has [SERVER-IP] in it. Replace it with your server's IP in the app settings."
    PUBLIC_URL=http://localhost:6142 ;;
esac
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
# Documenso's browser code calls PUBLIC_URL for sign-in, and its CSRF check
# refuses any form sent from another address, so it only works at exactly
# this address.
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "WARNING: PUBLIC_URL is $PUBLIC_URL. Documenso only works at exactly that address,"
    log "WARNING: so from another device sign-up and sign-in fail with 'Failed to fetch'."
    log "WARNING: Set PUBLIC_URL to the address you type in the browser, like http://192.168.1.20:6142" ;;
  *) log "Documenso works only at $PUBLIC_URL (open it at exactly that address)" ;;
esac

# ---- one folder per stateful service under /data ----
# Documents live in the database (upload transport "database"), so postgres/
# holds everything. cert/ holds the signing certificate.
STATE=$DATA/state
CERT_DIR=$DATA/cert
mkdir -p "$STATE/overrides" "$DATA/postgres" "$CERT_DIR"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----

# PG_PASSWORD: postgres superuser. DOCUMENSO_DB_PASSWORD: the "documenso" role.
# NEXTAUTH_SECRET signs sign-ins. The two encryption keys encrypt stored data
# and must never change once used, so they are made once and kept.
# SIGNING_PASSPHRASE protects the generated cert.p12. MAIL_PASSWORD is the
# /mail viewer login.
ensure_secret PG_PASSWORD 16
ensure_secret DOCUMENSO_DB_PASSWORD 16
ensure_secret NEXTAUTH_SECRET 32
ensure_secret ENCRYPTION_KEY 32
ensure_secret ENCRYPTION_SECONDARY_KEY 32
ensure_secret SIGNING_PASSPHRASE 16
ensure_secret MAIL_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
DOCUMENSO_DB_PASSWORD=$(secret DOCUMENSO_DB_PASSWORD)
MAIL_PASSWORD=$(secret MAIL_PASSWORD)

# ---- signing certificate: /data/cert/cert.p12 ----
# Made once (self-signed, 10 years) the way Documenso's docs show. To use your
# own, replace the file and set NEXT_PRIVATE_SIGNING_PASSPHRASE to its passphrase.
CERT=$CERT_DIR/cert.p12
SIGNING_PASSPHRASE=${NEXT_PRIVATE_SIGNING_PASSPHRASE:-$(secret SIGNING_PASSPHRASE)}
make_cert() {
  local tmp rc=0
  tmp=$(mktemp -d)
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
      -subj "/CN=Documenso self-hosted signing" \
      -keyout "$tmp/private.key" -out "$tmp/certificate.crt" 2>/dev/null \
    && { openssl pkcs12 -export -legacy -out "$CERT" -inkey "$tmp/private.key" -in "$tmp/certificate.crt" \
           -passout "pass:$SIGNING_PASSPHRASE" 2>/dev/null \
         || openssl pkcs12 -export -out "$CERT" -inkey "$tmp/private.key" -in "$tmp/certificate.crt" \
           -passout "pass:$SIGNING_PASSPHRASE"; } \
    || rc=1
  rm -rf "$tmp"
  return $rc
}
if [ ! -s "$CERT" ]; then
  log "first start: making a self-signed signing certificate in $CERT"
  # Documenso still starts without one; only signing is unavailable.
  make_cert || { rm -f "$CERT"; log "WARNING: could not make $CERT; documents cannot be signed until it exists"; }
fi
# Documenso runs as uid 1001 (nodejs) and must be able to read it, also when
# you dropped in your own file.
chown -R 1001:1001 "$CERT_DIR" 2>/dev/null || true
chmod 600 "$CERT" 2>/dev/null || true

# Mail viewer (/mail) login. It shows sign-up and password-reset emails, so it
# is never open: blank MP_UI_AUTH = user "admin" with a password made on first
# start, kept in the data folder. A value you set wins.
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
cred_note "Create your account on first visit; sign-up emails land in the mail viewer."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'documenso-mailpit' "$HOSTS"; then
  echo "127.0.0.1 database documenso documenso-mailpit" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: /data/cert is Documenso's /opt/documenso, where it looks for
  # cert.p12 (upstream mounts the file there too).
  if [ "$(basename "$d")" = documenso ]; then
    mkdir -p "$d/opt/documenso"
    if ! mountpoint -q "$d/opt/documenso"; then
      mount --bind "$CERT_DIR" "$d/opt/documenso" 2>/dev/null \
        || log "WARNING: could not bind $CERT_DIR to $d/opt/documenso; signing will not work"
    fi
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
INTERNAL_PORTS=" 1025 3000 5432 8025 "
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

# Email: blank NEXT_PRIVATE_SMTP_HOST = the built-in mail viewer at /mail
# (nothing leaves the box). With a real server, the port defaults to 587.
# Another transport (resend, smtp-api, mailchannels) is used as you set it.
SMTP_TRANSPORT=${NEXT_PRIVATE_SMTP_TRANSPORT:-smtp-auth}
SMTP_HOST=${NEXT_PRIVATE_SMTP_HOST:-}
if [ "$SMTP_TRANSPORT" = smtp-auth ] && [ -z "$SMTP_HOST" ]; then
  log "no NEXT_PRIVATE_SMTP_HOST set: emails go to the mail viewer at $PUBLIC_URL/mail/"
  SMTP=("NEXT_PRIVATE_SMTP_HOST=127.0.0.1" "NEXT_PRIVATE_SMTP_PORT=1025"
        "NEXT_PRIVATE_SMTP_SECURE=false" "NEXT_PRIVATE_SMTP_UNSAFE_IGNORE_TLS=true")
else
  SMTP=("NEXT_PRIVATE_SMTP_HOST=$SMTP_HOST" "NEXT_PRIVATE_SMTP_PORT=${NEXT_PRIVATE_SMTP_PORT:-587}")
fi

# From upstream's docker/production/compose.yml and .env.example, with the
# database on 127.0.0.1 and every secret made above.
write_env documenso "$TZV" \
  "NODE_ENV=production" \
  "PORT=3000" \
  "NEXTAUTH_SECRET=$(secret NEXTAUTH_SECRET)" \
  "NEXT_PRIVATE_ENCRYPTION_KEY=$(secret ENCRYPTION_KEY)" \
  "NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=$(secret ENCRYPTION_SECONDARY_KEY)" \
  "NEXT_PUBLIC_WEBAPP_URL=$PUBLIC_URL" \
  "NEXT_PRIVATE_INTERNAL_WEBAPP_URL=http://localhost:3000" \
  "NEXT_PRIVATE_DATABASE_URL=postgresql://documenso:$DOCUMENSO_DB_PASSWORD@127.0.0.1:5432/documenso" \
  "NEXT_PRIVATE_DIRECT_DATABASE_URL=postgresql://documenso:$DOCUMENSO_DB_PASSWORD@127.0.0.1:5432/documenso" \
  "NEXT_PRIVATE_SIGNING_TRANSPORT=local" \
  "NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH=/opt/documenso/cert.p12" \
  "NEXT_PRIVATE_SIGNING_PASSPHRASE=$SIGNING_PASSPHRASE" \
  "NEXT_PRIVATE_SMTP_TRANSPORT=$SMTP_TRANSPORT" \
  "${SMTP[@]}" \
  "NEXT_PRIVATE_SMTP_FROM_NAME=${NEXT_PRIVATE_SMTP_FROM_NAME:-Documenso}" \
  "NEXT_PRIVATE_SMTP_FROM_ADDRESS=${NEXT_PRIVATE_SMTP_FROM_ADDRESS:-noreply@documenso.local}"

# ---- settings: the README variables: list (Apps/documenso/) ----
# Documenso reads these itself on every start; blank ones are skipped, so they
# mean "default". The database, secrets, URLs, signing and SMTP host/port/
# sender are wired up above. With the mail viewer, SMTP user, password and TLS
# settings are skipped: it needs none of them.
if [ "${SMTP[0]}" != "NEXT_PRIVATE_SMTP_HOST=127.0.0.1" ]; then
  pass_env documenso 'NEXT_PRIVATE_SMTP_(USERNAME|PASSWORD|SECURE|UNSAFE_IGNORE_TLS|SERVICE|APIKEY_USER|APIKEY)'
fi
pass_env documenso 'NEXT_PRIVATE_RESEND_API_KEY|NEXT_PRIVATE_MAILCHANNELS_[A-Z_]+'
pass_env documenso 'NEXT_PRIVATE_(GOOGLE|MICROSOFT|OIDC)_[A-Z_]+|NEXT_PUBLIC_DISABLE_[A-Z_]+|NEXT_PRIVATE_ALLOWED_SIGNUP_DOMAINS'
pass_env documenso 'NEXT_PRIVATE_SIGNING_(TIMESTAMP_AUTHORITY|REASON)|NEXT_PUBLIC_SIGNING_CONTACT_INFO|NEXT_PRIVATE_USE_LEGACY_SIGNING_SUBFILTER'
pass_env documenso 'NEXT_PUBLIC_UPLOAD_TRANSPORT|NEXT_PRIVATE_UPLOAD_[A-Z_]+|NEXT_PUBLIC_DOCUMENT_SIZE_UPLOAD_LIMIT'
pass_env documenso 'NEXT_PRIVATE_DOCUMENT_CONVERSION_[A-Z_]+|NEXT_PRIVATE_WEBHOOK_SSRF_BYPASS_HOSTS'
pass_env documenso 'NEXT_PUBLIC_TURNSTILE_SITE_KEY|NEXT_PRIVATE_TURNSTILE_SECRET_KEY|GOOGLE_VERTEX_[A-Z_]+'
pass_env documenso 'DOCUMENSO_DISABLE_TELEMETRY|NEXT_PRIVATE_DOCUMENSO_LICENSE_KEY'

write_env mailpit "$TZV" \
  "MP_SMTP_AUTH_ACCEPT_ANY=1" \
  "MP_SMTP_AUTH_ALLOW_INSECURE=1" \
  "MP_SMTP_BIND_ADDR=127.0.0.1:1025" \
  "MP_UI_BIND_ADDR=127.0.0.1:8025" \
  "MP_WEBROOT=/mail/" \
  "MP_UI_AUTH=$MAIL_UI_AUTH"
pass_env mailpit 'MP_MAX_MESSAGES'

# The admin job (built-in, see run-svc.sh) reads only this.
write_env admin "DOCUMENSO_ADMIN_EMAIL=${DOCUMENSO_ADMIN_EMAIL:-}"

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

  # Upstream's "documenso" user is the Postgres superuser (POSTGRES_USER=documenso),
  # so it stays a superuser here and the Prisma migrations behave the same.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE documenso LOGIN SUPERUSER PASSWORD '${DOCUMENSO_DB_PASSWORD}';" \
    -c "CREATE DATABASE documenso OWNER documenso;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
