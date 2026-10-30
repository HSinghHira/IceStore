#!/bin/sh
# Start script for strava-dawarich-sync in IceStore.
#   1. Drops blank optional settings, so they mean "default" (upstream reads a
#      blank LOOKBACK_DAYS as missing and stops).
#   2. Starts the setup page (setup_page.py) in the background.
#   3. Waits until the settings are filled in and Strava is connected, then
#      runs upstream's sync loop ("$@", the image's CMD).
set -eu

DATA_DIR=${DATA_DIR:-/data}
export DATA_DIR
mkdir -p "$DATA_DIR"

for v in SPORT_TYPES SKIP_VIRTUAL SYNC_INTERVAL_MINUTES LOOKBACK_DAYS DRY_RUN; do
  eval "val=\${$v-}"
  [ -n "$val" ] || unset "$v"
done

log() { echo "[icestore] $*"; }

python -u /opt/icestore/setup_page.py &

missing() {
  m=""
  [ -n "${STRAVA_CLIENT_ID:-}" ] || m="$m STRAVA_CLIENT_ID"
  [ -n "${STRAVA_CLIENT_SECRET:-}" ] || m="$m STRAVA_CLIENT_SECRET"
  case ${DAWARICH_URL:-} in
    ""|*"[ZIMAOS-IP-ADDRESS]"*) m="$m DAWARICH_URL" ;;
  esac
  [ -n "${DAWARICH_API_KEY:-}" ] || m="$m DAWARICH_API_KEY"
  echo "$m"
}

m=$(missing)
if [ -n "$m" ]; then
  log "settings still missing:$m"
  log "fill them in in the app settings and save; the setup page on port 6176 explains each one"
  # Settings only change with a restart, so there is nothing to wait for.
  exec sleep infinity
fi

said=0
until [ -s "$DATA_DIR/tokens.json" ]; do
  if [ "$said" = 0 ]; then
    log "Strava is not connected yet: open http://[ZIMAOS-IP-ADDRESS]:6176 and follow the steps"
    said=1
  fi
  sleep 5
done

log "Strava is connected, starting the sync (every ${SYNC_INTERVAL_MINUTES:-60} minutes)"
exec "$@"
