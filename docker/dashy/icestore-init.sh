#!/bin/sh
# IceStore start script for Dashy.
#
#   - /app/user-data/conf.yml missing (first start): the sample config from
#     the image is copied in.
#   - The folder is given to Dashy's user (1000:1000) so the config editor
#     can save, then Dashy runs as that user.
set -eu

DIR=${USER_DATA_DIR:-/app/user-data}
case $DIR in /*) ;; *) DIR=/app/$DIR ;; esac
log() { echo "[icestore] $*"; }

mkdir -p "$DIR"
if [ ! -s "$DIR/conf.yml" ]; then
  cp /app/conf.sample.yml "$DIR/conf.yml"
  log "first start: put the sample conf.yml in the config folder. Edit it in Dashy (Config, Edit) or in the Files app."
fi
chown -R 1000:1000 "$DIR"

cd /app
exec su-exec 1000:1000 "$@"
