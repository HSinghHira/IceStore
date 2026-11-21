#!/bin/bash
# Starts one Zipline service for supervisord. Usage: zipline-svc <name>
set -euo pipefail
svc=${1:?usage: zipline-svc <name>}

PGBIN=/usr/libexec/postgresql17
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  zipline)
    deadline=$((SECONDS + 600))
    until as_pg "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "[zipline] gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the zipline role's password the same as /data/secrets.env.
    as_pg "$PGBIN/psql" -h /run/postgresql -U postgres -q -v ON_ERROR_STOP=1 \
      -c "ALTER ROLE zipline PASSWORD '${DB_PASSWORD}';" >/dev/null
    # Upstream's entrypoint: migrations run when the server starts.
    exec /zipline/entrypoint
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
