#!/bin/sh
# IceStore start script for KyDrive. Runs as root, gets the folders and this
# install's secrets ready, then starts upstream's server as 1000:1000 (the
# user upstream's image runs as).
#
#   - KY_SESSION_SECRET and KY_SCIM_TOKEN: KyDrive refuses to start in
#     production without them. A value from the app settings is used and
#     saved; blank means the saved one, or a new one made on first start.
#     Both are kept in /app/data/.icestore/ (back up the whole data folder).
#   - KY_APP_URL: the address people open. It must match the browser's
#     address exactly, or KyDrive refuses sign-in and uploads. While it still
#     has [ZIMAOS-IP-ADDRESS], localhost is used and the log says what to do.
#   - KY_COOKIE_SECURE: blank means off for an http:// address (browsers drop
#     Secure cookies there, so sign-in would fail) and on for https://.
#   - After the server answers, `bulk-init` sets up the file backup
#     repository in /app/bulk (it changes nothing when it already exists),
#     and the CREDENTIALS banner shows the first admin password.
#
# Commands inside the container: `kydrive <command>` (for example
# `docker exec -it kydrive kydrive rename-local-admin -from admin -to x`)
# runs /app/kydrive-server with these settings, as the right user.
set -eu

DATA=${ICESTORE_DATA:-/app/data}
BACKUPS=${ICESTORE_BACKUPS:-/app/backups}
BULK=${ICESTORE_BULK:-/app/bulk}
DIR=$DATA/.icestore
APP_UID=1000
APP_GID=1000
PORT=6875
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ---- folders: ZimaOS makes the bind folders as root ----
for d in "$DATA" "$BACKUPS" "$BULK"; do
  mkdir -p "$d"
  [ "$(stat -c %u:%g "$d")" = "$APP_UID:$APP_GID" ] || chown -R "$APP_UID:$APP_GID" "$d"
done
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
make_secret KY_SCIM_TOKEN 32

# ---- the public address ----
[ -n "${KY_APP_URL:-}" ] || KY_APP_URL="http://[ZIMAOS-IP-ADDRESS]:$PORT"
case $KY_APP_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "KY_APP_URL is still $KY_APP_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, like http://192.168.1.20:$PORT, or with your https address behind a reverse proxy."
    log "Until then KyDrive only works on the ZimaOS box itself, at http://localhost:$PORT; other devices can't sign in."
    KY_APP_URL=$(printf '%s' "$KY_APP_URL" | sed 's/\[ZIMAOS-IP-ADDRESS\]/localhost/') ;;
esac
KY_APP_URL=${KY_APP_URL%/}
if [ -z "${KY_COOKIE_SECURE:-}" ]; then
  case $KY_APP_URL in
    https://*) KY_COOKIE_SECURE=true ;;
    *) KY_COOKIE_SECURE=false
       log "KY_APP_URL is plain http, so sign-in cookies don't get the Secure flag. Use an https address behind a reverse proxy for access from outside your home network." ;;
  esac
fi
export KY_APP_URL KY_COOKIE_SECURE

# ZimaOS passes a setting left empty as an empty string; drop those so
# KyDrive uses its own default.
for v in KY_ADMIN_PASSWORD KY_TRUSTED_PROXIES KY_RATE_LIMIT_EXEMPT_NETWORKS \
         KY_KYSIGNON_ISSUER KY_KYSIGNON_CLIENT_ID KY_KYSIGNON_SECRET KY_SSO_ENABLED \
         KY_SSO_AUTO_PROVISION KYDRIVE_IDENTITY_URL KYDRIVE_EDITOR_URL KYDRIVE_EDITOR_SECRET \
         KY_BACKUP_DEPOSIT_INTERVAL KY_BACKUP_KEEP KYDRIVE_MAX_FILE_SIZE KYDRIVE_MAX_ZIP_SIZE \
         KYDRIVE_CONTENT_SEARCH KY_READ_TIMEOUT KY_WRITE_TIMEOUT; do
  eval "_v=\${$v:-}"
  [ -n "$_v" ] || unset "$v"
done

# Settings for `kydrive <command>` in `docker exec` (it doesn't run this script).
( umask 077
  { printf "KY_APP_URL='%s'\n" "$KY_APP_URL"
    printf "KY_COOKIE_SECURE='%s'\n" "$KY_COOKIE_SECURE"; } > "$DIR/env" )

if [ -n "${AIO_DRY_RUN:-}" ]; then
  log "dry run: KY_APP_URL=$KY_APP_URL KY_COOKIE_SECURE=$KY_COOKIE_SECURE KY_SESSION_SECRET=${#KY_SESSION_SECRET} chars KY_SCIM_TOKEN=${#KY_SCIM_TOKEN} chars"
  exit 0
fi

# ---- after start: backup repository and the CREDENTIALS banner ----
cred_reset
cred_add URL "$(cred_url "$KY_APP_URL")"
cred_add USER admin
(
  url=http://127.0.0.1:8080/readyz
  n=0
  until wget -q -O /dev/null -T 5 "$url" 2>/dev/null; do
    n=$((n + 3)); [ "$n" -lt 600 ] || exit 0
    sleep 3
  done
  if setpriv --reuid="$APP_UID" --regid="$APP_GID" --clear-groups /app/kydrive-server bulk-init; then
    log "file backup repository ready in $BULK."
  else
    log "bulk-init failed (see above): KyDrive runs, but its file backups won't until this is fixed."
  fi
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
exec setpriv --reuid="$APP_UID" --regid="$APP_GID" --clear-groups /app/kydrive-server "$@"
