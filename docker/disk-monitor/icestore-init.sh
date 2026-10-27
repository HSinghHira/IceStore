#!/bin/sh
# IceStore start script for Disk Monitor. Upstream refuses to start without
# DISK_MONITOR_USERNAME, DISK_MONITOR_PASSWORD (12+ characters) and
# DISK_MONITOR_SESSION_SECRET (32+ characters), and makes none of them itself.
# This script fills them in, then runs upstream's command.
#
#   - DISK_MONITOR_USERNAME blank or missing: admin.
#   - DISK_MONITOR_PASSWORD set: used as is. Blank or missing: the password in
#     /app/cache/password.txt, made on first start and shown in the log.
#   - DISK_MONITOR_SESSION_SECRET set: used and written to
#     /app/cache/.session_secret. Blank or missing: the secret in that file,
#     made on first start.
#
# The container root is read-only; only /app/cache and /tmp can be written.
set -eu

CACHE=/app/cache
PASS_FILE=$CACHE/password.txt
SECRET_FILE=$CACHE/.session_secret
log() { echo "[icestore] $*"; }

# Write $2 to file $1 safely (temp file, then rename), readable by root only.
save() {
  printf '%s' "$2" > "$1.tmp"
  mv "$1.tmp" "$1"
}

# Random hex string, $1 bytes long (busybox has no openssl).
random_hex() {
  head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'
}

umask 077
mkdir -p "$CACHE" || { log "cannot create $CACHE"; exit 1; }
touch "$CACHE/.icestore-write-test" 2>/dev/null || { log "cannot write to $CACHE; check the app's cache folder"; exit 1; }
rm -f "$CACHE/.icestore-write-test"

# ZimaOS passes a variable someone left empty as an empty string.
[ -n "${DISK_MONITOR_USERNAME:-}" ] || DISK_MONITOR_USERNAME=admin

# Session secret
if [ -n "${DISK_MONITOR_SESSION_SECRET:-}" ]; then
  if [ -s "$SECRET_FILE" ] && [ "$(cat "$SECRET_FILE")" != "$DISK_MONITOR_SESSION_SECRET" ]; then
    cp "$SECRET_FILE" "$SECRET_FILE.previous"
    log "DISK_MONITOR_SESSION_SECRET changed; everyone has to sign in again. The old one is in .session_secret.previous."
  fi
  save "$SECRET_FILE" "$DISK_MONITOR_SESSION_SECRET"
elif [ -s "$SECRET_FILE" ]; then
  DISK_MONITOR_SESSION_SECRET=$(cat "$SECRET_FILE")
else
  DISK_MONITOR_SESSION_SECRET=$(random_hex 48)
  save "$SECRET_FILE" "$DISK_MONITOR_SESSION_SECRET"
  log "first start: made this install's session secret (.session_secret in the cache folder)."
fi

# Login password
if [ -z "${DISK_MONITOR_PASSWORD:-}" ]; then
  if [ ! -s "$PASS_FILE" ]; then
    save "$PASS_FILE" "$(random_hex 12)"
    log "first start: sign in as $DISK_MONITOR_USERNAME with the password $(cat "$PASS_FILE")"
  fi
  DISK_MONITOR_PASSWORD=$(cat "$PASS_FILE")
  log "login: $DISK_MONITOR_USERNAME, password in /DATA/AppData/disk-monitor/cache/password.txt"
elif [ "${#DISK_MONITOR_PASSWORD}" -lt 12 ]; then
  log "DISK_MONITOR_PASSWORD must have at least 12 characters, or Disk Monitor won't start."
fi

export DISK_MONITOR_USERNAME DISK_MONITOR_PASSWORD DISK_MONITOR_SESSION_SECRET

cd /app
exec "$@"
