#!/bin/bash
# Starts one Joplin Server service for supervisord. Usage: joplin-svc <name>
set -euo pipefail
svc=${1:?usage: joplin-svc <name>}

PGBIN=/usr/lib/postgresql/16/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  joplin)
    deadline=$((SECONDS + 600))
    until as_pg "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "[joplin] gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the joplin role's password the same as /data/secrets.env.
    as_pg "$PGBIN/psql" -h /run/postgresql -U postgres -q -v ON_ERROR_STOP=1 \
      -c "ALTER ROLE joplin PASSWORD '${POSTGRES_PASSWORD}';" >/dev/null
    # Upstream's command, as the joplin user, from its working directory.
    cd /home/joplin/packages/server
    exec setpriv --reuid=joplin --regid=joplin --init-groups env HOME=/home/joplin yarn start-prod
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
