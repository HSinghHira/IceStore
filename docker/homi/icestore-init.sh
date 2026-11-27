#!/bin/bash
# IceStore start script for Homi. Runs as root, once per start, then hands
# over to supervisord (svc.sh). It does what upstream's README runs by hand:
#
#   - /data/state/secrets.env: the four database passwords, HOMI_AUTH_SECRET
#     and HOMI_MODULE_MANAGER_SECRET, made on first start.
#   - PUBLIC_URL (upstream's HOMI_AUTH_BASE_URL): the https address of the
#     reverse proxy in front of Homi. Homi only accepts sign-ins from this
#     exact address, and its web app needs https (crypto.randomUUID, which
#     browsers only offer on https or localhost, for the device and every
#     change). While it is blank, the example address or still has
#     [ZIMAOS-IP-ADDRESS], localhost is used, the log says what to do and
#     every other address gets a "set PUBLIC_URL" note. Plain http logs a
#     warning.
#   - first start: initdb, the homi database and upstream's own role setup
#     (deploy/postgres/001-init.sh).
#   - every start: the core migrations (safe to run again).
#   - once: the first account and household (bootstrap-first-account), with
#     HOMI_BOOTSTRAP_* from the app settings and a made password.
#   - when their version changes: the calendar and chequebook modules
#     (module-installer install). Upstream refuses to reinstall the same
#     version from a rebuilt package, so the versions done are kept in
#     /data/state/modules-installed.
#   - every other blank variable is dropped, so Homi uses its default.
set -euo pipefail

DATA=${AIO_DATA:-/data}
STATE=$DATA/state
PORT=6879
LOG_TAG=icestore
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

mkdir -p "$STATE" "$DATA/postgres" "$DATA/modules" "$DATA/module-backups"
SECRETS=$STATE/secrets.env
umask 077
touch "$SECRETS"

# ---- secrets ----
ensure_secret HOMI_MIGRATOR_DB_PASSWORD 24
ensure_secret HOMI_APP_DB_PASSWORD 24
ensure_secret HOMI_JOBS_DB_PASSWORD 24
ensure_secret HOMI_BACKUP_DB_PASSWORD 24
ensure_secret HOMI_AUTH_SECRET 32
ensure_secret HOMI_MODULE_MANAGER_SECRET 32
for s in HOMI_MIGRATOR_DB_PASSWORD HOMI_APP_DB_PASSWORD HOMI_JOBS_DB_PASSWORD HOMI_BACKUP_DB_PASSWORD \
         HOMI_AUTH_SECRET HOMI_MODULE_MANAGER_SECRET; do
  eval "$s=\$(secret $s)"
  export "${s?}"
done
PG_PASSWORD=$(openssl rand -hex 24)   # superuser; only used over the local socket

# ---- the public address ----
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:$PORT}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  *"[ZIMAOS-IP-ADDRESS]"*|*homi.example.com*)
    log "PUBLIC_URL is not set ($PUBLIC_URL): set it in the app settings to the https address of your reverse proxy (like Nginx Proxy Manager) pointed at http://<your ZimaOS IP>:$PORT. Homi needs https to save changes."
    log "Until then Homi only works on the ZimaOS box itself, at http://localhost:$PORT; other addresses show a note."
    PUBLIC_URL=http://localhost:$PORT ;;
  http://*)
    log "PUBLIC_URL is plain http ($PUBLIC_URL): the pages open, but the browser can't register the device, save changes or add events there (that needs https, or http://localhost:$PORT on the box). Put an https reverse proxy in front and set PUBLIC_URL to its address." ;;
esac
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
HOMI_AUTH_BASE_URL=$PUBLIC_URL
export PUBLIC_URL HOMI_AUTH_BASE_URL

host=${PUBLIC_URL#*://}; host=${host%%/*}; host=${host%:*}
GUARD_DIR=${AIO_RUN:-/run/homi}
mkdir -p "$GUARD_DIR"
case $host in
  localhost|127.0.0.1) cat > "$GUARD_DIR/guard.conf" <<'GUARD'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Homi is not set up for this address yet. Open the app settings in ZimaOS, set PUBLIC_URL to the https address of your reverse proxy (pointed at port 6879) and save.\n";
}
GUARD
    ;;
  *) : > "$GUARD_DIR/guard.conf" ;;
esac
chmod 644 "$GUARD_DIR/guard.conf"

# ---- database URLs (TCP for the services, the socket during setup) ----
DB_TCP=127.0.0.1:5432
HOMI_DATABASE_URL="postgresql://homi_app:${HOMI_APP_DB_PASSWORD}@${DB_TCP}/homi"
HOMI_MIGRATOR_DATABASE_URL="postgresql://homi_migrator:${HOMI_MIGRATOR_DB_PASSWORD}@${DB_TCP}/homi"
HOMI_BACKUP_DATABASE_URL="postgresql://homi_backup:${HOMI_BACKUP_DB_PASSWORD}@${DB_TCP}/homi"
HOMI_MODULES_DIRECTORY=$DATA/modules
HOMI_MODULE_BACKUPS_DIRECTORY=$DATA/module-backups
HOMI_MODULE_MANAGER_URL=http://127.0.0.1:3002
HOMI_PG_DIR=$DATA/postgres
export HOMI_DATABASE_URL HOMI_MIGRATOR_DATABASE_URL HOMI_BACKUP_DATABASE_URL HOMI_MODULES_DIRECTORY \
       HOMI_MODULE_BACKUPS_DIRECTORY HOMI_MODULE_MANAGER_URL HOMI_PG_DIR
SOCK_MIGRATOR="postgresql://homi_migrator:${HOMI_MIGRATOR_DB_PASSWORD}@localhost/homi?host=/run/postgresql"
SOCK_APP="postgresql://homi_app:${HOMI_APP_DB_PASSWORD}@localhost/homi?host=/run/postgresql"

# ---- the first account (used once, on the first start) ----
[ -n "${HOMI_BOOTSTRAP_EMAIL:-}" ] || HOMI_BOOTSTRAP_EMAIL=admin@example.com
[ -n "${HOMI_BOOTSTRAP_NAME:-}" ] || HOMI_BOOTSTRAP_NAME="Household Owner"
[ -n "${HOMI_BOOTSTRAP_HOUSEHOLD:-}" ] || HOMI_BOOTSTRAP_HOUSEHOLD="Our Home"
[ -n "${HOMI_BOOTSTRAP_LOCALE:-}" ] || HOMI_BOOTSTRAP_LOCALE=en-CA
[ -n "${HOMI_BOOTSTRAP_TIME_ZONE:-}" ] || HOMI_BOOTSTRAP_TIME_ZONE=${TZ:-UTC}
[ -n "$HOMI_BOOTSTRAP_TIME_ZONE" ] || HOMI_BOOTSTRAP_TIME_ZONE=UTC
PASS_FILE=$STATE/.first-password
PASSWORD_SET=
if [ -n "${HOMI_BOOTSTRAP_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  HOMI_BOOTSTRAP_PASSWORD=$(cat "$PASS_FILE")
else
  openssl rand -hex 10 > "$PASS_FILE.tmp" && mv "$PASS_FILE.tmp" "$PASS_FILE"
  HOMI_BOOTSTRAP_PASSWORD=$(cat "$PASS_FILE")
fi

# ---- every other blank variable: Homi's default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done

if [ -n "${AIO_DRY_RUN:-}" ]; then
  log "dry run: PUBLIC_URL=$PUBLIC_URL guard=$([ -s "$GUARD_DIR/guard.conf" ] && echo on || echo off) email=$HOMI_BOOTSTRAP_EMAIL tz=$HOMI_BOOTSTRAP_TIME_ZONE auth_secret=${#HOMI_AUTH_SECRET} chars"
  exit 0
fi

chown -R node:node "$DATA/modules" "$DATA/module-backups"
umask 022
as_node() { setpriv --reuid=node --regid=node --init-groups "$@"; }

# ---- PostgreSQL: first-start setup, then the setup steps on a local server ----
pg_setup /usr/lib/postgresql/18/bin "$DATA/postgres"
# A first setup cut short after initdb leaves a database without Homi's
# roles, and every later start would fail. Without the marker it is redone.
DB_READY=$STATE/.db-ready
if ! pg_is_new && [ ! -f "$DB_READY" ]; then
  aside="$DATA/postgres.incomplete-$(date +%Y%m%d-%H%M%S)"
  log "the first database setup did not finish last time; moving that folder to $aside and starting it again"
  mv "$DATA/postgres" "$aside"
  mkdir -p "$DATA/postgres"
  pg_setup /usr/lib/postgresql/18/bin "$DATA/postgres"
fi
pg_start_needed=1
if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -c "CREATE DATABASE homi;"
  # Upstream's own role and schema setup, unchanged.
  as_pg env PATH="$PGBIN:$PATH" PGHOST=/run/postgresql POSTGRES_USER=postgres POSTGRES_DB=homi \
    HOMI_MIGRATOR_DB_PASSWORD="$HOMI_MIGRATOR_DB_PASSWORD" HOMI_APP_DB_PASSWORD="$HOMI_APP_DB_PASSWORD" \
    HOMI_JOBS_DB_PASSWORD="$HOMI_JOBS_DB_PASSWORD" HOMI_BACKUP_DB_PASSWORD="$HOMI_BACKUP_DB_PASSWORD" \
    sh /opt/homi/deploy/postgres/001-init.sh
  touch "$DB_READY"
  pg_start_needed=
fi
[ -z "$pg_start_needed" ] || pg_start_local
# Keep the role passwords the same as /data/state/secrets.env.
pg_psql -d homi \
  -c "ALTER ROLE homi_migrator PASSWORD '${HOMI_MIGRATOR_DB_PASSWORD}';" \
  -c "ALTER ROLE homi_app PASSWORD '${HOMI_APP_DB_PASSWORD}';" \
  -c "ALTER ROLE homi_jobs PASSWORD '${HOMI_JOBS_DB_PASSWORD}';" \
  -c "ALTER ROLE homi_backup PASSWORD '${HOMI_BACKUP_DB_PASSWORD}';" >/dev/null

cd /opt/homi
log "applying database migrations"
if ! as_node env HOMI_MIGRATOR_DATABASE_URL="$SOCK_MIGRATOR" node packages/db/dist/migrate.js; then
  pg_stop_local
  log "the database migrations failed (see above); Homi can't start until they work."
  exit 1
fi

if [ ! -f "$STATE/.bootstrap-done" ]; then
  log "first start: creating the first account and household"
  if out=$(as_node env HOMI_DATABASE_URL="$SOCK_APP" HOMI_AUTH_SECRET="$HOMI_AUTH_SECRET" \
        HOMI_BOOTSTRAP_EMAIL="$HOMI_BOOTSTRAP_EMAIL" HOMI_BOOTSTRAP_PASSWORD="$HOMI_BOOTSTRAP_PASSWORD" \
        HOMI_BOOTSTRAP_NAME="$HOMI_BOOTSTRAP_NAME" HOMI_BOOTSTRAP_HOUSEHOLD="$HOMI_BOOTSTRAP_HOUSEHOLD" \
        HOMI_BOOTSTRAP_LOCALE="$HOMI_BOOTSTRAP_LOCALE" HOMI_BOOTSTRAP_TIME_ZONE="$HOMI_BOOTSTRAP_TIME_ZONE" \
        node apps/core/dist/bootstrap-first-account.js 2>&1); then
    touch "$STATE/.bootstrap-done"
  elif printf '%s' "$out" | grep -q "already contains a user"; then
    touch "$STATE/.bootstrap-done"
  else
    printf '%s\n' "$out" | grep -v -i password || true
    log "creating the first account failed (see above); Homi starts anyway and tries again on the next start."
  fi
fi

touch "$STATE/modules-installed"
for m in calendar chequebook; do
  ver=$(sed -n 's/^  "version": "\(.*\)",$/\1/p' "packages/$m/package.json" | head -1)
  grep -qx "$m $ver" "$STATE/modules-installed" && continue
  log "installing the $m module ($ver)"
  if as_node env HOMI_MIGRATOR_DATABASE_URL="$SOCK_MIGRATOR" HOMI_MODULES_DIRECTORY="$HOMI_MODULES_DIRECTORY" \
      node apps/core/dist/module-installer-cli.js install "/opt/homi/packages/$m"; then
    { grep -v "^$m " "$STATE/modules-installed" || true; echo "$m $ver"; } > "$STATE/modules-installed.tmp"
    mv "$STATE/modules-installed.tmp" "$STATE/modules-installed"
  else
    log "installing the $m module failed (see above); Homi starts without it and tries again on the next start."
  fi
done
pg_stop_local

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add EMAIL "$HOMI_BOOTSTRAP_EMAIL"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in HOMI_BOOTSTRAP_PASSWORD)"
else
  cred_add PASSWORD "$HOMI_BOOTSTRAP_PASSWORD"
  cred_note "First password, also in /DATA/AppData/homi/data/state/.first-password. Change it in Homi after you sign in."
fi
cred_note "Add the other members in Settings, Members, Add member."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
