#!/bin/sh
# IceStore start script for Root Cellar: makes each app's data folder, keeps
# the Labels printer setup (CUPS) in the data folder as upstream's labels
# entrypoint does, then starts the four apps and the print system.
set -eu

LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p /data/checkbook /data/notes/backups /data/movies /data/labels/cups

# Upstream's labels entrypoint: the printer setup lives in /data/labels/cups.
[ -f /data/labels/cups/cupsd.conf ] || cp -a /etc/cups.default/. /data/labels/cups/
if [ ! -L /etc/cups ]; then rm -rf /etc/cups && ln -s /data/labels/cups /etc/cups; fi

cred_reset
cred_add CHECKBOOK "http://<your ZimaOS IP>:6711"
cred_add NOTES "http://<your ZimaOS IP>:6712"
cred_add MOVIES "http://<your ZimaOS IP>:6713"
cred_add LABELS "http://<your ZimaOS IP>:6714"
cred_note "Open each address in your browser; on phones, add it to the Home Screen."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/ &

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
