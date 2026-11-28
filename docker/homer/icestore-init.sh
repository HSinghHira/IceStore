#!/bin/sh
# IceStore start script for Homer. Runs as root only long enough to hand the
# assets folder (made by ZimaOS as root) and this container's stdout/stderr
# to Homer's lighttpd user, then starts upstream's entrypoint as that user.
# Upstream's entrypoint copies the example config.yml into an empty assets
# folder and runs lighttpd, which writes its access log to /dev/fd/3 (a copy
# of stdout), so stdout must belong to that user too.
set -eu

LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

RUN_UID=${UID:-1000}
RUN_GID=${GID:-1000}

if [ "$(id -u)" = "0" ]; then
  mkdir -p /www/assets
  chown -R "$RUN_UID:$RUN_GID" /www/assets
  # Docker gives the log pipes to root; lighttpd reopens them as RUN_UID.
  # $$ is this shell (the exec keeps the same process), not /proc/self.
  chown "$RUN_UID:$RUN_GID" "/proc/$$/fd/1" "/proc/$$/fd/2"
  exec su-exec "$RUN_UID:$RUN_GID" "$@"
fi

exec "$@"
