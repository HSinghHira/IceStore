#!/bin/sh
# IceStore start script for Pocket ID. Makes sure /app/data/.encryption_key
# holds the key in use, then hands over to upstream's entrypoint (which fixes
# ownership of /app/data and drops to PUID:PGID).
#
#   - ENCRYPTION_KEY set (from the app settings): that key is used and written
#     to the file, as upstream would use it.
#   - ENCRYPTION_KEY blank or missing: the key already in the file is used, or
#     a new random one is made on first start.
#   - ENCRYPTION_KEY_FILE set to another path: left alone, you manage the key.
set -eu

KEY_FILE=/app/data/.encryption_key
log() { echo "[icestore] $*"; }

# ZimaOS passes a variable someone left empty as an empty string.
[ -n "${ENCRYPTION_KEY_FILE:-}" ] || ENCRYPTION_KEY_FILE=$KEY_FILE

if [ "$ENCRYPTION_KEY_FILE" = "$KEY_FILE" ]; then
  mkdir -p /app/data
  umask 077
  if [ -n "${ENCRYPTION_KEY:-}" ]; then
    if [ -s "$KEY_FILE" ] && [ "$(cat "$KEY_FILE")" != "$ENCRYPTION_KEY" ]; then
      log "ENCRYPTION_KEY differs from the key Pocket ID used before; using ENCRYPTION_KEY."
      log "The old key is saved as .encryption_key.previous. If Pocket ID can't read its data now,"
      log "set ENCRYPTION_KEY to the old key, or rotate it with: /app/pocket-id encryption-key-rotate"
      cp "$KEY_FILE" "$KEY_FILE.previous"
    fi
    printf '%s' "$ENCRYPTION_KEY" > "$KEY_FILE.tmp"
    mv "$KEY_FILE.tmp" "$KEY_FILE"
  elif [ ! -s "$KEY_FILE" ]; then
    # 32 random bytes, base64, no trailing newline (Pocket ID reads the file as is).
    head -c 32 /dev/urandom | base64 | tr -d '\n' > "$KEY_FILE.tmp"
    mv "$KEY_FILE.tmp" "$KEY_FILE"
    log "first start: made this install's encryption key in the data folder (.encryption_key). Back it up with the rest of the folder."
  fi
fi

# The file wins over the variable in Pocket ID; unset it so only one is in play.
unset ENCRYPTION_KEY
export ENCRYPTION_KEY_FILE

exec /app/docker/entrypoint.sh "$@"
