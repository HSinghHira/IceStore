#!/bin/sh
# IceStore start script for wastebin. Upstream makes a new cookie signing key
# on every start (so people can no longer delete their own pastes after a
# restart) and uses the fixed salt "somesalt" for paste passwords. This makes
# both once per install, keeps them in /data, and starts wastebin.
#   - A value set in the app settings is used and saved.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(WASTEBIN_[A-Z0-9_]*\)=$/\1/p'); do
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
# The signing key must be at least 64 bytes: 64 random bytes as 128 hex characters.
make_secret WASTEBIN_SIGNING_KEY 64
make_secret WASTEBIN_PASSWORD_SALT 16

# The compose default is a placeholder; wastebin can't parse it as a URL, so
# leave it unset (no QR codes) until it is filled in.
case "${WASTEBIN_BASE_URL:-}" in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "WASTEBIN_BASE_URL is still $WASTEBIN_BASE_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings for QR codes"
    unset WASTEBIN_BASE_URL ;;
esac

export WASTEBIN_DATABASE_PATH="${WASTEBIN_DATABASE_PATH:-$DIR/state.db}"
export WASTEBIN_ADDRESS_PORT="${WASTEBIN_ADDRESS_PORT:-0.0.0.0:8088}"

exec "$@"
