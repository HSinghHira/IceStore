#!/bin/bash
# Starts one Wiki.js service for supervisord. Usage: wikijs-svc <name>
set -euo pipefail
svc=${1:?usage: wikijs-svc <name>}
exec > >(sed -u "s/^/[$svc] /") 2>&1

PGBIN=/usr/lib/postgresql/18/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }
pg_up() { as_pg "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D /data/postgres -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  wiki)
    deadline=$((SECONDS + 600))
    until pg_up; do
      [ "$SECONDS" -lt "$deadline" ] || { echo "gave up waiting for PostgreSQL"; exit 1; }
      sleep 2
    done
    # Keep the wiki role's password the same as /data/secrets.env.
    as_pg "$PGBIN/psql" -h /run/postgresql -U postgres -q -v ON_ERROR_STOP=1 \
      -c "ALTER ROLE wiki PASSWORD '${DB_PASS}';" >/dev/null
    cd /wiki
    exec setpriv --reuid=node --regid=node --init-groups \
      node --no-experimental-webstorage backend
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
