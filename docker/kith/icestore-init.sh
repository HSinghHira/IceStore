#!/bin/bash
# IceStore start script for Kith. Makes this install's database and admin
# passwords, creates the MariaDB database on first start, then hands over to
# supervisord (mariadb, app, jobs).
set -euo pipefail

DATA=${AIO_DATA:-/data}
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

STATE=$DATA/state
mkdir -p "$STATE" "$DATA/mysql" "$DATA/media" "$DATA/instance"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"
ensure_secret DB_PASSWORD 16
ensure_secret ADMIN_PASSWORD 9

# ---- environment for every program (supervisord passes it on) ----
export KITH_DB_PASSWORD=$(secret DB_PASSWORD)
export KITH_ADMIN_USER=${KITH_ADMIN_USER:-admin}
export KITH_ADMIN_PASSWORD=$(secret ADMIN_PASSWORD)
# Blank settings from the app settings mean "use the default".
for v in $(env | sed -n 's/^\(KITH_[A-Z_]*\)=$/\1/p'); do unset "$v"; done

cred_reset
cred_add URL "http://<your ZimaOS IP>:6707"
cred_add USER "$KITH_ADMIN_USER"
cred_add PASSWORD "$KITH_ADMIN_PASSWORD"
cred_note "The admin account is made on the first start with this password; change it under your account."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  env | grep -E '^KITH_' | sed 's/PASSWORD=.*/PASSWORD=***/'
  log "dry run finished"
  exit 0
fi

chown -R kith:kith "$DATA/media" "$DATA/instance"
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chown -R mysql:mysql "$DATA/mysql"

# ---- first start: the database and its user (upstream's compose: MARIADB_
# ---- DATABASE kith, MARIADB_USER kith, random root password) ----
if [ ! -d "$DATA/mysql/mysql" ]; then
  log "first start: creating the database"
  mariadb-install-db --user=mysql --datadir="$DATA/mysql" --auth-root-authentication-method=socket >/dev/null
  mariadbd --user=mysql --datadir="$DATA/mysql" --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid=$!
  for _ in $(seq 60); do
    mariadb-admin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1 && break
    sleep 1
  done
  mariadb --socket=/run/mysqld/mysqld.sock <<SQL
CREATE DATABASE IF NOT EXISTS kith CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'kith'@'127.0.0.1' IDENTIFIED BY '$KITH_DB_PASSWORD';
CREATE USER IF NOT EXISTS 'kith'@'localhost' IDENTIFIED BY '$KITH_DB_PASSWORD';
GRANT ALL ON kith.* TO 'kith'@'127.0.0.1';
GRANT ALL ON kith.* TO 'kith'@'localhost';
FLUSH PRIVILEGES;
SQL
  kill "$pid"
  wait "$pid" || true
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
