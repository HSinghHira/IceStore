#!/bin/bash
# IceStore start script for SiteWatcher. Runs as root, once per start:
#
#   - gives /data to the sitewatcher user (ZimaOS makes it as root),
#   - SITEWATCHER_WEB_ALLOWED_HOSTS: SiteWatcher only answers to host names
#     listed there (no wildcards), so your ZimaOS IP must be in it,
#   - first start: makes the owner account (SITEWATCHER_ADMIN_USER, password
#     from SITEWATCHER_ADMIN_PASSWORD or made here and kept in /data);
#     a SITEWATCHER_ADMIN_PASSWORD set later resets the owner's password.
#
# Then supervisord runs the web dashboard and the check worker.
set -euo pipefail

DATA=/data
PASS_FILE=$DATA/.icestore-admin-password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(\(SITEWATCHER\|TELEGRAM\|VIRUSTOTAL\)_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$DATA/cache"
chown -R sitewatcher:sitewatcher "$DATA"

# ---- host names the dashboard answers to ----
hosts=${SITEWATCHER_WEB_ALLOWED_HOSTS:-}
case $hosts in
  *"[ZIMAOS-IP-ADDRESS]"*|"")
    log "SITEWATCHER_WEB_ALLOWED_HOSTS is not set to your ZimaOS IP yet: put it in the app settings (like 192.168.1.20), or the dashboard answers 400 Bad Request"
    hosts="" ;;
esac
hosts=$(printf '%s' "$hosts" | sed 's#https\?://##g; s#:[0-9]*##g; s#/##g; s# ##g')
export SITEWATCHER_WEB_ALLOWED_HOSTS="127.0.0.1,localhost${hosts:+,$hosts}"
export SITEWATCHER_WEB_BIND=0.0.0.0

# ---- owner account ----
SW_USER=${SITEWATCHER_ADMIN_USER:-admin}
RESET=
if [ -n "${SITEWATCHER_ADMIN_PASSWORD:-}" ]; then
  SW_PASS=$SITEWATCHER_ADMIN_PASSWORD
  RESET=--reset
elif [ -s "$PASS_FILE" ]; then
  SW_PASS=$(cat "$PASS_FILE")
else
  ( umask 077; python -c 'import secrets; print(secrets.token_urlsafe(12), end="")' > "$PASS_FILE" )
  chown sitewatcher:sitewatcher "$PASS_FILE"
  SW_PASS=$(cat "$PASS_FILE")
  log "first start: made the owner password ($PASS_FILE)"
fi
cd /app
SW_USER="$SW_USER" SW_PASS="$SW_PASS" \
  setpriv --reuid=sitewatcher --regid=sitewatcher --init-groups \
  python /usr/local/lib/icestore/sitewatcher-owner.py $RESET
unset SITEWATCHER_ADMIN_PASSWORD

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:7002/login/"
cred_add USER "$SW_USER"
if [ -n "$RESET" ]; then
  cred_add PASSWORD "(the one you set in SITEWATCHER_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$SW_PASS"
  cred_note "Also saved in /DATA/AppData/sitewatcher/data/.icestore-admin-password"
fi

[ -z "${AIO_DRY_RUN:-}" ] || exit 0
exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
