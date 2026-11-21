#!/bin/sh
# IceStore start script for Vikunja. Runs as root (the folder ZimaOS makes
# belongs to root, and upstream's image has no tool to switch users):
#
#   - VIKUNJA_SERVICE_SECRET: set in the app settings wins; blank means the
#     one in /data/.service_secret, made on first start. (Without it Vikunja
#     makes a new one on every start and signs everyone out.)
#   - The database and the uploaded files live in /data.
#   - VIKUNJA_SERVICE_TIMEZONE follows TZ unless set.
#   - Every other blank VIKUNJA_* variable is dropped, so Vikunja uses its
#     default (ZimaOS passes blank variables as empty strings).
set -eu

DATA=/data
SECRET_FILE=$DATA/.service_secret
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/files"
umask 077

if [ -n "${VIKUNJA_SERVICE_SECRET:-}" ]; then
  if [ -s "$SECRET_FILE" ] && [ "$(cat "$SECRET_FILE")" != "$VIKUNJA_SERVICE_SECRET" ]; then
    log "VIKUNJA_SERVICE_SECRET differs from the one used before; using it (everyone has to sign in again)."
    cp "$SECRET_FILE" "$SECRET_FILE.previous"
  fi
  printf '%s' "$VIKUNJA_SERVICE_SECRET" > "$SECRET_FILE.tmp"
  mv "$SECRET_FILE.tmp" "$SECRET_FILE"
elif [ ! -s "$SECRET_FILE" ]; then
  head -c 48 /dev/urandom | base64 | tr -d '\n/+=' > "$SECRET_FILE.tmp"
  mv "$SECRET_FILE.tmp" "$SECRET_FILE"
  log "first start: made this install's secret in /data/.service_secret."
fi
VIKUNJA_SERVICE_SECRET=$(cat "$SECRET_FILE")
export VIKUNJA_SERVICE_SECRET
umask 022

for v in $(env | sed -n 's/^\(VIKUNJA_[A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v"
done
[ -n "${VIKUNJA_SERVICE_TIMEZONE:-}" ] || VIKUNJA_SERVICE_TIMEZONE=${TZ:-GMT}
[ -n "$VIKUNJA_SERVICE_TIMEZONE" ] || VIKUNJA_SERVICE_TIMEZONE=GMT
[ -n "${VIKUNJA_DATABASE_PATH:-}" ] || VIKUNJA_DATABASE_PATH=$DATA/vikunja.db
[ -n "${VIKUNJA_FILES_BASEPATH:-}" ] || VIKUNJA_FILES_BASEPATH=$DATA/files
export VIKUNJA_SERVICE_TIMEZONE VIKUNJA_DATABASE_PATH VIKUNJA_FILES_BASEPATH

cred_reset
cred_add URL "http://<your ZimaOS IP>:6761"
cred_note "No account yet: click Create account on the sign-in page to make yours."
cred_note "Then set VIKUNJA_SERVICE_ENABLEREGISTRATION to false in the app settings."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:3456/api/v1/info &

exec /app/vikunja/vikunja "$@"
