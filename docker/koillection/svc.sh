#!/bin/bash
# Starts one Koillection service for supervisord. Usage: koillection-svc <name>
set -euo pipefail
svc=${1:?usage: koillection-svc <name>}

PGBIN=/usr/lib/postgresql/18/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }
pg_up() { as_pg "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  koillection)
    deadline=$((SECONDS + 600))
    until pg_up; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the koillection role's password the same as /data/secrets.env.
    as_pg "$PGBIN/psql" -h /run/postgresql -U postgres -q -v ON_ERROR_STOP=1 \
      -c "ALTER ROLE koillection PASSWORD '${DB_PASSWORD}';" >/dev/null
    # Upstream's entrypoint: writes .env.local, migrates, makes the JWT keys,
    # fixes /uploads ownership, then runs FrankenPHP on port 80.
    exec sh /app/public/docker/entrypoint.sh
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
