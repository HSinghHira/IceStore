#!/bin/sh
# IceStore start script for DailyTxT. Makes this install's SECRET_TOKEN and
# ADMIN_PASSWORD once and keeps them in /data, then hands over to upstream's
# entrypoint (backend + nginx).
#   - A value set in the app settings is used and saved.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${DATA_PATH:-/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do
  case $v in
    SECRET_TOKEN|ADMIN_PASSWORD|ALLOW_REGISTRATION|LOGOUT_AFTER_DAYS|ALLOWED_HOSTS|INDENT|BASE_PATH) unset "$v" ;;
  esac
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
make_secret SECRET_TOKEN 32
make_secret ADMIN_PASSWORD 12

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:7007"
cred_add "ADMIN PASSWORD" "$ADMIN_PASSWORD"
cred_note "Register your own account first. The admin password only opens the admin panel (Settings > Admin)."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:80/ &

exec "$@"
