#!/bin/sh
# IceStore start script for Bugsink. Runs as root, once per start:
#   - SECRET_KEY and the first admin's password: from the app settings, else
#     made on first start and kept in /data;
#   - CREATE_SUPERUSER=<ADMIN_EMAIL>:<password> (Bugsink only uses it while
#     there are no users yet);
#   - ALLOWED_HOSTS: BASE_URL's host plus localhost (for the healthcheck);
#   - /data and stdout/stderr go to the bugsink user, then upstream's start
#     command runs as that user.
set -eu

DIR=/data
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so Bugsink's
# defaults apply.
for v in $(env | sed -n 's/^\([A-Z][A-Z0-9_]*\)=$/\1/p'); do
  case $v in TZ|PATH|HOME) ;; *) unset "$v" ;; esac
done

mkdir -p "$DIR"
# make_secret NAME BYTES: NAME from the app settings, the saved file, or new.
make_secret() {
  _f="$DIR/.icestore-$(echo "$1" | tr 'A-Z_' 'a-z-')"
  eval "_v=\${$1:-}"
  ( umask 077
    if [ -n "$_v" ]; then
      printf '%s' "$_v" > "$_f.tmp" && mv "$_f.tmp" "$_f"
    elif [ ! -s "$_f" ]; then
      head -c "$2" /dev/urandom | od -An -tx1 | tr -d ' \n' > "$_f.tmp" && mv "$_f.tmp" "$_f"
      log "first start: made $1 ($_f)"
    fi )
  eval "$1=\$(cat \"\$_f\")"
  export "$1"
}
make_secret SECRET_KEY 32
make_secret ADMIN_PASSWORD 12
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
export CREATE_SUPERUSER="$ADMIN_EMAIL:$ADMIN_PASSWORD"

# ---- public address ----
BASE_URL=${BASE_URL:-http://[ZIMAOS-IP-ADDRESS]:7008}
BASE_URL=${BASE_URL%/}
case $BASE_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "BASE_URL is still $BASE_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, or Bugsink answers 400 Bad Request"
    BASE_URL=$(printf '%s' "$BASE_URL" | sed 's/\[ZIMAOS-IP-ADDRESS\]/localhost/') ;;
esac
export BASE_URL
if [ -z "${ALLOWED_HOSTS:-}" ]; then
  host=${BASE_URL#*://}; host=${host%%/*}; host=${host%:*}
  export ALLOWED_HOSTS="$host,localhost,127.0.0.1"
fi
export TIME_ZONE=${TIME_ZONE:-${TZ:-UTC}}

cred_reset
cred_add "URL" "$BASE_URL"
cred_add "EMAIL" "$ADMIN_EMAIL"
cred_add "PASSWORD" "$ADMIN_PASSWORD"
cred_note "Only used for the first account. Change it in Bugsink after you sign in."
/usr/local/lib/icestore/credentials.sh &

chown -R bugsink:bugsink "$DIR"
# Docker gives the log pipes to root; hand them to bugsink too.
chown bugsink:bugsink "/proc/$$/fd/1" "/proc/$$/fd/2"
unset ADMIN_PASSWORD
exec setpriv --reuid=bugsink --regid=bugsink --init-groups "$@"
