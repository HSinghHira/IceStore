#!/bin/sh
# IceStore start script for Langflow. Makes this install's secrets once and
# keeps them in /app/langflow, then hands over to upstream's own start command.
#   - A secret set in the app settings is used and saved to its file.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/app/langflow}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(LANGFLOW_[A-Z0-9_]*\)=$/\1/p'); do
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
make_secret LANGFLOW_SUPERUSER_PASSWORD 12
make_secret LANGFLOW_SECRET_KEY 32
export LANGFLOW_AUTO_LOGIN=false
export LANGFLOW_SUPERUSER="${LANGFLOW_SUPERUSER:-admin}"
export LANGFLOW_CONFIG_DIR="${LANGFLOW_CONFIG_DIR:-/app/langflow}"
export LANGFLOW_DATABASE_URL="${LANGFLOW_DATABASE_URL:-sqlite:////app/langflow/langflow.db}"
export LANGFLOW_HOST="${LANGFLOW_HOST:-0.0.0.0}"
export LANGFLOW_PORT="${LANGFLOW_PORT:-7860}"

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:6864"
cred_add "USER" "$LANGFLOW_SUPERUSER"
cred_add "PASSWORD" "$LANGFLOW_SUPERUSER_PASSWORD"
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:7860/health &

exec  "$@"
