#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each
# service's environment, prepares the database, then hands over to
# supervisord.
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

# ---- public addresses ----
# PUBLIC_URL is Trackie (upstream's SERVER_HOSTNAME). Logto's sign-in server
# and admin console use the same host with ports 6165 and 6166, unless
# LOGTO_ENDPOINT or LOGTO_ADMIN_ENDPOINT say otherwise (for your own domains).
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6164}
PUBLIC_URL=${PUBLIC_URL%/}
# The compose file ships http://[ZIMAOS-IP-ADDRESS]:6164 so people see they
# must put their IP there. Until they do, run on localhost (so Logto starts)
# and show the "set PUBLIC_URL" note to every other address (below).
case $PUBLIC_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "PUBLIC_URL is still $PUBLIC_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings"
    PUBLIC_URL=${PUBLIC_URL//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
proto=${PUBLIC_URL%%://*}
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
host=${hostport%:*}
LOGTO_URL=${LOGTO_ENDPOINT:-$proto://$host:6165}
LOGTO_ADMIN_URL=${LOGTO_ADMIN_ENDPOINT:-$proto://$host:6166}
LOGTO_URL=${LOGTO_URL%/}
LOGTO_ADMIN_URL=${LOGTO_ADMIN_URL%/}
for u in "$LOGTO_URL" "$LOGTO_ADMIN_URL"; do
  case $u in
    http://*|https://*) ;;
    *) log "every address must start with http:// or https:// (got: $u)"; exit 1 ;;
  esac
done
log "trackie: $PUBLIC_URL  sign-in (Logto): $LOGTO_URL  Logto admin console: $LOGTO_ADMIN_URL"
if [ "$host" = localhost ]; then
  log "PUBLIC_URL uses localhost, so sign-in only works on this server; set it to http://[ZIMAOS-IP-ADDRESS]:6164 with your IP"
fi

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/trackie" "$DATA/logto"
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

# PG_PASSWORD: postgres superuser. LOGTO_DB_PASSWORD: the "logto" role.
# ACTUAL_IDENTITY_SECRET turns each verified email into the account's id:
# changing it cuts every person off from their budget, so it never changes.
# ACTUAL_AKAHU_TOKEN_SECRET encrypts people's Akahu bank tokens.
ensure_secret PG_PASSWORD 16
ensure_secret LOGTO_DB_PASSWORD 16
ensure_secret ACTUAL_IDENTITY_SECRET 32
ensure_secret ACTUAL_AKAHU_TOKEN_SECRET 32
PG_PASSWORD=$(secret PG_PASSWORD)
LOGTO_DB_PASSWORD=$(secret LOGTO_DB_PASSWORD)
if [ -n "${ACTUAL_IDENTITY_SECRET:-}" ] && [ "$ACTUAL_IDENTITY_SECRET" != "$(secret ACTUAL_IDENTITY_SECRET)" ]; then
  log "WARNING: ACTUAL_IDENTITY_SECRET from the app settings differs from the one made on first start."
  log "People who signed in before will not find their budgets. Remove it from the app settings to go back."
fi

# ---- hostnames from upstream's compose files, all pointed at 127.0.0.1 ----
if ! grep -q 'logto-db' "$HOSTS"; then
  echo "127.0.0.1 server logto logto-db" >> "$HOSTS"
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

  # APP-SPECIFIC: /data/trackie is Trackie's /data (budgets, accounts and its
  # SQLite databases, upstream's volume), owned by the image's "actual" user.
  if [ "$(basename "$d")" = trackie ]; then
    mkdir -p "$d/data"
    if ! mountpoint -q "$d/data"; then
      mount --bind "$DATA/trackie" "$d/data" 2>/dev/null \
        || log "WARNING: could not bind $DATA/trackie to $d/data; budgets would be lost on update"
    fi
    uid=$(awk -F: '$1=="actual"{print $3":"$4}' "$d/etc/passwd" 2>/dev/null || true)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/trackie" 2>/dev/null || true
  fi
  # APP-SPECIFIC: /data/logto is Logto's /aio-state (remembers that the
  # signing key was switched to RSA). Logto keeps everything else in Postgres.
  if [ "$(basename "$d")" = logto ]; then
    mkdir -p "$d/aio-state"
    if ! mountpoint -q "$d/aio-state"; then
      mount --bind "$DATA/logto" "$d/aio-state" 2>/dev/null \
        || log "WARNING: could not bind $DATA/logto to $d/aio-state"
    fi
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

# ---- gateway ----
# 8080 Trackie (+ the PUBLIC_URL port), 8081 Logto (+ its port), 8082 the
# Logto admin console (+ its port). Trackie calls Logto's address from inside
# the container, so with a localhost address those ports must answer in here
# too.
INTERNAL_PORTS=" 3001 3002 5006 5432 8080 8081 8082 "
port_of() {
  local hp=${1#*://}
  hp=${hp%%/*}
  [[ $hp == *:* ]] && echo "${hp##*:}"
  return 0
}
extra_listen() {
  local p=$1
  [[ $p =~ ^[0-9]+$ ]] || return 0
  case "$INTERNAL_PORTS" in
    *" $p "*) log "port $p is used inside the container; calls to it from inside may fail" ;;
    *) echo "listen $p;" ;;
  esac
}
WEB_PORT=$(port_of "$PUBLIC_URL")
LOGTO_PORT=$(port_of "$LOGTO_URL")
ADMIN_PORT=$(port_of "$LOGTO_ADMIN_URL")
EXTRA_LISTEN=$(extra_listen "$WEB_PORT")
LOGTO_EXTRA_LISTEN=""
[ "$LOGTO_PORT" = "$WEB_PORT" ] || LOGTO_EXTRA_LISTEN=$(extra_listen "$LOGTO_PORT")
ADMIN_EXTRA_LISTEN=""
[ "$ADMIN_PORT" = "$WEB_PORT" ] || [ "$ADMIN_PORT" = "$LOGTO_PORT" ] || ADMIN_EXTRA_LISTEN=$(extra_listen "$ADMIN_PORT")
# Logto's addresses are fixed (they are in every sign-in token), so with
# the default PUBLIC_URL (localhost) every sign-in from another device is
# sent to localhost and fails. In that case anyone opening Trackie or Logto
# from another address gets a short note saying what to set instead.
# Requests to localhost/127.0.0.1 (the box itself, the healthcheck, Trackie
# calling Logto) still go through.
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Trackie is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so sign-in would send you to localhost.\n\nOpen the Trackie app settings in ZimaOS, set PUBLIC_URL to http://$host:6164 and save. After the app restarts, open http://$host:6166 for the Logto admin console.\n";
}
EOF
    ;;
  *) : > "$GUARD_FILE" ;;
esac
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@LOGTO_EXTRA_LISTEN@/$LOGTO_EXTRA_LISTEN/g" -e "s/@ADMIN_EXTRA_LISTEN@/$ADMIN_EXTRA_LISTEN/g" \
    -e "s/@ADMIN_PORT@/${ADMIN_PORT:-6166}/g" -e "s/@GUARD_FILE@/$(sed_escape "$GUARD_FILE")/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# From upstream's compose.logto.yml, with Postgres on 127.0.0.1. Logto is
# always behind the gateway, so it reads X-Forwarded-Proto.
write_env logto "$TZV" \
  "NODE_ENV=production" \
  "TRUST_PROXY_HEADER=1" \
  "DB_URL=postgres://logto:$LOGTO_DB_PASSWORD@127.0.0.1:5432/logto" \
  "ENDPOINT=$LOGTO_URL" \
  "ADMIN_ENDPOINT=$LOGTO_ADMIN_URL"

# From upstream's compose.yml. Trackie can only sign people in through Logto,
# so it is started once both values from the Logto console are set.
OIDC_ID=${ACTUAL_OPENID_CLIENT_ID:-}
OIDC_SECRET=${ACTUAL_OPENID_CLIENT_SECRET:-}
write_env trackie "$TZV" \
  "NODE_ENV=production" \
  "ACTUAL_LOGIN_METHOD=openid" \
  "ACTUAL_OPENID_ENFORCE=true" \
  "ACTUAL_USER_CREATION_MODE=login" \
  "ACTUAL_OPENID_SERVER_HOSTNAME=$PUBLIC_URL" \
  "ACTUAL_OPENID_DISCOVERY_URL=${ACTUAL_OPENID_DISCOVERY_URL:-$LOGTO_URL/oidc/.well-known/openid-configuration}" \
  "ACTUAL_OPENID_CLIENT_ID=$OIDC_ID" \
  "ACTUAL_OPENID_CLIENT_SECRET=$OIDC_SECRET" \
  "ACTUAL_TOKEN_EXPIRATION=${ACTUAL_TOKEN_EXPIRATION:-7776000}" \
  "ACTUAL_IDENTITY_SECRET=${ACTUAL_IDENTITY_SECRET:-$(secret ACTUAL_IDENTITY_SECRET)}" \
  "ACTUAL_AKAHU_TOKEN_SECRET=${ACTUAL_AKAHU_TOKEN_SECRET:-$(secret ACTUAL_AKAHU_TOKEN_SECRET)}"
if [ -z "$OIDC_ID" ] || [ -z "$OIDC_SECRET" ]; then
  echo "AIO_OIDC_MISSING=1" >> "$RUN/trackie.env"
  log "Trackie is not registered in Logto yet, so it waits. Open the Logto admin console at $LOGTO_ADMIN_URL,"
  log "add Trackie as a Traditional Web app with the redirect URI $PUBLIC_URL/openid/callback,"
  log "then set ACTUAL_OPENID_CLIENT_ID and ACTUAL_OPENID_CLIENT_SECRET in the app settings."
fi

# ---- settings: the README variables: list (Apps/trackie/) ----
# Trackie reads these itself on every start; blank ones are skipped, so they
# mean "default".
pass_env trackie 'TRACKIE_SUPPORT_EMAIL|ACTUAL_UPLOAD_[A-Z_]+'

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
id postgres >/dev/null
mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql "$DATA/postgres"
chmod 700 "$DATA/postgres"

pgbin=/usr/lib/postgresql/17/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  # Upstream's "logto" user is the Postgres superuser (POSTGRES_USER=logto),
  # so it stays one here: Logto's seed creates its own roles.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE logto LOGIN SUPERUSER PASSWORD '${LOGTO_DB_PASSWORD}';" \
    -c "CREATE DATABASE logto OWNER logto;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
