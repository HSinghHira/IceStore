#!/bin/bash
# IceStore start script for Baserow's all-in-one image. Upstream already makes
# every secret itself (SECRET_KEY, the JWT key, the database and Redis
# passwords, kept in /baserow/data), so this only:
#
#   - swaps a BASEROW_PUBLIC_URL that still has [ZIMAOS-IP-ADDRESS] for
#     localhost (so the bundled Caddy can start) and says in the log what to
#     set: the browser calls Baserow's API at this address;
#   - drops blank variables, so Baserow uses its defaults (ZimaOS passes
#     settings left empty as empty strings);
#   - prints the address in a CREDENTIALS box.
#
# Then it hands over to upstream's /baserow.sh unchanged.
set -eu

LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

BASEROW_PUBLIC_URL=${BASEROW_PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6766}
case $BASEROW_PUBLIC_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "BASEROW_PUBLIC_URL is still $BASEROW_PUBLIC_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, like http://192.168.1.20:6766. Until then Baserow only works at http://localhost:6766."
    BASEROW_PUBLIC_URL=${BASEROW_PUBLIC_URL//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
export BASEROW_PUBLIC_URL

for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done

cred_reset
cred_add URL "$(cred_url "$BASEROW_PUBLIC_URL")"
cred_note "No account yet: click Sign up. The first account becomes the instance admin."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8000/api/_health/ &

exec /baserow.sh "$@"
