#!/usr/bin/env bash
# IceStore start script for Paperless-ngx Full. Runs as root before
# s6-overlay:
#
#   - PAPERLESS_SECRET_KEY: set in the app settings wins; blank means the key
#     in /usr/src/paperless/data/.secret_key, made on first start.
#   - PostgreSQL: on first start, makes the cluster in /var/lib/postgresql/data
#     and the paperless role and database, with a password made for this
#     install (data/.db_password). PAPERLESS_DBPASS is set from it.
#   - PAPERLESS_ADMIN_USER (default admin) / PAPERLESS_ADMIN_PASSWORD: blank
#     password means the one in data/.admin_password, made on first start.
#     Paperless only creates that user when no user of that name exists, and
#     never changes an existing password.
#   - PAPERLESS_TIME_ZONE follows TZ unless set; PAPERLESS_TIKA_ENABLED is on
#     unless set to false.
#   - Tika and Gotenberg: /proc, /dev and /sys mounted into their folders
#     under /opt/rootfs (needs the container to run privileged).
#
# Then it hands over to upstream's /init (s6-overlay) unchanged.
set -eu

DATA=${PAPERLESS_DATA_DIR:-/usr/src/paperless/data}
PG_DATA=/var/lib/postgresql/data
KEY_FILE=$DATA/.secret_key
PASS_FILE=$DATA/.admin_password
DB_PASS_FILE=$DATA/.db_password
ROOTFS=/opt/rootfs
LOG_TAG=icestore
# The banner file is in /tmp (AIO_CRED_FILE, set in the Dockerfile so IceDash
# sees it too): s6-overlay may put a fresh tmpfs on /run.
export AIO_CRED_FILE=${AIO_CRED_FILE:-/tmp/icestore-credentials}
. /usr/local/lib/icestore/lib.sh

# Random letters and digits, without openssl (the Paperless image has none).
random_hex() { head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; }

mkdir -p "$DATA" "$PG_DATA"
umask 077

# ---- secret key ----
if [ -n "${PAPERLESS_SECRET_KEY:-}" ]; then
  if [ -s "$KEY_FILE" ] && [ "$(cat "$KEY_FILE")" != "$PAPERLESS_SECRET_KEY" ]; then
    log "PAPERLESS_SECRET_KEY differs from the key used before; using PAPERLESS_SECRET_KEY (everyone has to sign in again)."
    cp "$KEY_FILE" "$KEY_FILE.previous"
  fi
  printf '%s' "$PAPERLESS_SECRET_KEY" > "$KEY_FILE.tmp"
  mv "$KEY_FILE.tmp" "$KEY_FILE"
elif [ ! -s "$KEY_FILE" ]; then
  head -c 48 /dev/urandom | base64 | tr -d '\n/+=' > "$KEY_FILE.tmp"
  mv "$KEY_FILE.tmp" "$KEY_FILE"
  log "first start: made this install's secret key in the data folder (.secret_key)."
fi
PAPERLESS_SECRET_KEY=$(cat "$KEY_FILE")
export PAPERLESS_SECRET_KEY

# ---- database password ----
if [ ! -s "$DB_PASS_FILE" ]; then
  random_hex 24 > "$DB_PASS_FILE.tmp"
  mv "$DB_PASS_FILE.tmp" "$DB_PASS_FILE"
  log "first start: made the database password in the data folder (.db_password)."
fi
PAPERLESS_DBPASS=$(cat "$DB_PASS_FILE")
export PAPERLESS_DBPASS

# ---- PostgreSQL (first start: cluster, role and database) ----
pg_setup /usr/lib/postgresql/18/bin "$PG_DATA"
if pg_is_new; then
  if [ -n "$(ls -A "$PG_DATA" 2>/dev/null)" ]; then
    log "ERROR: $PG_DATA has files but no PostgreSQL database in it; empty the postgres folder or put the right one back."
    exit 1
  fi
  log "first start: creating the PostgreSQL database"
  PG_PASSWORD=$PAPERLESS_DBPASS
  pg_initdb --data-checksums
  pg_start_local
  pg_psql -v pw="$PAPERLESS_DBPASS" <<'SQL'
CREATE ROLE paperless LOGIN PASSWORD :'pw';
CREATE DATABASE paperless OWNER paperless;
SQL
  pg_stop_local
elif [ "$(cat "$PG_DATA/PG_VERSION")" != 18 ]; then
  log "ERROR: the database in $PG_DATA was made by PostgreSQL $(cat "$PG_DATA/PG_VERSION"), this image has 18."
  exit 1
fi

# ---- first admin ----
[ -n "${PAPERLESS_ADMIN_USER:-}" ] || PAPERLESS_ADMIN_USER=admin
PASSWORD_SET=
if [ -n "${PAPERLESS_ADMIN_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  PAPERLESS_ADMIN_PASSWORD=$(cat "$PASS_FILE")
else
  random_hex 12 > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  PAPERLESS_ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in the data folder (.admin_password)."
fi
export PAPERLESS_ADMIN_USER PAPERLESS_ADMIN_PASSWORD

# ---- other defaults (ZimaOS passes blank variables as empty strings) ----
[ -n "${PAPERLESS_TIME_ZONE:-}" ] || PAPERLESS_TIME_ZONE=${TZ:-UTC}
[ -n "$PAPERLESS_TIME_ZONE" ] || PAPERLESS_TIME_ZONE=UTC
[ -n "${PAPERLESS_TIKA_ENABLED:-}" ] || PAPERLESS_TIKA_ENABLED=1
export PAPERLESS_TIME_ZONE PAPERLESS_TIKA_ENABLED
for v in PAPERLESS_URL PAPERLESS_OCR_LANGUAGE PAPERLESS_OCR_LANGUAGES USERMAP_UID USERMAP_GID; do
  eval "val=\${$v:-}"
  # shellcheck disable=SC2154
  [ -n "$val" ] || unset "$v"
done
umask 022

# ---- Tika and Gotenberg folders ----
# Both run with chroot and need /proc (Java, Chromium, LibreOffice), /dev
# (/dev/null, /dev/shm) and /sys. Mounting needs a privileged container.
MOUNT_FAILED=
for d in "$ROOTFS"/*/; do
  [ -d "$d" ] || continue
  mkdir -p "$d/proc" "$d/dev" "$d/sys" "$d/tmp" "$d/etc"
  chmod 1777 "$d/tmp"
  cat /etc/hosts > "$d/etc/hosts"
  [ -f /etc/resolv.conf ] && cat /etc/resolv.conf > "$d/etc/resolv.conf"
  mountpoint -q "$d/proc" || mount -t proc proc "$d/proc" 2>/dev/null || MOUNT_FAILED=1
  mountpoint -q "$d/dev"  || mount --rbind /dev "$d/dev" 2>/dev/null || MOUNT_FAILED=1
  mountpoint -q "$d/sys"  || mount --rbind /sys "$d/sys" 2>/dev/null || true
done
if [ -n "$MOUNT_FAILED" ]; then
  log "WARNING: could not mount /proc or /dev for Tika and Gotenberg. The container must run privileged (it is in the IceStore compose file); without it Office files and emails cannot be read. PDFs and images still work."
fi

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6800"
cred_add USERNAME "$PAPERLESS_ADMIN_USER"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in PAPERLESS_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$PAPERLESS_ADMIN_PASSWORD"
  cred_note "Also saved in /DATA/AppData/paperless-ngx-full/data/.admin_password"
fi
cred_note "Change the password in Profile after you sign in; this one is only used to create the first admin."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8000/accounts/login/ &

exec /init "$@"
