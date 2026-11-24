#!/bin/sh
# IceStore start script for copyparty. On first start (no *.conf in /cfg yet)
# it writes /cfg/copyparty.conf: the admin account with this install's
# password, the whole of /w (your ZimaOS storage) for admin only, and the
# search index and thumbnails in /cfg/hist instead of inside your files.
# After that copyparty.conf is yours to edit; it is never rewritten.
#   - COPYPARTY_PASSWORD set in the app settings before the first start:
#     used as the admin password.
# Then hands over to upstream's own start-up (loads every /cfg/*.conf).
set -eu

CFG=${ICESTORE_CONFIG:-/cfg}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$CFG"
umask 077
FILE=$CFG/.icestore-password
if [ ! -s "$FILE" ]; then
  if [ -n "${COPYPARTY_PASSWORD:-}" ]; then
    printf '%s' "$COPYPARTY_PASSWORD" > "$FILE.tmp"
  else
    head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$FILE.tmp"
  fi
  mv "$FILE.tmp" "$FILE"
fi
PASS=$(cat "$FILE")
ADMIN=${COPYPARTY_USER:-admin}
unset COPYPARTY_PASSWORD

if ! ls "$CFG"/*.conf >/dev/null 2>&1; then
  cat > "$CFG/copyparty.conf" <<EOF
# copyparty settings, written by IceStore on first start. Edit freely:
# copyparty reads every *.conf in this folder when it starts.
# All options: https://github.com/9001/copyparty#the-browser
# Example with more users and folders:
# https://github.com/9001/copyparty/blob/hovudstraum/docs/example.conf

[global]
  e2dsa             # index every file, for search and finding duplicates
  e2ts              # read music and video tags
  hist: /cfg/hist   # keep the index and thumbnails here, not in your files
  ansi              # colours in the log
  no-robots         # ask search engines to stay away
  # ipa: lan        # only allow connections from your home network
  # grid            # show thumbnails by default

[accounts]
  $ADMIN: $PASS   # user name: password

[/]                 # the whole share, at the web root
  /w                # your ZimaOS storage (/DATA)
  accs:
    rwmda: $ADMIN   # read, write, move, delete, admin

# A public read-only folder, for example /DATA/Public:
# [/public]
#   /w/Public
#   accs:
#     r: *
EOF
  log "first start: wrote /cfg/copyparty.conf with the $ADMIN account"
fi
umask 022

cred_reset
cred_add URL "http://<your ZimaOS IP>:6809"
cred_add USER "$ADMIN"
cred_add PASSWORD "$PASS"
cred_note "This is the account copyparty.conf was first written with; if you changed it there, use yours."
/usr/local/lib/icestore/credentials.sh &

exec /bin/ash /z/cpp.sh -c /z/initcfg "$@"
