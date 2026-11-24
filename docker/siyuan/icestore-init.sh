#!/bin/sh
# IceStore start script for SiYuan. Makes this install's access code (the
# lock screen password) once and keeps it in the workspace folder, then hands
# over to upstream's entrypoint (which sets up the PUID/PGID user).
#   - SIYUAN_ACCESS_AUTH_CODE set in the app settings: used and saved.
#   - Blank or missing: the saved code is used, or a new one is made.
#   - SIYUAN_ACCESS_AUTH_CODE_BYPASS=true: no code at all (upstream's switch).
set -eu

WS=${SIYUAN_WORKSPACE_PATH:-/siyuan/workspace}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(SIYUAN_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$WS"
umask 077
FILE=$WS/.icestore-access-code
if [ -n "${SIYUAN_ACCESS_AUTH_CODE:-}" ]; then
  printf '%s' "$SIYUAN_ACCESS_AUTH_CODE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
elif [ ! -s "$FILE" ]; then
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
  log "first start: made this install's access code (.icestore-access-code in the workspace)"
fi
umask 022
SIYUAN_ACCESS_AUTH_CODE=$(cat "$FILE")
export SIYUAN_ACCESS_AUTH_CODE

cred_reset
cred_add URL "http://<your ZimaOS IP>:6807"
if [ "${SIYUAN_ACCESS_AUTH_CODE_BYPASS:-}" = "true" ]; then
  cred_note "SIYUAN_ACCESS_AUTH_CODE_BYPASS is true: SiYuan opens without an access code."
else
  cred_add "ACCESS CODE" "$SIYUAN_ACCESS_AUTH_CODE"
fi
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:6806/ &

exec /opt/siyuan/entrypoint.sh "$@"
