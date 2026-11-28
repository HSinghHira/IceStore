#!/bin/sh
# IceStore start script for gonic. gonic's first database migration makes an
# admin account with the password "admin". This script:
#   - on the very first start, runs gonic for a moment so it makes its
#     database, then stops it;
#   - sets the admin password: GONIC_ADMIN_PASSWORD from the app settings
#     (set again on every start), or one made here and kept in /data, which
#     only replaces the default "admin" password;
#   - then starts gonic.
set -eu

DATA=/data
PASS_FILE=$DATA/.icestore-admin-password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(GONIC_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done
export GONIC_PLAYLISTS_PATH="${GONIC_PLAYLISTS_PATH:-$DATA/playlists}"
DB=${GONIC_DB_PATH:-$DATA/gonic.db}
mkdir -p "$DATA" "$GONIC_PLAYLISTS_PATH" "${GONIC_CACHE_PATH:-/cache}" "${GONIC_PODCAST_PATH:-/podcasts}"

users_ready() { [ -s "$DB" ] && sqlite3 "$DB" "SELECT count(*) FROM users;" 2>/dev/null | grep -q '^[1-9]'; }

# ---- first start: let gonic make its database and the admin user ----
if ! users_ready; then
  log "first start: letting gonic create its database"
  GONIC_SCAN_AT_START_ENABLED=false gonic >/dev/null 2>&1 &
  pid=$!
  i=0
  until users_ready; do
    i=$((i + 1))
    if [ "$i" -gt 120 ] || ! kill -0 "$pid" 2>/dev/null; then
      log "gonic did not create its database; starting it normally"
      break
    fi
    sleep 1
  done
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
fi

# ---- admin password ----
SET_BY_USER=
if [ -n "${GONIC_ADMIN_PASSWORD:-}" ]; then
  PASS=$GONIC_ADMIN_PASSWORD
  SET_BY_USER=1
elif [ -s "$PASS_FILE" ]; then
  PASS=$(cat "$PASS_FILE")
else
  ( umask 077; head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$PASS_FILE" )
  PASS=$(cat "$PASS_FILE")
  log "first start: made the admin password ($PASS_FILE)"
fi
unset GONIC_ADMIN_PASSWORD
sql_pass=$(printf '%s' "$PASS" | sed "s/'/''/g")
if users_ready; then
  if [ -n "$SET_BY_USER" ]; then
    sqlite3 "$DB" "UPDATE users SET password='$sql_pass' WHERE name='admin';"
  else
    sqlite3 "$DB" "UPDATE users SET password='$sql_pass' WHERE name='admin' AND password='admin';"
  fi
fi

cred_reset
cred_add "URL" "http://<your ZimaOS IP>:7005"
cred_add "USER" "admin"
if [ -n "$SET_BY_USER" ]; then
  cred_add "PASSWORD" "(the one you set in GONIC_ADMIN_PASSWORD)"
else
  cred_add "PASSWORD" "$PASS"
  cred_note "If you changed the admin password in gonic, use yours."
fi
/usr/local/lib/icestore/credentials.sh "http://127.0.0.1:80/" &

exec "$@"
