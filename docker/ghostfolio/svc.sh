#!/bin/bash
# Starts one Ghostfolio service for supervisord. Usage: ghostfolio-svc <name>
set -euo pipefail
svc=${1:?usage: ghostfolio-svc <name>}

PGBIN=/usr/lib/postgresql/17/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }
pg_up() { as_pg "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  redis)
    # The password comes from /data/secrets.env through the environment.
    exec setpriv --reuid=redis --regid=redis --init-groups redis-server \
      --bind 127.0.0.1 --port 6379 --dir /data/redis --appendonly yes \
      --requirepass "$REDIS_PASSWORD" --save 60 1000
    ;;
  ghostfolio)
    deadline=$((SECONDS + 600))
    until pg_up; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "[ghostfolio] gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the ghostfolio role's password the same as /data/secrets.env.
    as_pg "$PGBIN/psql" -h /run/postgresql -U postgres -q -v ON_ERROR_STOP=1 \
      -c "ALTER ROLE ghostfolio PASSWORD '${POSTGRES_PASSWORD}';" >/dev/null
    cd /ghostfolio/apps/api
    # Upstream's start script: migrations, seed, then the server.
    exec setpriv --reuid=node --regid=node --init-groups /ghostfolio/entrypoint.sh
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
