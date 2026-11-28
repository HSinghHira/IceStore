#!/bin/sh
# IceStore start script for KyDNS. KyDNS checks every folder above its setup
# socket and stops with "setup socket directory has an ancestor other users
# can modify" when one is writable by group or others (unless it is a
# root-owned sticky folder like /tmp). ZimaOS can make the bind-mounted data
# folder 0775 or 0777, so take those write bits off the data folder, then
# start KyDNS.
set -eu

LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

DATA=/var/lib/kydns
mkdir -p "$DATA"
# KyDNS also refuses a folder owned by someone other than root or itself.
# Only the folders themselves change, not the files inside them.
for d in "$DATA" "$DATA/installer"; do
  [ -d "$d" ] || continue
  chown 0:0 "$d"
  chmod go-w "$d"
done
log "data folder $DATA is now $(stat -c '%a %U' "$DATA") (KyDNS needs it private)"

exec "$@"
