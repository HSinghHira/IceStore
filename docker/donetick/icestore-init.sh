#!/bin/sh
# IceStore start script for Donetick. Upstream's selfhosted.yaml ships one
# JWT secret for everyone. This makes one per install, keeps it in
# /donetick-data, points the SQLite database there too, and starts Donetick.
#   - DT_JWT_SECRET set in the app settings is used and saved.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/donetick-data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(\(DT\|DONETICK\)_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$DIR"
f="$DIR/.icestore-jwt-secret"
( umask 077
  if [ -n "${DT_JWT_SECRET:-}" ]; then
    printf '%s' "$DT_JWT_SECRET" > "$f.tmp" && mv "$f.tmp" "$f"
  elif [ ! -s "$f" ]; then
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$f.tmp" && mv "$f.tmp" "$f"
    log "first start: made DT_JWT_SECRET ($f)"
  fi )
DT_JWT_SECRET=$(cat "$f")
export DT_JWT_SECRET
export DT_SQLITE_PATH="${DT_SQLITE_PATH:-$DIR/donetick.db}"

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:6899"
cred_note "First visit: sign up. Then set DONETICK_DISABLE_SIGNUP to true."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:2021/ &

exec "$@"
