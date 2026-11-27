#!/bin/bash
# Starts one Homi service for supervisord. Usage: homi-svc <name>
# The environment (database URLs, secrets, PUBLIC_URL) comes from
# icestore-init, which supervisord passes on to every program.
set -euo pipefail
svc=${1:?usage: homi-svc <name>}

PGBIN=/usr/lib/postgresql/18/bin
as_node() { setpriv --reuid=node --regid=node --init-groups "$@"; }

# wait_for URL|pg: give up after 10 minutes; supervisord starts us again.
wait_for() {
  local what=$1 deadline=$((SECONDS + 600))
  until { [ "$what" = pg ] && setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/pg_isready" -q -h 127.0.0.1 -p 5432; } \
     || { [ "$what" != pg ] && curl -fsS -o /dev/null -m 5 "$what"; }; do
    [ "$SECONDS" -lt "$deadline" ] || { echo "[$svc] gave up waiting for $what"; exit 1; }
    sleep 2
  done
}

cd /opt/homi
case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" \
      -D "$HOMI_PG_DIR" -c listen_addresses=127.0.0.1 -c port=5432 \
      -c unix_socket_directories=/run/postgresql
    ;;
  module-manager)
    wait_for pg
    exec as_node env HOMI_MODULE_MANAGER_HOST=127.0.0.1 HOMI_MODULE_MANAGER_PORT=3002 \
      node apps/core/dist/module-manager-server.js
    ;;
  core)
    wait_for pg
    wait_for http://127.0.0.1:3002/health/live
    exec as_node env HOMI_HOST=127.0.0.1 HOMI_PORT=3001 node apps/core/dist/server.js
    ;;
  gateway)
    wait_for http://127.0.0.1:3001/health/ready
    exec nginx -c /etc/nginx/homi.conf -g 'daemon off;'
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
