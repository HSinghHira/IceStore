#!/bin/sh
# IceStore start script for LinkStack. Runs as root, once per start:
#
#   - first start (no /htdocs/version.json): copy the app from the image into
#     the data folder, as Docker does for upstream's named volume.
#   - give /htdocs to apache (ZimaOS makes the folder as root).
#   - blank variables are dropped, so LinkStack's entrypoint uses its
#     defaults (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's docker-entrypoint.sh runs as apache, unchanged.
set -eu

log() { echo "[icestore] $*"; }

if [ ! -f /htdocs/version.json ]; then
  log "first start: copying LinkStack into the data folder"
  cp -a /opt/linkstack-dist/. /htdocs/
fi
chown -R apache:apache /htdocs

for v in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=$/\1/p'); do
  unset "$v" 2>/dev/null || true
done

log "Open http://<your ZimaOS IP>:6776 and follow the setup wizard to make the admin account."
exec setpriv --reuid=apache --regid=apache --init-groups "$@"
