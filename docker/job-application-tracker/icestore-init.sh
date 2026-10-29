#!/bin/sh
# IceStore start script for Job Application Tracker.
#
#   1. Gives the data folder to PUID:PGID (default 1000:1000) if something in
#      it belongs to someone else (ZimaOS makes the folder as root).
#   2. First start, unless JAT_GIT_SNAPSHOTS=false: makes the data folder a
#      git repo, so the app commits a readable snapshot after each burst of
#      changes (upstream's backup feature). An existing repo is left alone.
#   3. `jat init` (safe on every start: it only adds what is missing), then
#      `jat serve` on 0.0.0.0:8770 as PUID:PGID.
# Paths can be moved for testing outside Docker (JAT_DATA_DIR, ICESTORE_DRY_RUN).
set -eu

DATA=${JAT_DATA_DIR:-/data}
PORT=${JAT_PORT:-8770}
log() { echo "[icestore] $*"; }

[ -n "${PUID:-}" ] || PUID=1000
[ -n "${PGID:-}" ] || PGID=1000
case "$PUID$PGID" in
  *[!0-9]*) log "PUID and PGID must be numbers (got PUID='$PUID' PGID='$PGID')"; exit 1 ;;
esac

mkdir -p "$DATA"
export JAT_DATA_DIR="$DATA" JAT_HOST=0.0.0.0 JAT_PORT="$PORT"
export HOME=/tmp

# Run a command as PUID:PGID when started as root, as is otherwise.
as_app() {
  if [ "$(id -u)" = 0 ]; then
    setpriv --reuid="$PUID" --regid="$PGID" --clear-groups -- "$@"
  else
    "$@"
  fi
}

if [ "$(id -u)" = 0 ] && \
   [ -n "$(find "$DATA" \( ! -user "$PUID" -o ! -group "$PGID" \) -print -quit)" ]; then
  log "giving $DATA to $PUID:$PGID"
  chown -R "$PUID:$PGID" "$DATA"
fi

snapshots=${JAT_GIT_SNAPSHOTS:-true}
if [ "$snapshots" != false ] && [ ! -e "$DATA/.git" ]; then
  log "first start: making the data folder a git repo for automatic snapshots"
  as_app git init -q -b main "$DATA"
  as_app git -C "$DATA" config user.name "${JAT_GIT_NAME:-Job Application Tracker}"
  as_app git -C "$DATA" config user.email "${JAT_GIT_EMAIL:-jat@localhost}"
fi
# The name and email can be changed later in the app settings.
if [ -d "$DATA/.git" ]; then
  [ -z "${JAT_GIT_NAME:-}" ] || as_app git -C "$DATA" config user.name "$JAT_GIT_NAME"
  [ -z "${JAT_GIT_EMAIL:-}" ] || as_app git -C "$DATA" config user.email "$JAT_GIT_EMAIL"
fi

if [ -n "${ICESTORE_DRY_RUN:-}" ]; then
  echo "would run: jat init; jat serve --host 0.0.0.0 --port $PORT (data: $DATA, user $PUID:$PGID)"
  exit 0
fi

as_app jat init
if [ "$(id -u)" = 0 ]; then
  exec setpriv --reuid="$PUID" --regid="$PGID" --clear-groups -- jat serve --host 0.0.0.0 --port "$PORT"
fi
exec jat serve --host 0.0.0.0 --port "$PORT"
