#!/bin/bash
# Last step of upstream's entrypoint (its `exec "$@"`): stop the PostgreSQL
# icestore-init started for the migrations, then run supervisord, which
# starts it again under supervision with the rest of Warracker.
set -euo pipefail
setpriv --reuid=postgres --regid=postgres --init-groups \
  /usr/lib/postgresql/17/bin/pg_ctl -D /data/postgres -w -m fast stop >/dev/null
/usr/local/lib/icestore/credentials.sh http://127.0.0.1/api/health &
exec /opt/venv/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
