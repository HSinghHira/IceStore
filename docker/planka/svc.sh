#!/bin/bash
# Starts one PLANKA service for supervisord. Usage: planka-svc <name>
set -euo pipefail
svc=${1:?usage: planka-svc <name>}

PGBIN=/usr/libexec/postgresql16

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  planka)
    deadline=$((SECONDS + 600))
    until setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "[planka] gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the planka role's password the same as /data/secrets.env.
    setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/psql" -h /run/postgresql -U postgres \
      -q -v ON_ERROR_STOP=1 -c "ALTER ROLE planka PASSWORD '${DB_PASSWORD}';" >/dev/null
    cd /app
    # Upstream's start script: migrations and the admin seed, then the server.
    exec setpriv --reuid=node --regid=node --init-groups ./start.sh
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
