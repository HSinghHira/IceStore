#!/bin/sh
# IceStore start script for HedgeDoc. Runs as root before upstream's
# entrypoint:
#
#   - CMD_SESSION_SECRET: set in the app settings wins; blank means the one
#     in /data/.session_secret, made on first start. (Without it HedgeDoc
#     makes a new one on every start and signs everyone out.)
#   - CMD_DB_URL: blank means SQLite in /data/hedgedoc.sqlite.
#   - Every other blank CMD_* variable is dropped, so HedgeDoc uses its
#     default (ZimaOS passes blank variables as empty strings).
#
# Then it hands over to upstream's docker-entrypoint.sh, which drops to the
# hedgedoc user with gosu.
set -eu

DATA=/data
SECRET_FILE=$DATA/.session_secret
log() { echo "[icestore] $*"; }

mkdir -p "$DATA"
umask 077

if [ -n "${CMD_SESSION_SECRET:-}" ]; then
  if [ -s "$SECRET_FILE" ] && [ "$(cat "$SECRET_FILE")" != "$CMD_SESSION_SECRET" ]; then
    log "CMD_SESSION_SECRET differs from the one used before; using CMD_SESSION_SECRET (everyone has to sign in again)."
    cp "$SECRET_FILE" "$SECRET_FILE.previous"
  fi
  printf '%s' "$CMD_SESSION_SECRET" > "$SECRET_FILE.tmp"
  mv "$SECRET_FILE.tmp" "$SECRET_FILE"
elif [ ! -s "$SECRET_FILE" ]; then
  head -c 48 /dev/urandom | base64 | tr -d '\n/+=' > "$SECRET_FILE.tmp"
  mv "$SECRET_FILE.tmp" "$SECRET_FILE"
  log "first start: made this install's session secret in /data/.session_secret."
fi
CMD_SESSION_SECRET=$(cat "$SECRET_FILE")
export CMD_SESSION_SECRET
umask 022

# Drop blank CMD_* variables.
for v in $(env | sed -n 's/^\(CMD_[A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v"
done
[ -n "${CMD_DB_URL:-}" ] || CMD_DB_URL="sqlite://$DATA/hedgedoc.sqlite"
[ -n "${CMD_IMAGE_UPLOAD_TYPE:-}" ] || CMD_IMAGE_UPLOAD_TYPE=filesystem
export CMD_DB_URL CMD_IMAGE_UPLOAD_TYPE

# The data folder is made by ZimaOS as root; HedgeDoc runs as hedgedoc.
chown -R hedgedoc "$DATA"

exec /usr/local/bin/docker-entrypoint.sh "$@"
