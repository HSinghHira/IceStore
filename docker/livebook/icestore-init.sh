#!/bin/sh
# IceStore start script for Livebook. Makes this install's secrets once and
# keeps them in /data, then hands over to upstream's own start command.
#   - A secret set in the app settings is used and saved to its file.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(LIVEBOOK_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$DIR"
# make_secret NAME BYTES: NAME from the app settings, the saved file, or new.
make_secret() {
  _f="$DIR/.icestore-$(echo "$1" | tr 'A-Z_' 'a-z-')"
  eval "_v=\${$1:-}"
  ( umask 077
    if [ -n "$_v" ]; then
      printf '%s' "$_v" > "$_f.tmp" && mv "$_f.tmp" "$_f"
    elif [ ! -s "$_f" ]; then
      head -c "$2" /dev/urandom | od -An -tx1 | tr -d ' \n' > "$_f.tmp" && mv "$_f.tmp" "$_f"
      log "first start: made $1 ($_f)"
    fi )
  eval "$1=\$(cat \"\$_f\")"
  export "$1"
}
make_secret LIVEBOOK_PASSWORD 12
make_secret LIVEBOOK_SECRET_KEY_BASE 48
export LIVEBOOK_HOME="${LIVEBOOK_HOME:-/data}"
export LIVEBOOK_DATA_PATH="${LIVEBOOK_DATA_PATH:-/data/.livebook}"
# Livebook checks this folder is writable but does not create it.
mkdir -p "$LIVEBOOK_HOME" "$LIVEBOOK_DATA_PATH"

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:6867"
cred_add "PASSWORD" "$LIVEBOOK_PASSWORD"
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/public/health &

exec  "$@"
