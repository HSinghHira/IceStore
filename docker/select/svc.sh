#!/bin/bash
# Starts one Select service for supervisord. Usage: select-svc <name>
# Each one waits for what upstream's compose file makes it depend on.
set -euo pipefail
svc=${1:?usage: select-svc <name>}
exec > >(sed -u "s/^/[$svc] /") 2>&1

wait_for() {
  local deadline=$((SECONDS + 900))
  until "$@" >/dev/null 2>&1; do
    [ "$SECONDS" -lt "$deadline" ] || { echo "gave up waiting for: $*"; exit 1; }
    sleep 2
  done
}
pg_up() { /usr/lib/postgresql/16/bin/pg_isready -q -h 127.0.0.1 -p 5432; }
api_up() { curl -fsS -o /dev/null -m 5 http://127.0.0.1:8000/api/health; }
as_select() { setpriv --reuid=select --regid=select --init-groups "$@"; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups \
      /usr/lib/postgresql/16/bin/postgres -D /data/postgres \
      -c listen_addresses=127.0.0.1 -c unix_socket_directories=/run/postgresql
    ;;
  api)
    # Upstream's api: runs the database migrations, then serves on 8000.
    wait_for pg_up
    exec as_select select-api serve --host 127.0.0.1 --port 8000 --migrate
    ;;
  worker)
    # Reads mailboxes, sends approved e-mails, fires routines and runs agents.
    wait_for api_up
    exec as_select select-api worker
    ;;
  web)
    # The web app; it proxies /api/* to the api.
    wait_for api_up
    cd /web
    exec as_select env PORT=3000 HOSTNAME=0.0.0.0 SELECT_API_URL=http://127.0.0.1:8000 node server.js
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
