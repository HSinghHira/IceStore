#!/bin/sh
# IceStore start script for OpenBot. Makes this install's secrets once and
# keeps them in /data, then hands over to upstream's own start command.
#   - A secret set in the app settings is used and saved to its file.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(OPENBOT_[A-Z0-9_]*\)=$/\1/p'); do
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

# The data folder ZimaOS makes is root's; OpenBot runs as uid 1000
# (upstream's Umbrel app does the same in its pre-start hook).
if [ "$(stat -c '%u:%g' "$DIR")" != "1000:1000" ]; then
  chown 1000:1000 "$DIR"
fi
chmod 0700 "$DIR"
export OPENBOT_SETUP_PAGE_PORT="${OPENBOT_SETUP_PAGE_PORT:-8080}"
# stdout/stderr belong to root; let the openbot user write to them.
chown 1000:1000 "/proc/$$/fd/1" "/proc/$$/fd/2"

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:6873"
cred_note "Open this address and sign in with your OpenBot account, then use the OpenBot app or openbot.run/app with the same account."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/ &

exec setpriv --reuid=1000 --regid=1000 --init-groups env HOME=/data /opt/OpenBot/app/resources/hosting/openbot-container "$@"
