#!/bin/sh
# IceStore start script for Semaphore UI. Runs as root, once per start:
#
#   - SEMAPHORE_ACCESS_KEY_ENCRYPTION: set in the app settings wins; blank
#     means the one in /data/secrets.env, made on first start. It encrypts
#     the SSH keys and passwords you save in Semaphore.
#   - SEMAPHORE_ADMIN_PASSWORD: blank means the one in /data/.admin_password,
#     made on first start. Upstream's server-wrapper only makes the admin on
#     the first start (when there is no config.json yet).
#   - SQLite, config, database and the folder Semaphore clones repos into
#     all live in /data.
#   - Blank variables are dropped, so Semaphore uses its defaults
#     (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's server-wrapper runs as Semaphore's user (1001).
set -eu

DATA=/data
SECRETS=$DATA/secrets.env
PASS_FILE=$DATA/.admin_password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/config" "$DATA/db" "$DATA/tmp"
umask 077
touch "$SECRETS"

if ! grep -q '^SEMAPHORE_ACCESS_KEY_ENCRYPTION=' "$SECRETS"; then
  echo "SEMAPHORE_ACCESS_KEY_ENCRYPTION=$(head -c 32 /dev/urandom | base64 | tr -d '\n')" >> "$SECRETS"
fi
[ -n "${SEMAPHORE_ACCESS_KEY_ENCRYPTION:-}" ] || SEMAPHORE_ACCESS_KEY_ENCRYPTION=$(secret SEMAPHORE_ACCESS_KEY_ENCRYPTION)

[ -n "${SEMAPHORE_ADMIN:-}" ] || SEMAPHORE_ADMIN=admin
[ -n "${SEMAPHORE_ADMIN_EMAIL:-}" ] || SEMAPHORE_ADMIN_EMAIL=admin@localhost
PASSWORD_SET=
if [ -n "${SEMAPHORE_ADMIN_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  SEMAPHORE_ADMIN_PASSWORD=$(cat "$PASS_FILE")
else
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  SEMAPHORE_ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in /data/.admin_password."
fi
umask 022

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done
SEMAPHORE_DB_DIALECT=sqlite
SEMAPHORE_CONFIG_PATH=$DATA/config
SEMAPHORE_DB_PATH=$DATA/db
SEMAPHORE_TMP_PATH=$DATA/tmp
export SEMAPHORE_ACCESS_KEY_ENCRYPTION SEMAPHORE_ADMIN SEMAPHORE_ADMIN_EMAIL SEMAPHORE_ADMIN_PASSWORD \
       SEMAPHORE_DB_DIALECT SEMAPHORE_CONFIG_PATH SEMAPHORE_DB_PATH SEMAPHORE_TMP_PATH
unset SEMAPHORE_DB_HOST SEMAPHORE_DB_PORT SEMAPHORE_DB_USER SEMAPHORE_DB_PASS 2>/dev/null || true

chown -R 1001 "$DATA"
chown root "$SECRETS" "$PASS_FILE" 2>/dev/null || true

cred_reset
cred_add URL "http://<your ZimaOS IP>:6778"
cred_add USERNAME "$SEMAPHORE_ADMIN"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in SEMAPHORE_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$SEMAPHORE_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/semaphore/data/.admin_password"
fi
cred_note "Only used for the first start. Change it in your user settings after you sign in."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:3000/api/ping &

cd /home/semaphore
exec setpriv --reuid=semaphore --regid=0 --init-groups "$@"
