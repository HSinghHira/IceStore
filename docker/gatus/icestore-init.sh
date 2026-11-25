#!/bin/sh
# IceStore start script for Gatus. Makes this install's secrets once and
# keeps them in /config, then hands over to upstream's own start command.
#   - A secret set in the app settings is used and saved to its file.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/config}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(GATUS_[A-Z0-9_]*\)=$/\1/p'); do
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

if [ ! -e "$DIR/config.yaml" ]; then
  cp "${ICESTORE_STARTER:-/usr/local/share/icestore/config.yaml}" "$DIR/config.yaml"
  log "first start: wrote a starter config.yaml; edit it in /DATA/AppData/gatus/config"
fi
mkdir -p "${ICESTORE_DATA_DIR:-/data}"
export GATUS_CONFIG_PATH="${GATUS_CONFIG_PATH:-$DIR/config.yaml}"

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:6857"
cred_add "CONFIG" "/DATA/AppData/gatus/config/config.yaml"
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/health &

exec /gatus "$@"
