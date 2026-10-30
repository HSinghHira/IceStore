#!/bin/sh
# IceStore start script for GitSave. Makes sure the data folder holds this
# install's JWT_SECRET and ENCRYPTION_SECRET, then hands over to upstream's
# entrypoint (node's docker-entrypoint.sh).
#
#   - A secret set in the app settings is used and written to its file.
#   - Blank or missing: the one in the file is used, or a new random one is
#     made on first start.
#   - ENCRYPTION_SECRET must be exactly 32 characters (GitSave refuses to
#     start otherwise); the one made here is 32 hex characters.
# The data path can be moved for testing outside Docker (ICESTORE_DATA).
set -eu

DATA=${ICESTORE_DATA:-/app/data}
log() { echo "[icestore] $*"; }

mkdir -p "$DATA"

# keep_secret NAME FILE BYTES: the value from the variable, the file, or new.
keep_secret() {
  name=$1 file=$DATA/$2 bytes=$3
  eval "val=\${$name:-}"
  old_umask=$(umask)
  umask 077
  if [ -n "$val" ]; then
    if [ -s "$file" ] && [ "$(cat "$file")" != "$val" ]; then
      log "$name differs from the one used before; using $name. The old one is saved as $2.previous."
      cp "$file" "$file.previous"
    fi
    printf '%s' "$val" > "$file.tmp"
    mv "$file.tmp" "$file"
  elif [ ! -s "$file" ]; then
    head -c "$bytes" /dev/urandom | od -An -tx1 | tr -d ' \n' > "$file.tmp"
    mv "$file.tmp" "$file"
    log "first start: made this install's $name in the data folder ($2)."
  fi
  umask "$old_umask"
  eval "$name=\$(cat \"\$file\")"
  export "$name"
}

keep_secret JWT_SECRET .jwt_secret 32
# 16 bytes = 32 hex characters, the exact length GitSave needs.
keep_secret ENCRYPTION_SECRET .encryption_secret 16

if [ "${#ENCRYPTION_SECRET}" -ne 32 ]; then
  log "ENCRYPTION_SECRET must be exactly 32 characters; GitSave will not start until it is."
fi

# Blank values from the app settings mean "use the default".
[ -n "${DISABLE_AUTH:-}" ] || DISABLE_AUTH=false
export DISABLE_AUTH
for name in GIT_TIMEOUT PORT; do
  eval "val=\${$name-unset}"
  [ -n "$val" ] || unset "$name"
done

if [ -n "${ICESTORE_DRY_RUN:-}" ]; then
  env | grep -E '^(JWT_SECRET|ENCRYPTION_SECRET|DISABLE_AUTH|GIT_TIMEOUT)=' | sort
  exit 0
fi

exec docker-entrypoint.sh "$@"
