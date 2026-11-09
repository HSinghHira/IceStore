#!/bin/sh
# IceStore start script for byagent. Makes this install's ADMIN_TOKEN and
# KEY_SIGNING_SECRET once, keeps them in the data folder, fills in the public
# addresses from PUBLIC_URL, then starts upstream's server.
#   - A value set in the app settings wins and is saved to the file.
#   - Blank or missing: the saved value is used, or a new one is made.
set -eu

DATA=${DATA_DIR:-/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA"
umask 077

# keep NAME FILE: export NAME from the app settings, the file, or a new value.
keep() {
  name=$1 file=$DATA/$2
  eval "val=\${$name:-}"
  if [ -n "$val" ]; then
    if [ -s "$file" ] && [ "$(cat "$file")" != "$val" ]; then
      cp "$file" "$file.previous"
      log "$name differs from the saved one; using the new value (old one kept as $2.previous)"
    fi
    printf '%s' "$val" > "$file.tmp" && mv "$file.tmp" "$file"
  elif [ ! -s "$file" ]; then
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$file.tmp" && mv "$file.tmp" "$file"
    log "first start: made $name in the data folder ($2). Back it up with the rest of the folder."
  fi
  eval "export $name=\"\$(cat \"\$file\")\""
}
keep ADMIN_TOKEN .admin-token
keep KEY_SIGNING_SECRET .key-signing-secret

# One public address for links, the API and the dashboard.
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6699}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "PUBLIC_URL is still $PUBLIC_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, or links will say localhost"
    PUBLIC_URL=$(printf '%s' "$PUBLIC_URL" | sed 's/\[ZIMAOS-IP-ADDRESS\]/localhost/') ;;
esac
[ -n "${PUBLIC_SHARE_ORIGIN:-}" ] || PUBLIC_SHARE_ORIGIN=$PUBLIC_URL
[ -n "${PUBLIC_API_ORIGIN:-}" ] || PUBLIC_API_ORIGIN=$PUBLIC_URL
# Dashboard sign-in: "log" prints each sign-in code in the app's logs, so only
# someone who can read the logs can sign in. Set resend (or GitHub) for email.
[ -n "${EMAIL_PROVIDER:-}" ] || EMAIL_PROVIDER=log
export PUBLIC_SHARE_ORIGIN PUBLIC_API_ORIGIN EMAIL_PROVIDER DATA_DIR="$DATA"

cred_reset
cred_add URL "$(cred_url "$PUBLIC_API_ORIGIN/app/login")"
cred_add "ADMIN TOKEN" "$ADMIN_TOKEN"
cred_note "Sign in to the dashboard with any email; with EMAIL_PROVIDER=log the code appears in these logs."
cred_note "The admin token is an API key: byagent login --key <token> --server $(cred_url "$PUBLIC_API_ORIGIN")"
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/healthz &

exec /artifacts-server "$@"
