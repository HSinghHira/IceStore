#!/bin/sh
# IceStore start script for Spoolman. Upstream's entrypoint switches to the
# "app" user (PUID/PGID, default 1000) but never chowns the data folder, and
# ZimaOS makes that folder as root. This gives the data folder to PUID:PGID,
# then hands over to upstream's entrypoint.
set -eu

LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(\(SPOOLMAN\|EXTERNAL_DB\)_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done
# PUID 0 makes upstream's entrypoint refuse to start; fall back to 1000.
[ "${PUID:-}" = "0" ] && { log "PUID 0 is not allowed by Spoolman, using 1000"; PUID=1000; }
[ "${PGID:-}" = "0" ] && PGID=1000
export PUID=${PUID:-1000} PGID=${PGID:-1000}

DATA=${SPOOLMAN_DIR_DATA:-/home/app/.local/share/spoolman}
mkdir -p "$DATA"
if [ "$(id -u)" = "0" ]; then
  chown -R "$PUID:$PGID" "$DATA"
fi

exec /home/app/spoolman/entrypoint.sh "$@"
