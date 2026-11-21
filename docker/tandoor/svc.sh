#!/bin/bash
# Starts one Tandoor service for supervisord. Usage: tandoor-svc <name>
set -euo pipefail
svc=${1:?usage: tandoor-svc <name>}

PGBIN=/usr/libexec/postgresql17

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  tandoor)
    deadline=$((SECONDS + 600))
    until setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "[tandoor] gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the tandoor role's password the same as /data/secrets.env.
    setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/psql" -h /run/postgresql -U postgres \
      -q -v ON_ERROR_STOP=1 -c "ALTER ROLE tandoor PASSWORD '${POSTGRES_PASSWORD}';" >/dev/null
    # boot.sh starts nginx in the background on its own, so make sure an
    # old one from a restart of this program is gone first.
    pkill -x nginx 2>/dev/null || true
    cd /opt/recipes
    # Upstream's start script: migrations, static files, nginx and gunicorn.
    exec /opt/recipes/boot.sh
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
