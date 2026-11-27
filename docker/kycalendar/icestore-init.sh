#!/bin/sh
# IceStore start script for KyCalendar. Runs as root, gets the folders and
# this install's session secret ready, then starts upstream's server as
# 10001:10001 (the user upstream's image runs as).
#
#   - KY_SESSION_SECRET: KyCalendar refuses to start in production without
#     one (and makes a new one on every start otherwise, signing everyone
#     out). A value from the app settings is used and saved; blank means the
#     saved one, or a new one made on first start, kept in
#     /app/data/.icestore/ (back up the whole data folder).
#   - KY_APP_URL: the address people open. It must match the browser's
#     address exactly, or KyCalendar refuses sign-in and changes. While it
#     still has [ZIMAOS-IP-ADDRESS], localhost is used and the log says what
#     to do.
#   - Plain http address: KY_ALLOW_INSECURE_HTTP=true (production refuses
#     http without it) and KY_COOKIE_SECURE=false (browsers drop Secure
#     cookies on http, so sign-in would fail), unless you set them.
#   - SCIM stays off until you set KY_SCIM_TOKEN (32+ characters).
#   - The CREDENTIALS banner shows the first admin password.
#
# Commands inside the container: `kycalendar <command>` (for example
# `docker exec -it kycalendar kycalendar create-user ...`) runs
# /app/kycalendar with these settings, as the right user.
set -eu

DATA=${ICESTORE_DATA:-/app/data}
BACKUPS=${ICESTORE_BACKUPS:-/app/backups}
DIR=$DATA/.icestore
APP_UID=10001
APP_GID=10001
PORT=6876
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ---- folders: ZimaOS makes the bind folders as root ----
for d in "$DATA" "$BACKUPS"; do
  mkdir -p "$d"
  [ "$(stat -c %u:%g "$d")" = "$APP_UID:$APP_GID" ] || chown -R "$APP_UID:$APP_GID" "$d"
  # The app refuses to start ("setup socket directory has an ancestor
  # other users can modify") when a folder above <data>/installer is group- or
  # other-writable, as ZimaOS may make the bind folders. Private on every start,
  # so an existing install recovers too.
  chmod 700 "$d"
done
# The installer socket folder must be private and owned by the app user.
if [ -d "$DATA/installer" ]; then
  chown "$APP_UID:$APP_GID" "$DATA/installer"
  chmod 700 "$DATA/installer"
fi
mkdir -p "$DIR"
chown "$APP_UID:$APP_GID" "$DIR"
chmod 700 "$DIR"

# make_secret NAME BYTES: NAME from the app settings, the saved file, or new.
make_secret() {
  _f="$DIR/$(echo "$1" | tr 'A-Z_' 'a-z-')"
  eval "_v=\${$1:-}"
  ( umask 077
    if [ -n "$_v" ]; then
      if [ -s "$_f" ] && [ "$(cat "$_f")" != "$_v" ]; then
        cp "$_f" "$_f.previous"
        log "$1 from the app settings differs from the saved one; using it (old one kept as $_f.previous)."
      fi
      printf '%s' "$_v" > "$_f.tmp" && mv "$_f.tmp" "$_f"
    elif [ ! -s "$_f" ]; then
      head -c "$2" /dev/urandom | od -An -tx1 | tr -d ' \n' > "$_f.tmp" && mv "$_f.tmp" "$_f"
      log "first start: made $1 (kept in the data folder, .icestore/)."
    fi )
  chown "$APP_UID:$APP_GID" "$_f"
  eval "$1=\$(cat \"\$_f\")"
  export "$1"
}

make_secret KY_SESSION_SECRET 32

# ---- the public address ----
[ -n "${KY_APP_URL:-}" ] || KY_APP_URL="http://[ZIMAOS-IP-ADDRESS]:$PORT"
case $KY_APP_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "KY_APP_URL is still $KY_APP_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, like http://192.168.1.20:$PORT, or with your https address behind a reverse proxy."
    log "Until then KyCalendar only works on the ZimaOS box itself, at http://localhost:$PORT; other devices can't sign in."
    KY_APP_URL=$(printf '%s' "$KY_APP_URL" | sed 's/\[ZIMAOS-IP-ADDRESS\]/localhost/') ;;
esac
KY_APP_URL=${KY_APP_URL%/}
case $KY_APP_URL in
  https://*) ;;
  *) [ -n "${KY_ALLOW_INSECURE_HTTP:-}" ] || KY_ALLOW_INSECURE_HTTP=true
     [ -n "${KY_COOKIE_SECURE:-}" ] || KY_COOKIE_SECURE=false
     export KY_ALLOW_INSECURE_HTTP KY_COOKIE_SECURE
     log "KY_APP_URL is plain http, so sign-in cookies don't get the Secure flag. Use an https address behind a reverse proxy for access from outside your home network." ;;
esac
export KY_APP_URL

# ZimaOS passes a setting left empty as an empty string; drop those so
# KyCalendar uses its own default (SCIM off without a token). Upstream reads a
# blank boolean as false, so a blank KY_SSO_AUTO_PROVISION would turn it off.
for v in KY_ADMIN_PASSWORD KY_SCIM_TOKEN KY_SCIM_ENABLED KY_TRUSTED_PROXIES KY_RATE_LIMIT_EXEMPT_NETWORKS \
         KY_KYSIGNON_ISSUER KY_KYSIGNON_CLIENT_ID KY_KYSIGNON_SECRET KY_KYSIGNON_HMAC_SECRET \
         KY_SSO_ENABLED KY_SSO_AUTO_PROVISION KY_COOKIE_SECURE KY_ALLOW_INSECURE_HTTP \
         KYCALENDAR_BACKUP_KEEP KYCALENDAR_BACKUP_DEPOSIT_INTERVAL KYCALENDAR_BACKUP_ALLOW_PRIVATE_RECOVERY \
         KYCALENDAR_SCHEDULING KY_CALENDAR_MAX_BYTES_TOTAL KY_CALENDAR_MAX_BYTES_PER_USER; do
  eval "_v=\${$v:-}"
  [ -n "$_v" ] || unset "$v"
done

# Settings for `kycalendar <command>` in `docker exec` (it doesn't run this script).
( umask 077
  { printf "KY_APP_URL='%s'\n" "$KY_APP_URL"
    [ -z "${KY_COOKIE_SECURE:-}" ] || printf "KY_COOKIE_SECURE='%s'\n" "$KY_COOKIE_SECURE"
    [ -z "${KY_ALLOW_INSECURE_HTTP:-}" ] || printf "KY_ALLOW_INSECURE_HTTP='%s'\n" "$KY_ALLOW_INSECURE_HTTP"
  } > "$DIR/env" )
chown "$APP_UID:$APP_GID" "$DIR/env"

if [ -n "${AIO_DRY_RUN:-}" ]; then
  log "dry run: KY_APP_URL=$KY_APP_URL KY_COOKIE_SECURE=${KY_COOKIE_SECURE:-default} KY_ALLOW_INSECURE_HTTP=${KY_ALLOW_INSECURE_HTTP:-default} KY_SESSION_SECRET=${#KY_SESSION_SECRET} chars"
  exit 0
fi

# ---- after start: the CREDENTIALS banner ----
cred_reset
cred_add URL "$(cred_url "$KY_APP_URL")"
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
    cred_note "The admin password is the one you set (KY_ADMIN_PASSWORD) or changed since."
  fi
  exec /usr/local/lib/icestore/credentials.sh "$url"
) &

# Docker gives stdout/stderr to root; let the app user write its log there.
chown "$APP_UID:$APP_GID" "/proc/$$/fd/1" "/proc/$$/fd/2"
exec setpriv --reuid="$APP_UID" --regid="$APP_GID" --clear-groups /app/kycalendar "$@"
