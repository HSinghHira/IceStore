#!/bin/bash
# Starts one tududi service for supervisord. Usage: tududi-svc <name>
set -euo pipefail
svc=${1:?usage: tududi-svc <name>}

PGBIN=/usr/libexec/postgresql16
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  tududi)
    deadline=$((SECONDS + 600))
    until as_pg "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "[tududi] gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the tududi role's password the same as /data/secrets.env.
    as_pg "$PGBIN/psql" -h /run/postgresql -U postgres -q -v ON_ERROR_STOP=1 \
      -c "ALTER ROLE tududi PASSWORD '${DB_PASSWORD}';" >/dev/null
    # Upstream's entrypoint: PUID/PGID, folder ownership, then its start
    # script (migrations, first user, server) as that user.
    cd /app/backend
    exec /app/scripts/docker-entrypoint.sh
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
