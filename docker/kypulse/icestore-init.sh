#!/bin/sh
# IceStore start script for KyPulse. Runs as root, gets the folders ready,
# then starts upstream's server as 10001:10001 (the user upstream's image
# runs as). KyPulse makes and keeps its own session secret (session.key) and
# audit key in production, so no secret is made here.
#
#   - Folders: KyPulse refuses to start ("setup socket directory has an
#     ancestor other users can modify") when a folder above <data>/installer
#     is group- or other-writable, as ZimaOS may make the bind folders. They
#     are made private (700) and owned by the app user on every start.
#   - Blank settings: ZimaOS passes a setting left empty as an empty string,
#     and KyPulse refuses to start on a blank true/false setting. Blank ones
#     are removed so KyPulse uses its own default.
#   - KYPULSE_APP_URL: the https address of the reverse proxy in front of
#     KyPulse. Sign-in only works on an https page (its sign-in check needs
#     one). While it is blank, the example address or plain http, the log
#     says to set the proxy's https address.
#   - The CREDENTIALS banner shows the first admin password.
#
# Commands inside the container: `kypulse <command>` (for example
# `docker exec -it kypulse kypulse version`) runs /app/kypulse as the app user.
set -eu

DATA=${ICESTORE_DATA:-/app/data}
BACKUPS=${ICESTORE_BACKUPS:-/app/backups}
SECRETS=${ICESTORE_SECRETS:-/app/secrets}
APP_UID=10001
APP_GID=10001
PORT=6878
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ---- folders: ZimaOS makes the bind folders as root ----
for d in "$DATA" "$BACKUPS" "$SECRETS"; do
  mkdir -p "$d"
  [ "$(stat -c %u:%g "$d")" = "$APP_UID:$APP_GID" ] || chown -R "$APP_UID:$APP_GID" "$d"
  chmod 700 "$d"
done
# The installer socket folder must be private and owned by the app user.
if [ -d "$DATA/installer" ]; then
  chown "$APP_UID:$APP_GID" "$DATA/installer"
  chmod 700 "$DATA/installer"
fi

# ---- blank settings ----
for v in KYPULSE_APP_URL KYPULSE_ADMIN_PASSWORD KYPULSE_TRUSTED_PROXIES KYPULSE_SESSION_SECRET \
         KYPULSE_KYSIGNON_ISSUER KYPULSE_KYSIGNON_CLIENT_ID KYPULSE_KYSIGNON_SECRET KYPULSE_KYSIGNON_HMAC_SECRET \
         KYPULSE_ALERT_ALLOW_HTTP KYPULSE_ALLOW_INSECURE_DEV KYPULSE_BACKUP_ALLOW_PRIVATE_RECOVERY \
         KYPULSE_COOKIE_SECURE KYPULSE_KYYARD_ALLOW_HTTP KYPULSE_SSO_AUTO_PROVISION KYPULSE_SSO_ENABLED \
         KYPULSE_BACKUP_KEEP KYPULSE_BACKUP_DEPOSIT_INTERVAL KYPULSE_POLL_WORKERS; do
  eval "_v=\${$v:-}"
  [ -n "$_v" ] || unset "$v"
done

# ---- the public address ----
if [ -z "${KYPULSE_APP_URL:-}" ]; then
  KYPULSE_APP_URL="http://localhost:$PORT"
  log "KYPULSE_APP_URL is not set: set it in the app settings to the https address of your reverse proxy (like Nginx Proxy Manager) pointed at http://<your ZimaOS IP>:$PORT. KyPulse only lets you sign in on an https page."
else
  KYPULSE_APP_URL=${KYPULSE_APP_URL%/}
  case $KYPULSE_APP_URL in
    *pulse.example.com*)
      log "KYPULSE_APP_URL is still the example $KYPULSE_APP_URL: set it to your own https address (a reverse proxy pointed at http://<your ZimaOS IP>:$PORT). KyPulse only lets you sign in on an https page." ;;
    http://*)
      log "KYPULSE_APP_URL is plain http ($KYPULSE_APP_URL): the page opens, but sign-in only works on https. Put an https reverse proxy in front and set KYPULSE_APP_URL to its address." ;;
  esac
fi
export KYPULSE_APP_URL

# Settings for `kypulse <command>` in `docker exec` (it doesn't run this script).
( umask 077; printf "KYPULSE_APP_URL='%s'\n" "$KYPULSE_APP_URL" > "$DATA/.icestore-env" )
chown "$APP_UID:$APP_GID" "$DATA/.icestore-env"

if [ -n "${AIO_DRY_RUN:-}" ]; then
  log "dry run: KYPULSE_APP_URL=$KYPULSE_APP_URL SSO_AUTO_PROVISION=${KYPULSE_SSO_AUTO_PROVISION-unset} COOKIE_SECURE=${KYPULSE_COOKIE_SECURE-unset}"
  exit 0
fi

# ---- after start: the CREDENTIALS banner ----
cred_reset
cred_add URL "$(cred_url "$KYPULSE_APP_URL")"
cred_add USER admin
(
  url=http://127.0.0.1:8080/healthz
  n=0
  until wget -q -O /dev/null -T 5 "$url" 2>/dev/null; do
    n=$((n + 3)); [ "$n" -lt 600 ] || exit 0
    sleep 3
  done
  if [ -s "$DATA/initial-admin-password" ]; then
    cred_add PASSWORD "$(cat "$DATA/initial-admin-password")"
    cred_note "First password, from initial-admin-password in the data folder. Change it after you sign in, then delete that file."
  else
    cred_note "The admin password is the one you set (KYPULSE_ADMIN_PASSWORD) or changed since."
  fi
  exec /usr/local/lib/icestore/credentials.sh "$url"
) &

# Docker gives stdout/stderr to root; let the app user write its log there.
chown "$APP_UID:$APP_GID" "/proc/$$/fd/1" "/proc/$$/fd/2"
exec setpriv --reuid="$APP_UID" --regid="$APP_GID" --clear-groups /app/kypulse "$@"
