#!/bin/bash
# Starts one Kith service for supervisord. Usage: kith-svc <name>
set -euo pipefail
svc=${1:?usage: kith-svc <name>}
exec > >(sed -u "s/^/[$svc] /") 2>&1

db_up() { mariadb-admin --protocol=socket --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; }
wait_db() {
  local deadline=$((SECONDS + 600))
  until db_up; do
    [ "$SECONDS" -lt "$deadline" ] || { echo "gave up waiting for MariaDB"; exit 1; }
    sleep 2
  done
}
as_kith() { setpriv --reuid=kith --regid=kith --init-groups "$@"; }

case $svc in
  mariadb)
    exec mariadbd --user=mysql --datadir=/data/mysql --bind-address=127.0.0.1 \
      --socket=/run/mysqld/mysqld.sock --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    ;;
  app)
    wait_db
    cd /app
    # A new site: the tables and the first admin (upstream's `setup db`),
    # with this install's password from icestore-init. Then any database
    # upgrades, as upstream's image does before it serves a page.
    out=$(as_kith flask --app app setup upgrade 2>&1)
    echo "$out"
    if grep -q "Empty database" <<<"$out"; then
      echo "first start: creating the tables and the admin account"
      as_kith flask --app app setup db --admin "$KITH_ADMIN_USER" --password "$KITH_ADMIN_PASSWORD"
    fi
    exec as_kith gunicorn --workers "${KITH_WORKERS:-3}" --bind 0.0.0.0:8000 --access-logfile - 'app:create_app()'
    ;;
  jobs)
    # Upstream's scheduled jobs (deploy/jobs.sh timers), checked once a
    # minute: place coordinates at 02:30, the version check at 04:00 and the
    # weekly email on Mondays at 13:00 (container time zone).
    wait_db
    cd /app
    while :; do
      now=$(date +%H:%M); dow=$(date +%u)
      case $now in
        02:30) as_kith flask --app app geocode run || true ;;
        04:00) as_kith flask --app app updates check || true ;;
        13:00) [ "$dow" = 1 ] && { as_kith flask --app app digest send || true; } ;;
      esac
      sleep 60
    done
    ;;
  *) echo "unknown service $svc"; exit 1 ;;
esac
