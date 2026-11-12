#!/bin/bash
# IceStore start script for OpenSignup. Makes this install's secrets, fills
# the site settings into the build, writes the gateway config, creates the
# database on first start, then hands over to supervisord (postgres, mailpit,
# web, worker, gateway).
set -euo pipefail

DATA=${AIO_DATA:-/data}
APP=${AIO_APP:-/app}
PRISTINE=${AIO_PRISTINE:-/opt/opensignup/next}
FILL=${AIO_FILL:-/opt/opensignup/fill-public.mjs}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/icestore.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/icestore.conf}
GATEWAY_PORT=8080
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

STATE=$DATA/state
mkdir -p "$STATE" "$DATA/postgres" "$DATA/mail"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"
# PG_PASSWORD: the postgres superuser. DB_PASSWORD: the "signup" role.
# AUTH_SECRET signs sign-in sessions and participants' edit links (upstream
# wants 32+ characters). MAIL_PASSWORD: the /mail viewer login.
ensure_secret PG_PASSWORD 16
ensure_secret DB_PASSWORD 16
ensure_secret AUTH_SECRET 32
ensure_secret MAIL_PASSWORD 12
PG_PASSWORD=$(secret PG_PASSWORD)
DB_PASSWORD=$(secret DB_PASSWORD)

# Blank settings from the app settings mean "use the default".
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do unset "$v"; done

# ---- public address: sign-in links, share links and email links use it ----
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6727}
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
log "OpenSignup's address is $PUBLIC_URL (sign-in and share links point there)"

# ---- environment for every program (supervisord passes it on) ----
# From upstream's .env.example and docker-compose.prod.yml, with the database
# inside this container.
export NODE_ENV=production
export DATABASE_URL="postgres://signup:${DB_PASSWORD}@127.0.0.1:5432/signup"
export AUTH_SECRET=$(secret AUTH_SECRET)
export AUTH_URL=$PUBLIC_URL
export NEXT_PUBLIC_APP_URL=$PUBLIC_URL
export AUTH_MAGIC_LINK_MAX_AGE_MINUTES=${AUTH_MAGIC_LINK_MAX_AGE_MINUTES:-60}

# Email. Nothing set = the built-in mail viewer at /mail (nothing leaves the
# box). SMTP_HOST set = your mail server. RESEND_API_KEY set = Resend.
# EMAIL_TRANSPORT set = exactly that.
MAIL_VIEWER=0
if [ -z "${EMAIL_TRANSPORT:-}" ]; then
  if [ -n "${SMTP_HOST:-}" ]; then EMAIL_TRANSPORT=smtp
  elif [ -n "${RESEND_API_KEY:-}" ]; then EMAIL_TRANSPORT=resend
  else MAIL_VIEWER=1
  fi
fi
if [ "$MAIL_VIEWER" = 1 ]; then
  log "no SMTP_HOST set: sign-in and reminder emails go to the mail viewer at $PUBLIC_URL/mail/"
  export EMAIL_TRANSPORT=smtp SMTP_HOST=127.0.0.1 SMTP_PORT=1025 SMTP_SECURE=false SMTP_REQUIRE_TLS=false
  unset SMTP_USER SMTP_PASSWORD
else
  export EMAIL_TRANSPORT
  if [ "$EMAIL_TRANSPORT" = smtp ]; then export SMTP_PORT=${SMTP_PORT:-587}; fi
  log "emails are sent with $EMAIL_TRANSPORT"
fi
export EMAIL_FROM=${EMAIL_FROM:-OpenSignup <noreply@opensignup.local>}
# OpenSignup reads these itself from the container environment when set
# (blank ones were unset above, so they mean "default"): RESEND_API_KEY
# SMTP_USER SMTP_PASSWORD SMTP_SECURE SMTP_REQUIRE_TLS GOOGLE_CLIENT_ID
# GOOGLE_CLIENT_SECRET LLM_BASE_URL LLM_API_KEY LLM_MODEL LLM_TIMEOUT_MS
# OAUTH_STATIC_CLIENTS

# ---- site settings baked into the build: filled in from the app settings ----
# Quotes, backslashes, < > and backticks are dropped and ' becomes ’, so the
# values are safe in the built JavaScript and HTML.
clean() { printf '%s' "$1" | tr -d '"\\<>`\r\n' | sed "s/'/’/g"; }
export NEXT_PUBLIC_INSTANCE_NAME=$(clean "${NEXT_PUBLIC_INSTANCE_NAME:-OpenSignup}")
export NEXT_PUBLIC_SUPPORT_EMAIL=$(clean "${NEXT_PUBLIC_SUPPORT_EMAIL:-support@opensignup.local}")
DEFAULT_LAW="the laws of the place where the operator of this site lives"
export NEXT_PUBLIC_GOVERNING_LAW=$(clean "${NEXT_PUBLIC_GOVERNING_LAW:-$DEFAULT_LAW}")
NEXT_PUBLIC_OPERATOR_NAME=$(clean "${NEXT_PUBLIC_OPERATOR_NAME:-}")
if [ -n "$NEXT_PUBLIC_OPERATOR_NAME" ]; then export NEXT_PUBLIC_OPERATOR_NAME; else unset NEXT_PUBLIC_OPERATOR_NAME; fi
PUBLIC_URL_CLEAN=$(clean "$PUBLIC_URL")
FILL_PAIRS="[[\"http://icestore-opensignup-app-url.invalid\",\"$PUBLIC_URL_CLEAN\"],\
[\"icestore-opensignup-app-url.invalid\",\"$(clean "$hostport")\"],\
[\"IcestoreOpenSignupInstanceName\",\"$NEXT_PUBLIC_INSTANCE_NAME\"],\
[\"support@icestore-opensignup-support.invalid\",\"$NEXT_PUBLIC_SUPPORT_EMAIL\"],\
[\"IcestoreOpenSignupGoverningLaw\",\"$NEXT_PUBLIC_GOVERNING_LAW\"],\
[\"IcestoreOpenSignupOperatorName\",\"${NEXT_PUBLIC_OPERATOR_NAME:-}\"]]"
export FILL_PAIRS

# ---- mail viewer login: blank MP_UI_AUTH = admin with a password made on
# ---- first start. It shows sign-in links, so it is never open. ----
export MP_UI_AUTH=${MP_UI_AUTH:-admin:$(secret MAIL_PASSWORD)}

# ---- gateway: the "set PUBLIC_URL" note for other addresses while
# ---- PUBLIC_URL is on localhost, and the PUBLIC_URL port inside ----
GUARD_FILE=$(dirname "$NGINX_OUT")/icestore-guard.conf
case $host in
  localhost|127.0.0.1) cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "OpenSignup is not set up yet.\n\nOpen the app settings in ZimaOS, set PUBLIC_URL to http://$host:6727 (the address you typed) and save.\nSign-in links and share links use that address, so it must be the one people can reach.\n";
}
EOF
    ;;
  *) : > "$GUARD_FILE" ;;
esac
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 1025 3000 5432 8025 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; calls to $PUBLIC_URL from inside may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;" ;;
  esac
fi
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@GUARD_FILE@/$(sed_escape "$GUARD_FILE")/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- CREDENTIALS banner, printed on every start once the app answers ----
SHOW_URL=$(cred_url "$PUBLIC_URL")
cred_reset
cred_add URL "$SHOW_URL"
if [ "$MAIL_VIEWER" = 1 ]; then
  case $MP_UI_AUTH in
    "admin:$(secret MAIL_PASSWORD)") cred_add "MAIL VIEWER" "$SHOW_URL/mail/  admin / $(secret MAIL_PASSWORD)" ;;
    *) cred_add "MAIL VIEWER" "$SHOW_URL/mail/  (the login you set in MP_UI_AUTH)" ;;
  esac
  cred_note "Sign in with any email address; the sign-in link lands in the mail viewer."
else
  cred_note "Sign in with your email address; the sign-in link is emailed to you."
fi
cred_note "Participants need no account: share a signup's link with them."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  env | grep -E '^(NODE_ENV|AUTH_URL|NEXT_PUBLIC_|EMAIL_|SMTP_|RESEND_|GOOGLE_|LLM_|OAUTH_|DATABASE_URL|MP_)' \
    | sed -e 's/\(PASSWORD\|SECRET\|KEY\|AUTH\)=.*/\1=***/' -e 's/signup:[0-9a-f]*@/signup:***@/'
  log "dry run finished"
  exit 0
fi

# ---- the build with this install's settings in /app/.next ----
SIG=$(printf '%s\n%s\n' "$FILL_PAIRS" "$(stat -c %Y "$PRISTINE")" | sha256sum | cut -d' ' -f1)
if [ "$(cat "$APP/.next/.icestore-filled" 2>/dev/null)" != "$SIG" ]; then
  rm -rf "$APP/.next"
  cp -a "$PRISTINE" "$APP/.next"
  node "$FILL" "$APP/.next"
  echo "$SIG" > "$APP/.next/.icestore-filled"
  chown -R signup:signup "$APP/.next"
fi

chown -R signup:signup "$DATA/mail"

# ---- first start: the database (upstream's POSTGRES_USER/DB signup) ----
pg_setup /usr/libexec/postgresql16
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE ROLE signup LOGIN PASSWORD '${DB_PASSWORD}';" \
          -c "CREATE DATABASE signup OWNER signup;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
