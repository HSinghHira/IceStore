#!/bin/sh
# IceStore start script for tdeemon.
#   - TDEEMON_SECRET_KEY: a value from the app settings wins and is saved;
#     blank means the saved key, or a new one on first start.
#   - TDEEMON_BASE_URL with the [ZIMAOS-IP-ADDRESS] placeholder: runs on
#     localhost until it is set, and says so in the log.
#   - First start: once the server answers, makes the first admin from
#     ADMIN_EMAIL with a made password (upstream's `user create --admin`),
#     and shows it in the CREDENTIALS banner.
set -eu

DATA=${TDEEMON_DATA_DIR:-/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA/.icestore"
umask 077
KEY=$DATA/.icestore/secret_key
if [ -n "${TDEEMON_SECRET_KEY:-}" ]; then
  printf '%s' "$TDEEMON_SECRET_KEY" > "$KEY"
elif [ ! -s "$KEY" ]; then
  head -c 32 /dev/urandom | base64 | tr -d '\n' > "$KEY"
  log "first start: made TDEEMON_SECRET_KEY (.icestore/secret_key in the data folder). Back it up."
fi
TDEEMON_SECRET_KEY=$(cat "$KEY")
export TDEEMON_SECRET_KEY TDEEMON_DATA_DIR="$DATA"

URL=${TDEEMON_BASE_URL:-http://[ZIMAOS-IP-ADDRESS]:6722}
case $URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "TDEEMON_BASE_URL is still $URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings"
    URL=$(printf '%s' "$URL" | sed 's/\[ZIMAOS-IP-ADDRESS\]/localhost/') ;;
esac
export TDEEMON_BASE_URL="${URL%/}"

# ZimaOS passes settings left empty as empty strings; drop them.
for v in $(env | sed -n 's/^\(TDEEMON_[A-Z_]*\)=$/\1/p'); do unset "$v"; done

ADMIN_EMAIL=${ADMIN_EMAIL:-}
PASS_FILE=$DATA/.icestore/admin_password
(
  until wget -q -O /dev/null http://127.0.0.1:8080/healthz 2>/dev/null; do sleep 2; done
  if [ ! -f "$DATA/.icestore/admin_created" ] && [ -n "$ADMIN_EMAIL" ] && [ "$ADMIN_EMAIL" != "CHANGEME@example.com" ]; then
    [ -s "$PASS_FILE" ] || head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE"
    if /tdeemon user create --admin --email "$ADMIN_EMAIL" --timezone "${TZ:-UTC}" --password-stdin < "$PASS_FILE"; then
      : > "$DATA/.icestore/admin_created"
      log "made the first admin, $ADMIN_EMAIL"
    else
      log "could not make the first admin (it may already exist)"
    fi
  fi
  cred_reset
  cred_add URL "$TDEEMON_BASE_URL"
  if [ -f "$DATA/.icestore/admin_created" ] && [ -s "$PASS_FILE" ]; then
    cred_add EMAIL "$ADMIN_EMAIL"
    cred_add PASSWORD "$(cat "$PASS_FILE")"
    cred_note "Change the password in Settings once you are in."
  else
    cred_note "Set ADMIN_EMAIL in the app settings and restart to make the first admin."
  fi
  CRED_WAIT_SECONDS=0 /usr/local/lib/icestore/credentials.sh
) &

exec /tdeemon "$@"
