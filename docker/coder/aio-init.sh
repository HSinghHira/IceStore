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
DOCKER_SOCK=${AIO_DOCKER_SOCK:-/var/run/docker.sock}
GATEWAY_PORT=8080

log() { echo "[init] $*"; }

# ---- public address: Coder's CODER_ACCESS_URL ----
# Browsers and every workspace agent use it to reach Coder, so it must be an
# address workspaces can reach too (not localhost when they run in Docker).
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6145}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "WARNING: PUBLIC_URL is $PUBLIC_URL. Other devices and Docker workspaces cannot reach that."
    log "WARNING: Set PUBLIC_URL to your ZimaOS address, like http://192.168.1.20:6145" ;;
esac

# ---- one folder per stateful service under /data ----
# coder/ is the coder user's home: Terraform providers and modules, the
# server's config and its cache.
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/coder"
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

# PG_PASSWORD: postgres superuser. CODER_DB_PASSWORD: the "coder" role.
ensure_secret PG_PASSWORD 16
ensure_secret CODER_DB_PASSWORD 16
PG_PASSWORD=$(secret PG_PASSWORD)
CODER_DB_PASSWORD=$(secret CODER_DB_PASSWORD)

# ---- hostnames from the old two-container compose, all pointed at 127.0.0.1 ----
if ! grep -q ' coder-postgres' "$HOSTS"; then
  echo "127.0.0.1 postgres coder-postgres" >> "$HOSTS"
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

  # APP-SPECIFIC: /data/coder is the coder user's home (/home/coder, uid 1000),
  # so Terraform providers and the server's config survive updates.
  if [ "$(basename "$d")" = coder ]; then
    mkdir -p "$d/home/coder"
    if ! mountpoint -q "$d/home/coder"; then
      mount --bind "$DATA/coder" "$d/home/coder" 2>/dev/null \
        || log "WARNING: could not bind $DATA/coder to $d/home/coder; Coder's files will be lost on update"
    fi
    chown -R 1000:1000 "$DATA/coder" 2>/dev/null || true

    # Optional Docker workspaces: when the host's Docker socket is mounted at
    # /var/run/docker.sock, hand it to the chroot and let the coder user use it.
    rm -f "$RUN/coder.groups" 2>/dev/null || true
    if [ -S "$DOCKER_SOCK" ]; then
      # Alpine's /var/run is a symlink to /run. Followed from out here it
      # would point at this container's /run, so use the chroot's own run/.
      sockdir=$d/var/run
      [ -L "$sockdir" ] && sockdir=$d/run
      mkdir -p "$sockdir"
      [ -e "$sockdir/docker.sock" ] || : > "$sockdir/docker.sock"
      mountpoint -q "$sockdir/docker.sock" || mount --bind "$DOCKER_SOCK" "$sockdir/docker.sock" 2>/dev/null \
        || log "WARNING: could not pass $DOCKER_SOCK into Coder"
      DOCKER_GID=$(stat -c %g "$DOCKER_SOCK")
      log "Docker socket found (group $DOCKER_GID): Docker workspace templates can be used"
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

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 5432 "
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
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

[ -n "${DOCKER_GID:-}" ] && echo "$DOCKER_GID" > "$RUN/coder.groups"

# From Coder's docker-compose.yaml and `coder server --help`, with the
# database on 127.0.0.1 and Coder behind the gateway on 3000.
write_env coder "$TZV" \
  "HOME=/home/coder" \
  "CODER_HTTP_ADDRESS=127.0.0.1:3000" \
  "CODER_ACCESS_URL=$PUBLIC_URL" \
  "CODER_PG_CONNECTION_URL=postgresql://coder:$CODER_DB_PASSWORD@127.0.0.1:5432/coder?sslmode=disable" \
  "CODER_CACHE_DIRECTORY=/home/coder/.cache/coder"

# ---- settings: the README variables: list (Apps/coder/) ----
# Coder reads these itself on every start; blank ones are skipped, so they
# mean "default". The address, database and listen address are wired up above.
pass_env coder 'CODER_OIDC_(ISSUER_URL|CLIENT_ID|CLIENT_SECRET|SIGN_IN_TEXT|ICON_URL|ALLOW_SIGNUPS|EMAIL_DOMAIN|SCOPES|IGNORE_EMAIL_VERIFIED|USERNAME_FIELD|GROUP_FIELD|GROUP_AUTO_CREATE|REDIRECT_URL|SIGNUPS_DISABLED_TEXT)'
pass_env coder 'CODER_DISABLE_PASSWORD_AUTH'
pass_env coder 'CODER_OAUTH2_GITHUB_(CLIENT_ID|CLIENT_SECRET|ALLOW_SIGNUPS|ALLOWED_ORGS|ALLOWED_TEAMS|ALLOW_EVERYONE|ENTERPRISE_BASE_URL|DEFAULT_PROVIDER_ENABLE)'
pass_env coder 'CODER_EXTERNAL_AUTH_GITHUB_DEFAULT_PROVIDER_ENABLE'
pass_env coder 'CODER_EMAIL_(SMARTHOST|FROM|HELLO|AUTH_USERNAME|AUTH_PASSWORD|FORCE_TLS|TLS_STARTTLS|TLS_SKIPVERIFY)'
pass_env coder 'CODER_WILDCARD_ACCESS_URL|CODER_REDIRECT_TO_ACCESS_URL|CODER_SECURE_AUTH_COOKIE|CODER_STRICT_TRANSPORT_SECURITY'
pass_env coder 'CODER_PROXY_TRUSTED_HEADERS|CODER_PROXY_TRUSTED_ORIGINS|CODER_SESSION_DURATION|CODER_MAX_TOKEN_LIFETIME'
pass_env coder 'CODER_PROVISIONER_DAEMONS|CODER_DISABLE_PATH_APPS|CODER_DISABLE_OWNER_WORKSPACE_ACCESS|CODER_EXPERIMENTS'
pass_env coder 'CODER_DERP_SERVER_STUN_ADDRESSES|CODER_BLOCK_DIRECT|CODER_TELEMETRY_ENABLE|CODER_UPDATE_CHECK'
pass_env coder 'CODER_AUDIT_LOGS_RETENTION|CODER_WORKSPACE_AGENT_LOGS_RETENTION|CODER_VERBOSE|CODER_LOG_FILTER'

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

  # Upstream's "coder" user is the Postgres superuser (POSTGRES_USER=coder),
  # so it owns its database here and the migrations behave the same.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE coder LOGIN SUPERUSER PASSWORD '${CODER_DB_PASSWORD}';" \
    -c "CREATE DATABASE coder OWNER coder;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
