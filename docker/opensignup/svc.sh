#!/bin/bash
# Starts one OpenSignup service for supervisord. Usage: opensignup-svc <name>
set -euo pipefail
svc=${1:?usage: opensignup-svc <name>}
exec > >(sed -u "s/^/[$svc] /") 2>&1

PGBIN=/usr/libexec/postgresql16
as_signup() { setpriv --reuid=signup --regid=signup --init-groups "$@"; }

# wait_for <what> <test command...>: up to 15 minutes, then supervisord restarts us
wait_for() {
  local what=$1 deadline=$((SECONDS + 900)); shift
  until "$@" >/dev/null 2>&1; do
    [ "$SECONDS" -lt "$deadline" ] || { echo "gave up waiting for $what"; exit 1; }
    sleep 2
  done
}
pg_up() { "$PGBIN/pg_isready" -h 127.0.0.1 -p 5432 -q; }
web_up() { curl -fsS -o /dev/null -m 5 http://127.0.0.1:3000/api/public/health; }

case $svc in
  postgres)
    exec setpriv --reuid=postgres --regid=postgres --init-groups "$PGBIN/postgres" -D /data/postgres \
      -c listen_addresses=127.0.0.1 -c unix_socket_directories=/run/postgresql
    ;;
  mailpit)
    export MP_SMTP_AUTH_ACCEPT_ANY=1 MP_SMTP_AUTH_ALLOW_INSECURE=1 \
      MP_SMTP_BIND_ADDR=127.0.0.1:1025 MP_UI_BIND_ADDR=127.0.0.1:8025 \
      MP_WEBROOT=/mail/ MP_DATABASE=/data/mail/mailpit.db
    exec as_signup /usr/local/bin/mailpit
    ;;
  web)
    # Upstream's "migrate" service, then its "web" service.
    wait_for PostgreSQL pg_up
    cd /app
    echo "running database migrations"
    as_signup node_modules/.bin/tsx src/db/migrate.ts
    export HOSTNAME=127.0.0.1 PORT=3000
    exec as_signup node server.js
    ;;
  worker)
    # Upstream's "worker" service (pnpm worker), once the migrations ran.
    wait_for "the web server" web_up
    cd /app
    exec as_signup node_modules/.bin/tsx --tsconfig tsconfig.worker.json src/jobs/worker.ts
    ;;
  gateway)
    wait_for "the web server" web_up
    exec nginx -c /etc/nginx/icestore.conf -g 'daemon off;'
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
