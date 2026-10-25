#!/bin/sh
# IceStore start script for Yuvomi. Makes sure the data folder holds this
# install's session secret and database key, then hands over to upstream's
# entrypoint (which fixes ownership of /data, /backups and /app/modules and
# drops to the "node" user).
#
#   - SESSION_SECRET / DB_ENCRYPTION_KEY set (from the app settings): that value
#     is used and written to the file.
#   - blank or missing: the value already in the file is used, or a new random
#     one is made on first start.
set -eu

log() { echo "[icestore] $*"; }

# ensure NAME FILE: export NAME from the app settings or from FILE.
ensure() {
  name=$1 file=$2
  eval "value=\${$name:-}"
  old_umask=$(umask)
  umask 077
  if [ -n "$value" ]; then
    if [ -s "$file" ] && [ "$(cat "$file")" != "$value" ]; then
      log "$name differs from the one Yuvomi used before; using the one from the app settings."
      log "The old one is saved as $(basename "$file").previous in the data folder."
      cp "$file" "$file.previous"
    fi
    printf '%s' "$value" > "$file.tmp"
    mv "$file.tmp" "$file"
  elif [ ! -s "$file" ]; then
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$file.tmp"
    mv "$file.tmp" "$file"
    log "first start: made this install's $name in the data folder ($(basename "$file")). Back it up with the rest of the folder."
  fi
  umask "$old_umask"
  export "$name=$(cat "$file")"
}

mkdir -p /data
ensure SESSION_SECRET /data/.session_secret

# Changing or losing the database key locks the database for good, so it is
# never made again once the database exists without one.
if [ -z "${DB_ENCRYPTION_KEY:-}" ] && [ ! -s /data/.db_encryption_key ] && [ -s "${DB_PATH:-/data/yuvomi.db}" ]; then
  log "the database already exists and there is no .db_encryption_key in the data folder;"
  log "starting without a database key. Set DB_ENCRYPTION_KEY in the app settings if it is encrypted."
  unset DB_ENCRYPTION_KEY
else
  ensure DB_ENCRYPTION_KEY /data/.db_encryption_key
fi

exec /entrypoint.sh "$@"
