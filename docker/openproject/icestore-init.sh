#!/bin/sh
# IceStore start script for OpenProject. Makes this install's secrets once and
# keeps them in /var/openproject/assets, then hands over to upstream's own start command.
#   - A secret set in the app settings is used and saved to its file.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/var/openproject/assets}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(OPENPROJECT_[A-Z0-9_]*\)=$/\1/p'); do
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
make_secret SECRET_KEY_BASE 64
make_secret OPENPROJECT_SEED_ADMIN_USER_PASSWORD 12
export OPENPROJECT_SEED_ADMIN_USER_PASSWORD_RESET="${OPENPROJECT_SEED_ADMIN_USER_PASSWORD_RESET:-false}"
export OPENPROJECT_HTTPS="${OPENPROJECT_HTTPS:-false}"

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:6869"
cred_add "USER" "admin"
cred_add "PASSWORD" "$OPENPROJECT_SEED_ADMIN_USER_PASSWORD"
cred_note "This is the password the admin account was made with; if you changed it in OpenProject, use yours."
/usr/local/lib/icestore/credentials.sh &

exec ./docker/prod/entrypoint.sh "$@"
