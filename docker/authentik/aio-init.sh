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

# ---- one folder per stateful service under /data ----
# authentik/ holds what upstream mounts into its containers:
#   data/       -> /data       (uploaded icons, backgrounds, other media)
#   certs/      -> /certs      (certificates authentik picks up by itself)
#   templates/  -> /templates  (your own email templates)
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" \
         "$DATA/authentik/data" "$DATA/authentik/certs" "$DATA/authentik/templates"
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

# PG_PASSWORD: postgres superuser. AUTHENTIK_DB_PASSWORD: the "authentik" role.
# AUTHENTIK_SECRET_KEY signs sessions and tokens; it must never change after
# users exist, so it is made once and kept.
# ADMIN_PASSWORD_GENERATED: used for akadmin when ADMIN_PASSWORD is blank.
ensure_secret PG_PASSWORD 16
ensure_secret AUTHENTIK_DB_PASSWORD 16
ensure_secret AUTHENTIK_SECRET_KEY 40
ensure_secret ADMIN_PASSWORD_GENERATED 9
PG_PASSWORD=$(secret PG_PASSWORD)
AUTHENTIK_DB_PASSWORD=$(secret AUTHENTIK_DB_PASSWORD)
AUTHENTIK_SECRET_KEY=$(secret AUTHENTIK_SECRET_KEY)

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'authentik_postgres' "$HOSTS"; then
  echo "127.0.0.1 postgresql authentik_postgres server worker" >> "$HOSTS"
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
  # authentik keeps its temp files (TMPDIR=/dev/shm/) and Prometheus files here.
  mkdir -p "$d/dev/shm"
  mountpoint -q "$d/dev/shm" || mount -t tmpfs -o size=512m tmpfs "$d/dev/shm" 2>/dev/null || true
  chmod 1777 "$d/dev/shm" 2>/dev/null || true
  [ -e "$d/dev/fd" ] || ln -s /proc/self/fd "$d/dev/fd" 2>/dev/null || true
  if [ -f "$d/proc/version" ]; then
    log "$d procfs mounted successfully"
  else
    log "WARNING: $d procfs is NOT mounted"
  fi

  # APP-SPECIFIC: authentik's /data, /certs and /templates live in /data/authentik.
  # Without these mounts its files would live in the image and vanish on update.
  if [ "$(basename "$d")" = authentik ]; then
    for m in data certs templates; do
      mkdir -p "$d/$m"
      if ! mountpoint -q "$d/$m"; then
        mount --bind "$DATA/authentik/$m" "$d/$m" 2>/dev/null \
          || log "WARNING: could not bind $DATA/authentik/$m to $d/$m; files will not survive an update"
      fi
    done
    # Outposts: if you add /var/run/docker.sock as a volume in the app
    # settings, authentik can start and manage its own outpost containers.
    if [ -S /var/run/docker.sock ]; then
      mkdir -p "$d/var/run"
      [ -e "$d/var/run/docker.sock" ] || : > "$d/var/run/docker.sock"
      mountpoint -q "$d/var/run/docker.sock" || mount --bind /var/run/docker.sock "$d/var/run/docker.sock" 2>/dev/null \
        || log "warning: could not pass the Docker socket to authentik"
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
# authentik builds every link from the browser's own address (Host header), so
# there is no PUBLIC_URL to set and no extra listen port is needed.
EXTRA_LISTEN=""
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# Admin account (akadmin). authentik reads the AUTHENTIK_BOOTSTRAP_* values
# only on its very first start, when it creates akadmin.
# ADMIN_PASSWORD blank = use the generated one, unless you gave a hash.
BOOT=()
if [ -n "${AUTHENTIK_BOOTSTRAP_PASSWORD_HASH:-}" ]; then
  ADMIN_PW=""
elif [ -n "${ADMIN_PASSWORD:-}" ]; then
  ADMIN_PW=$ADMIN_PASSWORD
else
  ADMIN_PW=$(secret ADMIN_PASSWORD_GENERATED)
fi
[ -n "$ADMIN_PW" ] && BOOT+=("AUTHENTIK_BOOTSTRAP_PASSWORD=$ADMIN_PW")
[ -n "${ADMIN_EMAIL:-}" ] && BOOT+=("AUTHENTIK_BOOTSTRAP_EMAIL=$ADMIN_EMAIL")

# From upstream's lifecycle/container/compose.yml (server + worker), with the
# database on 127.0.0.1 and the files under /data/authentik.
write_env authentik "$TZV" \
  "AUTHENTIK_SECRET_KEY=$AUTHENTIK_SECRET_KEY" \
  "AUTHENTIK_POSTGRESQL__HOST=127.0.0.1" \
  "AUTHENTIK_POSTGRESQL__PORT=5432" \
  "AUTHENTIK_POSTGRESQL__NAME=authentik" \
  "AUTHENTIK_POSTGRESQL__USER=authentik" \
  "AUTHENTIK_POSTGRESQL__PASSWORD=$AUTHENTIK_DB_PASSWORD" \
  "${BOOT[@]}"

# ---- settings: the compose environment: plus the README variables: list (Apps/authentik/) ----
# authentik reads every AUTHENTIK_* variable itself on each start (email,
# log level, cookie domain, update check, error reporting, bootstrap token...),
# so they go straight through; blank ones are skipped, so they mean "default".
# The database and the secret key are wired up above and are not passed again.
pass_env authentik 'AUTHENTIK_(EMAIL__[A-Z_]+|LOG_LEVEL|COOKIE_DOMAIN|DISABLE_UPDATE_CHECK|DISABLE_STARTUP_ANALYTICS|ERROR_REPORTING__ENABLED|BOOTSTRAP_TOKEN|BOOTSTRAP_PASSWORD_HASH|WEB__WORKERS|WEB__THREADS|WORKER__PROCESSES|WORKER__THREADS|OUTPOSTS__[A-Z_]+|STORAGE__[A-Z0-9_]+|SESSIONS__[A-Z_]+)'

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

pgbin=/usr/lib/postgresql/16/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  # Upstream's "authentik" user is the Postgres superuser (POSTGRES_USER=authentik),
  # so it stays a superuser here and the migrations behave the same.
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE authentik LOGIN SUPERUSER PASSWORD '${AUTHENTIK_DB_PASSWORD}';" \
    -c "CREATE DATABASE authentik OWNER authentik;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"

  if [ -n "${AUTHENTIK_BOOTSTRAP_PASSWORD_HASH:-}" ]; then
    log "the akadmin password is the one from AUTHENTIK_BOOTSTRAP_PASSWORD_HASH"
  elif [ -n "${ADMIN_PASSWORD:-}" ]; then
    log "the akadmin password is the one you set in ADMIN_PASSWORD"
  else
    log "sign in as akadmin; the admin password is: $ADMIN_PW"
  fi
else
  if [ -z "${ADMIN_PASSWORD:-}" ] && [ -z "${AUTHENTIK_BOOTSTRAP_PASSWORD_HASH:-}" ]; then
    log "the first akadmin password is kept in /data/state/secrets.env (ADMIN_PASSWORD_GENERATED)"
  fi
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
