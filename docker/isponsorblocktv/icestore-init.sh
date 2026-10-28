#!/bin/sh
# IceStore start script for iSponsorBlockTV.
#
#   1. Starts ttyd on $ISPONSORBLOCKTV_SETUP_PORT. Opening that page in a
#      browser runs upstream's own setup wizard (`main.pyc --setup`), which
#      writes /app/data/config.json.
#   2. Runs the skipper (upstream's command, "$@") once config.json lists at
#      least one device, and restarts it whenever config.json changes.
#
# Optional settings (blank or missing = default):
#   ISPONSORBLOCKTV_SETUP_USERNAME / ISPONSORBLOCKTV_SETUP_PASSWORD
#       both set: the setup page asks for them (basic auth).
#   ISPONSORBLOCKTV_DEBUG=true   adds --debug to the skipper.
set -eu

cd /app
DATA_DIR=/app/data
CONFIG=$DATA_DIR/config.json
PORT=${ISPONSORBLOCKTV_SETUP_PORT:-}
[ -n "$PORT" ] || PORT=6129

log() { echo "[icestore] $*"; }

mkdir -p "$DATA_DIR"

# ---- setup page -------------------------------------------------------------
TTYD_ARGS="-W -p $PORT -m 1 -t titleFixed=iSponsorBlockTV-setup -t fontSize=15"
if [ -n "${ISPONSORBLOCKTV_SETUP_USERNAME:-}" ] && [ -n "${ISPONSORBLOCKTV_SETUP_PASSWORD:-}" ]; then
  TTYD_ARGS="$TTYD_ARGS -c ${ISPONSORBLOCKTV_SETUP_USERNAME}:${ISPONSORBLOCKTV_SETUP_PASSWORD}"
  log "setup page asks for a username and password."
elif [ -n "${ISPONSORBLOCKTV_SETUP_USERNAME:-}${ISPONSORBLOCKTV_SETUP_PASSWORD:-}" ]; then
  log "set both ISPONSORBLOCKTV_SETUP_USERNAME and ISPONSORBLOCKTV_SETUP_PASSWORD to protect the setup page; it is open for now."
fi
# shellcheck disable=SC2086
ttyd $TTYD_ARGS python3 -u /app/main.pyc --setup &
TTYD_PID=$!
log "setup page on port $PORT (open http://[ZIMAOS-IP-ADDRESS]:$PORT)."

# ---- skipper ----------------------------------------------------------------
DEBUG_FLAG=""
case "${ISPONSORBLOCKTV_DEBUG:-}" in
  true|TRUE|True|1|yes) DEBUG_FLAG="--debug" ;;
esac

APP_PID=""
stop_all() {
  [ -n "$APP_PID" ] && kill "$APP_PID" 2>/dev/null || true
  kill "$TTYD_PID" 2>/dev/null || true
  wait 2>/dev/null || true
  exit 0
}
trap stop_all TERM INT

has_devices() {
  [ -s "$CONFIG" ] || return 1
  python3 -c "import json,sys; sys.exit(0 if json.load(open(sys.argv[1])).get('devices') else 1)" "$CONFIG" 2>/dev/null
}

config_sum() { md5sum "$CONFIG" 2>/dev/null | cut -d' ' -f1; }

WAITING_SAID=""
while :; do
  if ! kill -0 "$TTYD_PID" 2>/dev/null; then
    log "setup page stopped; restarting it."
    # shellcheck disable=SC2086
    ttyd $TTYD_ARGS python3 -u /app/main.pyc --setup &
    TTYD_PID=$!
  fi

  if ! has_devices; then
    if [ -z "$WAITING_SAID" ]; then
      log "no TV paired yet. Open http://[ZIMAOS-IP-ADDRESS]:$PORT and add a device in the setup wizard."
      WAITING_SAID=1
    fi
    sleep 5 &
    wait $! || true
    continue
  fi
  WAITING_SAID=""

  SUM=$(config_sum)
  log "starting iSponsorBlockTV."
  # shellcheck disable=SC2086
  "$@" $DEBUG_FLAG &
  APP_PID=$!

  while kill -0 "$APP_PID" 2>/dev/null; do
    sleep 5 &
    wait $! || true
    if [ "$(config_sum)" != "$SUM" ]; then
      log "config.json changed; restarting iSponsorBlockTV."
      kill "$APP_PID" 2>/dev/null || true
      break
    fi
  done
  wait "$APP_PID" 2>/dev/null || true
  APP_PID=""
  sleep 2
done
