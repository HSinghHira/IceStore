#!/bin/sh
# IceStore start script for Papra. Makes this install's AUTH_SECRET once and
# keeps it in /app/app-data, checks APP_BASE_URL, then hands over to
# upstream's own entrypoint and start command.
#   - AUTH_SECRET set in the app settings is used and saved.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/app/app-data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do
  case $v in
    AUTH_*|APP_*|CLIENT_*|SERVER_*|TRUSTED_*|EMAILS_*|SMTP_*|DOCUMENT_*|INGESTION_*|INTAKE_*|OCR_*|AI_*|TASKS_*|DATABASE_*|PROCESS_*) unset "$v" ;;
  esac
done

mkdir -p "$DIR"
f="$DIR/.icestore-auth-secret"
( umask 077
  if [ -n "${AUTH_SECRET:-}" ]; then
    printf '%s' "$AUTH_SECRET" > "$f.tmp" && mv "$f.tmp" "$f"
  elif [ ! -s "$f" ]; then
    head -c 48 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$f.tmp" && mv "$f.tmp" "$f"
    log "first start: made AUTH_SECRET ($f)"
  fi )
AUTH_SECRET=$(cat "$f")
export AUTH_SECRET

APP_BASE_URL=${APP_BASE_URL:-http://[ZIMAOS-IP-ADDRESS]:6890}
APP_BASE_URL=${APP_BASE_URL%/}
case $APP_BASE_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "APP_BASE_URL is still $APP_BASE_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, or sign-in from other devices fails"
    APP_BASE_URL=$(printf '%s' "$APP_BASE_URL" | sed 's/\[ZIMAOS-IP-ADDRESS\]/localhost/') ;;
esac
export APP_BASE_URL

cred_reset
cred_add "URL" "$APP_BASE_URL"
cred_note "First visit: create an account. The first account becomes the admin."
/usr/local/lib/icestore/credentials.sh "http://127.0.0.1:${PORT:-1221}/" &

exec docker-entrypoint.sh "$@"
