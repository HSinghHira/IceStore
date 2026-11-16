#!/bin/sh
# IceStore start script for FileBrowser Quantum.
#
#   - config.yaml missing (first start): a starter one is written with one
#     source, /srv (your ZimaOS files), and the cache in the data folder.
#     Edit it later in the Files app; it is never overwritten.
#   - FILEBROWSER_ADMIN_PASSWORD set: used as is.
#   - Blank or missing, new install: a random password, saved in
#     data/password.txt and shown in the CREDENTIALS box. FileBrowser only
#     uses it when it makes the admin user.
set -eu

DATA=/home/filebrowser/data
CONFIG=${FILEBROWSER_CONFIG:-$DATA/config.yaml}
DB=${FILEBROWSER_DATABASE_PATH:-$DATA/database.sqlite}
PASS_FILE=$DATA/password.txt
log() { echo "[icestore] $*"; }

umask 077
mkdir -p "$DATA"

if [ ! -s "$CONFIG" ]; then
  umask 022
  cat > "$CONFIG.tmp" <<'YAML'
# Made by IceStore on first start. Edit freely: it is never overwritten.
# All settings: https://filebrowserquantum.com/en/docs/configuration/
server:
  cacheDir: /home/filebrowser/data/tmp
  sources:
    - path: /srv
      name: files
      config:
        defaultEnabled: true
YAML
  mv "$CONFIG.tmp" "$CONFIG"
  umask 077
  log "first start: wrote config.yaml (your files are the source /srv)."
fi

# CREDENTIALS banner (docker/_common).
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh
cred_reset
cred_add URL "http://<your ZimaOS IP>:6738"
cred_add USERNAME admin

if [ -n "${FILEBROWSER_ADMIN_PASSWORD:-}" ]; then
  cred_add PASSWORD "(the one you set in FILEBROWSER_ADMIN_PASSWORD)"
elif [ -s "$PASS_FILE" ]; then
  FILEBROWSER_ADMIN_PASSWORD=$(cat "$PASS_FILE")
  cred_add PASSWORD "$FILEBROWSER_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/filebrowser-quantum/data/password.txt. If you changed it in FileBrowser, use your new one."
elif [ ! -e "$DB" ]; then
  head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  FILEBROWSER_ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made a random admin password (password.txt in the data folder)."
  cred_add PASSWORD "$FILEBROWSER_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/filebrowser-quantum/data/password.txt. Change it in FileBrowser under Settings if you like."
else
  cred_add PASSWORD "(the one you already use)"
fi
[ -z "${FILEBROWSER_ADMIN_PASSWORD:-}" ] || export FILEBROWSER_ADMIN_PASSWORD

/usr/local/lib/icestore/credentials.sh "http://127.0.0.1:80/health" &

cd /home/filebrowser
exec "$@"
