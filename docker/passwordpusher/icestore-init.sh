#!/bin/sh
# IceStore start script for Password Pusher.
#
#   - SECRET_KEY_BASE set (from the app settings): used as is.
#   - Blank or missing: the key in storage/.secret_key_base, made on first
#     start, is passed as SECRET_KEY_BASE_FILE.
#   - The storage folder is given to the app's user (pwpusher), then
#     upstream's entrypoint runs as that user.
set -eu

STORAGE=/opt/PasswordPusher/storage
KEY_FILE=$STORAGE/.secret_key_base
log() { echo "[icestore] $*"; }

mkdir -p "$STORAGE/db"
if [ -z "${SECRET_KEY_BASE:-}" ]; then
  unset SECRET_KEY_BASE
  if [ ! -s "$KEY_FILE" ]; then
    (umask 077; head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$KEY_FILE.tmp")
    mv "$KEY_FILE.tmp" "$KEY_FILE"
    log "first start: made this install's SECRET_KEY_BASE (.secret_key_base in the storage folder). Back it up with the rest of the folder."
  fi
  export SECRET_KEY_BASE_FILE=$KEY_FILE
fi
chown -R pwpusher:pwpusher "$STORAGE"

cd /opt/PasswordPusher
exec su-exec pwpusher /usr/local/bin/docker-entrypoint "$@"
