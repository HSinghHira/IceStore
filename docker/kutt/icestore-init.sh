#!/bin/sh
# IceStore start script for Kutt. Makes this install's secrets once and
# keeps them in /kutt/db, then hands over to upstream's own start command.
#   - A secret set in the app settings is used and saved to its file.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/kutt/db}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do
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
make_secret JWT_SECRET 32
export DB_FILENAME="${DB_FILENAME:-/kutt/db/data}"
export DISALLOW_REGISTRATION="${DISALLOW_REGISTRATION:-true}"
export DISALLOW_ANONYMOUS_LINKS="${DISALLOW_ANONYMOUS_LINKS:-true}"

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:6859"
cred_note "Open Kutt and make the admin account; the first account is the admin."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:3000/api/v2/health &

exec docker-entrypoint.sh "$@"
