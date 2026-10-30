#!/bin/sh
# IceStore start script for GitHub Release Monitor.
#
#   - BETTER_AUTH_SECRET and AUTH_SETUP_TOKEN: a value from the app settings
#     is used and written to the data folder. Blank or missing: the one in
#     the file is used, or a new random one is made on first start.
#   - The setup token is printed in the log on every start until the first
#     account exists (upstream writes auth-setup.lock then).
#   - Sign-in works from home-network addresses on port 6182 (unless
#     GRM_TRUST_LAN=false); BETTER_AUTH_URL is only needed for links in
#     emails and an https domain. Blank = http://localhost:6182.
#   - HTTPS defaults to false, since ZimaOS serves the app on plain http.
#   - /app/data is given to upstream's nextjs user, then the app runs as
#     that user.
# All paths can be moved for testing outside Docker (ICESTORE_DATA, ...).
set -eu

DATA=${ICESTORE_DATA:-/app/data}
APP_PORT=6182
APP_USER=${ICESTORE_APP_USER:-nextjs}
log() { echo "[icestore] $*"; }

mkdir -p "$DATA"

# keep_secret NAME FILE: the value from the variable, the file, or new.
keep_secret() {
  name=$1 file=$DATA/$2
  eval "val=\${$name:-}"
  old_umask=$(umask)
  umask 077
  if [ -n "$val" ]; then
    if [ -s "$file" ] && [ "$(cat "$file")" != "$val" ]; then
      log "$name differs from the one used before; using $name. The old one is saved as $2.previous."
      cp "$file" "$file.previous"
    fi
    printf '%s' "$val" > "$file.tmp"
    mv "$file.tmp" "$file"
  elif [ ! -s "$file" ]; then
    # 32 random bytes as 64 hex characters (upstream needs 32 or more).
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$file.tmp"
    mv "$file.tmp" "$file"
    log "first start: made this install's $name in the data folder ($2)."
  fi
  umask "$old_umask"
  eval "$name=\$(cat \"\$file\")"
  export "$name"
}

keep_secret BETTER_AUTH_SECRET .better_auth_secret
keep_secret AUTH_SETUP_TOKEN .auth_setup_token

if [ ! -e "$DATA/auth-setup.lock" ]; then
  log "========================================================================"
  log "No account yet. Open http://<your ZimaOS IP>:$APP_PORT and make one."
  log "Setup token: $AUTH_SETUP_TOKEN"
  log "========================================================================"
fi

# ---- the address people open the app at ---------------------------------
LOCAL_URL=http://localhost:$APP_PORT
[ -n "${BETTER_AUTH_URL:-}" ] || BETTER_AUTH_URL=$LOCAL_URL
case $BETTER_AUTH_URL in
  *"[ZIMAOS-IP-ADDRESS]"*) BETTER_AUTH_URL=$LOCAL_URL ;;
esac
BETTER_AUTH_URL=${BETTER_AUTH_URL%/}
export BETTER_AUTH_URL

add_origin() {
  case ",$origins," in
    *",$1,"*) ;;
    *) origins=${origins:+$origins,}$1 ;;
  esac
}
origins=${BETTER_AUTH_TRUSTED_ORIGINS:-}
add_origin "$LOCAL_URL"
# Better Auth only accepts sign-ins from trusted origins. Trust the private
# address ranges (home network, Tailscale, .local names) on this port, so
# http://<ZimaOS IP>:6182 works without setting anything. Better Auth's '*'
# also matches dots.
if [ "${GRM_TRUST_LAN:-true}" != false ]; then
  for p in "http://127.0.0.1" "http://192.168.*" "http://10.*" "http://172.*" \
           "http://100.*" "http://*.local"; do
    add_origin "$p:$APP_PORT"
  done
fi
BETTER_AUTH_TRUSTED_ORIGINS=$origins
export BETTER_AUTH_TRUSTED_ORIGINS

# Plain http unless someone says otherwise, or sign-in cookies are dropped.
[ -n "${HTTPS:-}" ] || HTTPS=false
export HTTPS

# Blank values from the app settings mean "use the default": drop them so
# the app's own defaults apply.
for name in AUTHENTICATION_METHOD AUTH_LOGIN_LOCKOUT_SECONDS AUTH_LOGIN_WINDOW_SECONDS \
            AUTH_MAX_LOGIN_ATTEMPTS AUTH_TRUST_PROXY_HEADERS AUTH_TRUSTED_PROXY_HOPS \
            AUTH_ENABLE_SIGNUP AUTH_ENABLE_PASSKEY AUTH_PASSWORD_RESET_TOKEN_TTL_SECONDS \
            AUTH_TRUST_SOCIAL_LINKING AUTH_GITHUB_CLIENT_ID AUTH_GITHUB_CLIENT_SECRET \
            AUTH_GOOGLE_CLIENT_ID AUTH_GOOGLE_CLIENT_SECRET GITHUB_ACCESS_TOKEN \
            GITLAB_ADDITIONAL_HOSTS GITLAB_ACCESS_TOKENS GITLAB_DEPLOY_TOKENS \
            CODEBERG_ACCESS_TOKEN FORGEJO_ADDITIONAL_BASE_URLS FORGEJO_ACCESS_TOKENS \
            LOG_LEVEL MAIL_HOST MAIL_PORT MAIL_USERNAME MAIL_PASSWORD MAIL_FROM_ADDRESS \
            MAIL_FROM_NAME MAIL_TO_ADDRESS MAIL_TLS_REJECT_UNAUTHORIZED APPRISE_URL; do
  eval "val=\${$name-unset}"
  [ -n "$val" ] || unset "$name"
done

if [ -n "${ICESTORE_DRY_RUN:-}" ]; then
  env | grep -E '^(BETTER_AUTH_|AUTH_SETUP_TOKEN|HTTPS|LOG_LEVEL|MAIL_)' | sort
  exit 0
fi

# ---- hand over to upstream ----------------------------------------------
if [ "$(id -u)" = 0 ]; then
  uid=$(id -u "$APP_USER")
  gid=$(id -g "$APP_USER")
  if [ -n "$(find "$DATA" \( ! -user "$uid" -o ! -group "$gid" \) -print -quit)" ]; then
    chown -R "$uid:$gid" "$DATA"
  fi
  export HOME=/home/$APP_USER
  exec su-exec "$uid:$gid" docker-entrypoint.sh "$@"
fi
exec docker-entrypoint.sh "$@"
