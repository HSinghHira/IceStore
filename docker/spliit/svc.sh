#!/bin/bash
# Starts one Spliit service for supervisord. Usage: spliit-svc <name>
set -euo pipefail
svc=${1:?usage: spliit-svc <name>}

PGBIN=/usr/libexec/postgresql17
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  spliit)
    deadline=$((SECONDS + 600))
    until as_pg "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "[spliit] gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the spliit role's password the same as /data/secrets.env.
    as_pg "$PGBIN/psql" -h /run/postgresql -U postgres -q -v ON_ERROR_STOP=1 \
      -c "ALTER ROLE spliit PASSWORD '${DB_PASSWORD}';" >/dev/null
    # Upstream's entrypoint: migrations, then the server.
    cd /usr/app
    exec /bin/sh /usr/app/scripts/container-entrypoint.sh
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
