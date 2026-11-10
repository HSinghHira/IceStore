#!/bin/sh
# IceStore start script for kovi: the bind-mounted data folder ZimaOS makes
# belongs to root, so give it to the node user (upstream's image runs as
# node), then start kovi as that user.
set -eu
mkdir -p /app/data/uploads /app/data/covers
chown -R node:node /app/data
# Settings left empty in the app settings mean "use the default".
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do unset "$v"; done
exec setpriv --reuid=node --regid=node --init-groups "$@"
