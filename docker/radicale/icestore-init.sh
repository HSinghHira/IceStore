#!/bin/sh
# IceStore start script for Radicale. The upstream image has no login
# (auth type none), so anyone could use it. This script:
#   - makes a password once (or takes RADICALE_PASSWORD from the app
#     settings) and keeps it in /data/.icestore-radicale-password,
#   - writes that user to /data/users (bcrypt) and points Radicale at it,
#   - then hands over to upstream's docker-entrypoint.sh, which applies the
#     RADICALE_CONFIG_* settings and drops to the radicale user.
# Extra users can be added to /data/users by hand (htpasswd lines); only the
# RADICALE_USER line is managed here. RADICALE_CONFIG_AUTH_TYPE set in the
# app settings (like none or ldap) turns all of this off.
set -eu

DIR=${ICESTORE_DIR:-/data}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

# ZimaOS passes settings left empty as empty strings; drop them so upstream's
# defaults apply.
for v in $(env | sed -n 's/^\(RADICALE_[A-Z0-9_]*\)=$/\1/p'); do
  unset "$v"
done

mkdir -p "$DIR"
USER_NAME=${RADICALE_USER:-admin}
URL="http://<your ZimaOS IP>:6886"
cred_reset

if [ -z "${RADICALE_CONFIG_AUTH_TYPE:-}" ]; then
  f="$DIR/.icestore-radicale-password"
  users="$DIR/users"
  ( umask 077
    if [ -n "${RADICALE_PASSWORD:-}" ]; then
      printf '%s' "$RADICALE_PASSWORD" > "$f.tmp" && mv "$f.tmp" "$f"
    elif [ ! -s "$f" ]; then
      head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$f.tmp" && mv "$f.tmp" "$f"
      log "first start: made the Radicale password ($f)"
    fi )
  PASS=$(cat "$f")
  # Rewrite only this user's line when the password no longer matches it.
  USER_NAME="$USER_NAME" PASS="$PASS" USERS="$users" /venv/bin/python - <<'PY'
import os
import bcrypt
user, pw, path = os.environ["USER_NAME"], os.environ["PASS"], os.environ["USERS"]
lines = open(path).read().splitlines() if os.path.exists(path) else []
mine = [l for l in lines if l.split(":", 1)[0] == user]
try:
    same = bool(mine) and bcrypt.checkpw(pw.encode(), mine[0].split(":", 1)[1].encode())
except ValueError:
    same = False
if not same:
    lines = [l for l in lines if l.split(":", 1)[0] != user] + [user + ":" + bcrypt.hashpw(pw.encode(), bcrypt.gensalt()).decode()]
    old = os.umask(0o077)
    with open(path + ".tmp", "w") as fh:
        fh.write("\n".join(lines) + "\n")
    os.umask(old)
    os.replace(path + ".tmp", path)
    print("[icestore] saved the login for " + user + " in " + path)
PY
  export RADICALE_CONFIG_AUTH_TYPE=htpasswd
  export RADICALE_CONFIG_AUTH_HTPASSWD_FILENAME="$users"
  export RADICALE_CONFIG_AUTH_HTPASSWD_ENCRYPTION=autodetect
  unset RADICALE_PASSWORD
  cred_add "URL" "$URL"
  cred_add "USER" "$USER_NAME"
  cred_add "PASSWORD" "$PASS"
  cred_note "Calendar and contacts apps use the same address, user and password."
else
  cred_add "URL" "$URL"
  cred_note "Login comes from your own RADICALE_CONFIG_AUTH_TYPE setting."
fi
unset RADICALE_USER
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:5232/.web/ &

exec docker-entrypoint.sh "$@"
