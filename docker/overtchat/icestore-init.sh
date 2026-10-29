#!/bin/sh
# IceStore start script for OvertChat.
#
#   - BETTER_AUTH_SECRET set (from the app settings): used and written to the
#     data folder. Blank or missing: the one in /app/data/.better_auth_secret
#     is used, or a new random one is made on first start.
#   - BETTER_AUTH_URL still has [ZIMAOS-IP-ADDRESS] in it: OvertChat starts on
#     localhost and the log says what to change. Sign-in from other devices
#     only works once the real address is set.
#   - /app/data is given to upstream's nextjs user, then upstream's
#     entrypoint runs the app as that user.
# All paths can be moved for testing outside Docker (ICESTORE_DATA, ...).
set -eu

DATA=${ICESTORE_DATA:-/app/data}
SECRET_FILE=$DATA/.better_auth_secret
APP_PORT=6139
APP_USER=${ICESTORE_APP_USER:-nextjs}
log() { echo "[icestore] $*"; }

mkdir -p "$DATA"

# ---- per-install session secret ----------------------------------------
old_umask=$(umask)
umask 077
if [ -n "${BETTER_AUTH_SECRET:-}" ]; then
  if [ -s "$SECRET_FILE" ] && [ "$(cat "$SECRET_FILE")" != "$BETTER_AUTH_SECRET" ]; then
    log "BETTER_AUTH_SECRET differs from the one used before; using BETTER_AUTH_SECRET (everyone has to sign in again)."
    cp "$SECRET_FILE" "$SECRET_FILE.previous"
  fi
  printf '%s' "$BETTER_AUTH_SECRET" > "$SECRET_FILE.tmp"
  mv "$SECRET_FILE.tmp" "$SECRET_FILE"
elif [ ! -s "$SECRET_FILE" ]; then
  # 32 random bytes as 64 hex characters, like upstream's `openssl rand -hex 32`.
  head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$SECRET_FILE.tmp"
  mv "$SECRET_FILE.tmp" "$SECRET_FILE"
  log "first start: made this install's BETTER_AUTH_SECRET in the data folder (.better_auth_secret)."
fi
umask "$old_umask"
BETTER_AUTH_SECRET=$(cat "$SECRET_FILE")
export BETTER_AUTH_SECRET

# ---- the address people open OvertChat at -------------------------------
LOCAL_URL=http://localhost:$APP_PORT
[ -n "${BETTER_AUTH_URL:-}" ] || BETTER_AUTH_URL="http://[ZIMAOS-IP-ADDRESS]:$APP_PORT"
case $BETTER_AUTH_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "BETTER_AUTH_URL is still $BETTER_AUTH_URL."
    log "Replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, like http://192.168.1.20:$APP_PORT,"
    log "or signing in from other devices fails with 'Invalid origin'. Until then only $LOCAL_URL works."
    BETTER_AUTH_URL=$LOCAL_URL ;;
esac
BETTER_AUTH_URL=${BETTER_AUTH_URL%/}
export BETTER_AUTH_URL

# Signing in on the box itself keeps working too, as upstream's "home
# network" setup does.
origins=${EXTRA_TRUSTED_ORIGINS:-}
if [ "$BETTER_AUTH_URL" != "$LOCAL_URL" ]; then
  case ",$origins," in
    *",$LOCAL_URL,"*) ;;
    *) origins=${origins:+$origins,}$LOCAL_URL ;;
  esac
fi
EXTRA_TRUSTED_ORIGINS=$origins
export EXTRA_TRUSTED_ORIGINS

# A Host Connector on another computer reaches the server at its address.
[ -n "${HOST_CONNECTOR_URL:-}" ] || HOST_CONNECTOR_URL=$BETTER_AUTH_URL
export HOST_CONNECTOR_URL

# No bundled search or speech containers here; updates come from the store.
[ -n "${OVERTCHAT_INSTALLED_CAPABILITIES:-}" ] || OVERTCHAT_INSTALLED_CAPABILITIES=""
[ -n "${OVERTCHAT_UPDATE_METHOD:-}" ] || OVERTCHAT_UPDATE_METHOD=compose
export OVERTCHAT_INSTALLED_CAPABILITIES OVERTCHAT_UPDATE_METHOD

# Blank values from the app settings mean "use the default": drop them so
# the app's own defaults apply.
for name in REDIS_URL SEARXNG_URL KOKORO_URL STT_URL STT_API_KEY STT_PROVIDER STT_MODEL \
            TTS_PROVIDER TTS_MODEL TTS_VOICE TTS_API_KEY WEB_SEARCH_PROVIDER \
            BRAVE_SEARCH_API_KEY SANDBOX_URL SANDBOX_TOKEN DISABLE_UPDATE_CHECK \
            OVERTCHAT_REQUIRE_ADMIN_TWO_FACTOR; do
  eval "val=\${$name-unset}"
  [ -n "$val" ] || unset "$name"
done

if [ -n "${ICESTORE_DRY_RUN:-}" ]; then
  env | grep -E '^(BETTER_AUTH_|EXTRA_TRUSTED|HOST_CONNECTOR|OVERTCHAT_|REDIS_URL|SEARXNG_URL)' | sort
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
  exec setpriv --reuid="$uid" --regid="$gid" --init-groups -- docker-entrypoint.sh "$@"
fi
exec docker-entrypoint.sh "$@"
