#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each service's
# environment, prepares the database, then hands over to supervisord.
set -euo pipefail

DATA=${AIO_DATA:-/data}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}
HOSTS=${AIO_HOSTS:-/etc/hosts}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/aio.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/aio.conf}
GATEWAY_PORT=8080

log() { echo "[init] $*"; }

# ---- public address: the base of every booking link and email link ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6137}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost:*|*://localhost|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL: booking links and emails will point at localhost."
    log "Set PUBLIC_URL to http://<your ZimaOS IP>:6137 (or your https address) in the app settings." ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -hex "$2")" >> "$SECRETS"
  fi
  return 0
}
secret() { sed -n "s/^$1=//p" "$SECRETS"; }

ensure_secret PG_PASSWORD 16
# Signs and encrypts the login session cookie (16+ characters).
ensure_secret SESSION_ENCRYPTION_KEY 32
# AES-256-GCM key for Google tokens at rest: exactly 64 hex characters.
ensure_secret TOKEN_ENCRYPTION_KEY 32
ensure_secret GOOGLE_OAUTH_STATE_SECRET 32

PG_PASSWORD=$(secret PG_PASSWORD)

# Your own values from the app settings win over the generated ones. Changing
# TOKEN_ENCRYPTION_KEY later makes stored Google connections unreadable.
SESSION_KEY=${SESSION_ENCRYPTION_KEY:-$(secret SESSION_ENCRYPTION_KEY)}
TOKEN_KEY=${TOKEN_ENCRYPTION_KEY:-$(secret TOKEN_ENCRYPTION_KEY)}
STATE_SECRET=${GOOGLE_OAUTH_STATE_SECRET:-$(secret GOOGLE_OAUTH_STATE_SECRET)}

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' calit_db' "$HOSTS"; then
  echo "127.0.0.1 db calit_db calit_app" >> "$HOSTS"
fi

# ---- generic: prepare every chroot filesystem under /opt/rootfs ----
for d in "$ROOTFS"/*/; do
  [ -d "$d" ] || continue
  mkdir -p "$d/dev" "$d/etc" "$d/tmp" "$d/proc" "$d/sys"
  chmod 1777 "$d/tmp"
  cat "$HOSTS" > "$d/etc/hosts"
  [ -f /etc/resolv.conf ] && cat /etc/resolv.conf > "$d/etc/resolv.conf"

  if ! mountpoint -q "$d/proc"; then
    mount -t proc proc "$d/proc" 2>/dev/null || mount --rbind /proc "$d/proc" 2>/dev/null || {
      err=$(mount --rbind /proc "$d/proc" 2>&1 || true)
      log "warning: could not mount proc into $d/proc: $err"
    }
  fi
  mountpoint -q "$d/sys" || mount --rbind /sys "$d/sys" 2>/dev/null || true
  mkdir -p "$d/dev/shm"
  mountpoint -q "$d/dev/shm" || mount -t tmpfs tmpfs "$d/dev/shm" 2>/dev/null || true
  chmod 1777 "$d/dev/shm" 2>/dev/null || true
  [ -e "$d/dev/fd" ] || ln -s /proc/self/fd "$d/dev/fd" 2>/dev/null || true
  if [ -f "$d/proc/version" ]; then
    log "$d procfs mounted successfully"
  else
    log "WARNING: $d procfs is NOT mounted"
  fi

  [ -e "$d/dev/null" ]    || mknod -m 666 "$d/dev/null" c 1 3    2>/dev/null || log "warning: could not create $d/dev/null"
  [ -e "$d/dev/zero" ]    || mknod -m 666 "$d/dev/zero" c 1 5    2>/dev/null || true
  [ -e "$d/dev/random" ]  || mknod -m 666 "$d/dev/random" c 1 8  2>/dev/null || true
  [ -e "$d/dev/urandom" ] || mknod -m 666 "$d/dev/urandom" c 1 9 2>/dev/null || true
  [ -e "$d/dev/stdin" ] || : > "$d/dev/stdin"
  for f in stdout stderr; do
    [ -p "$d/dev/$f" ] && continue
    rm -f "$d/dev/$f"
    mkfifo -m 666 "$d/dev/$f" 2>/dev/null || : > "$d/dev/$f"
  done
done

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 8081 5432 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# calit's prod profile has no default for the MAIL_* values and won't start
# without them. With no SMTP server set, point it at a closed local port:
# bookings still work, mail waits in calit's outbox (the dashboard shows a
# banner) and goes out once MAIL_HOST is set.
if [ -z "${MAIL_HOST:-}" ]; then
  log "MAIL_HOST is not set: calit can't send booking emails until you add your SMTP settings"
fi

# calit forces a Secure CSRF cookie in production, which browsers drop on a
# plain http:// address other than localhost, so every form would fail. Only
# force it when the app is served over https.
CSRF_SECURE=true
case $PUBLIC_URL in http://*) CSRF_SECURE=false ;; esac

write_env calit "$TZV" \
  "QUARKUS_HTTP_PORT=8081" \
  "QUARKUS_HTTP_HOST=127.0.0.1" \
  "DB_URL=jdbc:postgresql://127.0.0.1:5432/calit" \
  "DB_USER=calit" \
  "DB_PASSWORD=$PG_PASSWORD" \
  "APP_BASE_URL=$PUBLIC_URL" \
  "SESSION_ENCRYPTION_KEY=$SESSION_KEY" \
  "TOKEN_ENCRYPTION_KEY=$TOKEN_KEY" \
  "GOOGLE_OAUTH_STATE_SECRET=$STATE_SECRET" \
  "_PROD_QUARKUS_REST_CSRF_COOKIE_FORCE_SECURE=$CSRF_SECURE" \
  "MAIL_HOST=${MAIL_HOST:-127.0.0.1}" \
  "MAIL_PORT=${MAIL_PORT:-587}" \
  "MAIL_USERNAME=${MAIL_USERNAME:-calit}" \
  "MAIL_PASSWORD=${MAIL_PASSWORD:-unset}" \
  "MAIL_FROM=${MAIL_FROM:-calit@example.com}" \
  "MAIL_START_TLS=${MAIL_START_TLS:-REQUIRED}" \
  "MAIL_TLS=${MAIL_TLS:-false}"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional calit setting from the README Variables list, by its own name.
pass_env calit 'SIGNUP_ENABLED|REMINDER_LEAD_MINUTES|APPROVAL_HOLD_HOURS|SCHEDULER_GRACE_SECONDS|PER_EMAIL_DAILY_CAP|GOOGLE_OAUTH_CLIENT_ID|GOOGLE_OAUTH_CLIENT_SECRET|GOOGLE_OAUTH_REDIRECT_URI|GOOGLE_OAUTH_LOGIN_REDIRECT_URI|GOOGLE_PROBE_INTERVAL|GOOGLE_SITE_VERIFICATION|OPERATOR_NAME|PRIVACY_CONTACT_EMAIL|TURNSTILE_ENABLED|TURNSTILE_SITE_KEY|TURNSTILE_SECRET_KEY|CAPTCHA_PROVIDER|ALTCHA_HMAC_KEY|ALTCHA_MAX_NUMBER|OIDC_ENABLED|OIDC_ISSUER_URL|OIDC_CLIENT_ID|OIDC_CLIENT_SECRET|OIDC_ADMIN_GROUP|NOTIFY_ALLOWED_SCHEMES|NOTIFY_ALLOW_PRIVATE|NOTIFY_MAX_ATTEMPTS|INVITEE_ERASURE|BOOKING_RETENTION_DAYS|CALDAV_ALLOW_PRIVATE_HOSTS|QUARKUS_LOG_[A-Z0-9_]+'

# Files in /data/state/overrides/<service>.env are appended last, so users can
# change any service setting without rebuilding the image.
for f in "$STATE"/overrides/*.env; do
  [ -f "$f" ] || continue
  svc=$(basename "$f" .env)
  log "applying your overrides to $svc"
  cat "$f" >> "$RUN/$svc.env"
done

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

# ---- built-in data folders and first-start database ----
pgbin=/usr/lib/postgresql/18/bin
id postgres >/dev/null
mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql "$DATA/postgres"
chmod 700 "$DATA/postgres"

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  # calit's own role and database (upstream's db service makes these from
  # POSTGRES_USER / POSTGRES_DB). Flyway creates the tables on calit's start.
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses=''" -w start >/dev/null
  setpriv --reuid=postgres --regid=postgres --init-groups \
    psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
      -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE calit LOGIN PASSWORD :'pw';
CREATE DATABASE calit OWNER calit;
SQL
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
