#!/bin/sh
# IceStore start script for VSCodium web. Makes sure /config/connection-token.txt
# holds the token in use, then hands over to upstream's /init (s6-overlay),
# which sets up PUID/PGID, sudo and starts the server.
#
#   - CONNECTION_TOKEN_FILE set (from the app settings): left alone, upstream
#     reads the token from that file.
#   - CONNECTION_TOKEN set: that token is used and written to the file.
#   - Both blank or missing: the token already in the file is used, or a new
#     random one is made on first start.
set -eu

TOKEN_FILE=/config/connection-token.txt
PORT=6160
log() { echo "[icestore] $*"; }

# ZimaOS passes a variable someone left empty as an empty string.
if [ -z "${CONNECTION_TOKEN_FILE:-}" ]; then
  unset CONNECTION_TOKEN_FILE
  mkdir -p /config
  umask 077
  if [ -n "${CONNECTION_TOKEN:-}" ]; then
    printf '%s' "$CONNECTION_TOKEN" > "$TOKEN_FILE.tmp"
    mv "$TOKEN_FILE.tmp" "$TOKEN_FILE"
  elif [ ! -s "$TOKEN_FILE" ]; then
    # Hex only, so the token is safe to paste into ?tkn= in an address.
    head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$TOKEN_FILE.tmp"
    mv "$TOKEN_FILE.tmp" "$TOKEN_FILE"
    log "first start: made this install's connection token in $TOKEN_FILE"
  fi
  CONNECTION_TOKEN=$(cat "$TOKEN_FILE")
  export CONNECTION_TOKEN
  log "open VSCodium at http://[ZIMAOS-IP-ADDRESS]:$PORT/?tkn=$CONNECTION_TOKEN"
else
  log "using the connection token in $CONNECTION_TOKEN_FILE"
fi

exec /init "$@"
