#!/bin/sh
# IceStore start script for Glance. Copies a starter glance.yml into the
# config folder when there is none, then starts upstream's glance with it.
# Your own glance.yml is never changed. Arguments are passed to glance
# instead (for example "password:hash mypassword" or "secret:make").
set -eu

CONFIG=${ICESTORE_CONFIG:-/app/config}
STARTER=${ICESTORE_STARTER:-/usr/local/share/icestore/glance.yml}

if [ "$#" -gt 0 ]; then
  exec /app/glance "$@"
fi

mkdir -p "$CONFIG" "$CONFIG/assets"
if [ ! -e "$CONFIG/glance.yml" ]; then
  cp "$STARTER" "$CONFIG/glance.yml"
  echo "[icestore] first start: wrote a starter glance.yml; edit it in /DATA/AppData/glance/config"
fi

exec /app/glance --config "$CONFIG/glance.yml"
