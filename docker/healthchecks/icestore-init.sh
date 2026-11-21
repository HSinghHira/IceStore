#!/bin/bash
# IceStore start script for Healthchecks. Runs as root, once per start:
#
#   - SECRET_KEY: set in the app settings wins; blank means the one in
#     /data/secrets.env, made on first start.
#   - ADMIN_PASSWORD: blank means the one in /data/.admin_password, made on
#     first start. The admin account (ADMIN_EMAIL) is made once, when there
#     is none yet.
#   - DB=sqlite in /data; DEBUG off; ALLOWED_HOSTS * unless you set it.
#   - SITE_ROOT: while it still has [ZIMAOS-IP-ADDRESS], localhost is used
#     and the log says what to do (the ping URLs Healthchecks shows use it).
#   - Every other blank variable is dropped, so Healthchecks uses its
#     default (ZimaOS passes settings left empty as empty strings).
#
# Then upstream's run.sh runs as hc (migrations, alerts, reports, gunicorn).
set -euo pipefail

DATA=/data
SECRETS=$DATA/secrets.env
PASS_FILE=$DATA/.admin_password
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

rand() { python -c "import secrets; print(secrets.token_hex($1))"; }

mkdir -p "$DATA"
umask 077
touch "$SECRETS"

# ---- secrets ----
grep -q '^SECRET_KEY=' "$SECRETS" || echo "SECRET_KEY=$(rand 32)" >> "$SECRETS"
[ -n "${SECRET_KEY:-}" ] || SECRET_KEY=$(secret SECRET_KEY)
export SECRET_KEY

[ -n "${ADMIN_EMAIL:-}" ] || ADMIN_EMAIL=admin@example.com
PASSWORD_SET=
if [ -n "${ADMIN_PASSWORD:-}" ]; then
  PASSWORD_SET=1
elif [ -s "$PASS_FILE" ]; then
  ADMIN_PASSWORD=$(cat "$PASS_FILE")
else
  rand 12 > "$PASS_FILE.tmp"
  mv "$PASS_FILE.tmp" "$PASS_FILE"
  ADMIN_PASSWORD=$(cat "$PASS_FILE")
  log "first start: made the admin password in /data/.admin_password."
fi
umask 022

# ---- every other blank variable: Healthchecks' default ----
for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done
DB=sqlite
DB_NAME=$DATA/hc.sqlite
[ -n "${DEBUG:-}" ] || DEBUG=False
[ -n "${ALLOWED_HOSTS:-}" ] || ALLOWED_HOSTS='*'
SITE_ROOT=${SITE_ROOT:-http://[ZIMAOS-IP-ADDRESS]:6773}
case $SITE_ROOT in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "SITE_ROOT is still $SITE_ROOT: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings, like http://192.168.1.20:6773, so the ping URLs Healthchecks shows work from your other machines."
    SITE_ROOT=${SITE_ROOT//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
export DB DB_NAME DEBUG ALLOWED_HOSTS SITE_ROOT
unset DB_HOST DB_PORT DB_USER DB_PASSWORD 2>/dev/null || true

chown -R hc "$DATA"
cd /opt/healthchecks
as_hc() { setpriv --reuid=hc --regid="$(id -g hc)" --init-groups "$@"; }

# ---- database and the admin account ----
as_hc ./manage.py migrate --no-input
if ADMIN_EMAIL=$ADMIN_EMAIL as_hc ./manage.py shell -c "
import os, sys
from django.contrib.auth.models import User
sys.exit(0 if User.objects.filter(is_superuser=True).exists() else 3)
" ; then
  :
else
  log "first start: making the admin account $ADMIN_EMAIL"
  # Healthchecks' own createsuperuser: the email is the login (no username).
  as_hc ./manage.py createsuperuser --email "$ADMIN_EMAIL" --password "$ADMIN_PASSWORD" </dev/null
fi
unset ADMIN_PASSWORD

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "$(cred_url "$SITE_ROOT")"
cred_add EMAIL "$ADMIN_EMAIL"
if [ -n "$PASSWORD_SET" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$(cat "$PASS_FILE")"
  cred_note "Also saved in /DATA/AppData/healthchecks/data/.admin_password"
fi
cred_note "Only used for the first account. Change it in Account Settings after you sign in."
/usr/local/lib/icestore/credentials.sh http://127.0.0.1:8000/health &

exec setpriv --reuid=hc --regid="$(id -g hc)" --init-groups "$@"
