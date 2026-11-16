#!/bin/sh
# IceStore start script for Gotify. Gotify makes its first user from
# GOTIFY_DEFAULTUSER_NAME / GOTIFY_DEFAULTUSER_PASS when it creates its
# database, and upstream's default password is "admin". This script makes
# that password random for each install, then runs upstream's command.
#
#   - GOTIFY_DEFAULTUSER_PASS set: used as is (Gotify only reads it when the
#     database is new).
#   - Blank or missing, new install: a random password, saved in
#     /app/data/password.txt and shown in the CREDENTIALS box.
#   - Blank or missing, existing database without password.txt (installed
#     before this script): nothing is made; the password is whatever you use.
set -eu

DATA=/app/data
PASS_FILE=$DATA/password.txt
log() { echo "[icestore] $*"; }

umask 077
mkdir -p "$DATA"

[ -n "${GOTIFY_DEFAULTUSER_NAME:-}" ] || GOTIFY_DEFAULTUSER_NAME=admin

# CREDENTIALS banner (docker/_common).
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh
cred_reset
cred_add URL "http://<your ZimaOS IP>:6730"
cred_add USERNAME "$GOTIFY_DEFAULTUSER_NAME"

if [ -n "${GOTIFY_DEFAULTUSER_PASS:-}" ]; then
  cred_add PASSWORD "(the one you set in GOTIFY_DEFAULTUSER_PASS)"
elif [ -s "$PASS_FILE" ]; then
  GOTIFY_DEFAULTUSER_PASS=$(cat "$PASS_FILE")
  cred_add PASSWORD "$GOTIFY_DEFAULTUSER_PASS"
  cred_note "Also saved in /DATA/AppData/gotify/data/password.txt. If you changed it in Gotify, use your new one."
elif [ ! -e "$DATA/gotify.db" ]; then
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  GOTIFY_DEFAULTUSER_PASS=$(cat "$PASS_FILE")
  log "first start: made a random admin password (password.txt in the data folder)."
  cred_add PASSWORD "$GOTIFY_DEFAULTUSER_PASS"
  cred_note "Also saved in /DATA/AppData/gotify/data/password.txt. Change it in Gotify under Users if you like."
else
  cred_add PASSWORD "(the one you already use)"
fi

export GOTIFY_DEFAULTUSER_NAME
[ -z "${GOTIFY_DEFAULTUSER_PASS:-}" ] || export GOTIFY_DEFAULTUSER_PASS

/usr/local/lib/icestore/credentials.sh "http://127.0.0.1:${GOTIFY_SERVER_PORT:-80}/health" &

cd /app
exec "$@"
