#!/bin/sh
# IceStore start script for Kestello. On the first start (an empty site
# folder) it copies in the release this image was built with; after that the
# files belong to Kestello, which updates itself. Then it makes the writable
# folders upstream's entrypoint makes and starts php-fpm and nginx.
set -eu

SITE=/var/www/html
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

if [ ! -f "$SITE/public/index.php" ]; then
  log "first start: copying Kestello $(cat /usr/src/kestello/.icestore-version) into the site folder"
  cp -a /usr/src/kestello/. "$SITE/"
fi

# Upstream's docker/entrypoint.sh: the folders Kestello writes to.
mkdir -p "$SITE/config" "$SITE/storage/cache" "$SITE/storage/logs" \
         "$SITE/storage/sessions" "$SITE/storage/compiled"
# Kestello writes its config, content, uploads and its own updates, so
# php-fpm (www-data) owns the whole site folder.
chown -R www-data:www-data "$SITE"

# The container's time zone for PHP too.
if [ -n "${TZ:-}" ] && [ -e "/usr/share/zoneinfo/$TZ" ]; then
  printf 'date.timezone = %s\n' "$TZ" > /usr/local/etc/php/conf.d/zz-timezone.ini
fi

cred_reset
cred_add URL "http://<your ZimaOS IP>:6704"
if [ -f "$SITE/config/installed.php" ]; then
  cred_note "Sign in at /admin with the account you made in the installer."
else
  cred_note "Open the URL and follow the installer: pick SQLite (or your own database) and make the admin account."
fi
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8080/ &

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
