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

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

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

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
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
  return 0
}
# authentik keeps its temp files (TMPDIR=/dev/shm/) and Prometheus files here.
CHROOT_SHM_SIZE=512m
prep_chroots

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

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
# authentik only uses the bootstrap password when it first creates akadmin.
cred_reset
cred_add URL "http://<your ZimaOS IP>:6123"
cred_add ADMIN "http://<your ZimaOS IP>:6123/if/admin/"
cred_add USERNAME akadmin
if [ -n "${AUTHENTIK_BOOTSTRAP_PASSWORD_HASH:-}" ]; then
  cred_add PASSWORD "(the one behind AUTHENTIK_BOOTSTRAP_PASSWORD_HASH)"
elif [ -n "${ADMIN_PASSWORD:-}" ]; then
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PW"
  cred_note "Also saved in $SECRETS (ADMIN_PASSWORD_GENERATED)"
fi
cred_note "Changed it in authentik? Your new password is the one that works."

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
pg_setup /usr/lib/postgresql/16/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums

  # Upstream's "authentik" user is the Postgres superuser (POSTGRES_USER=authentik),
  # so it stays a superuser here and the migrations behave the same.
  pg_start_local
  pg_psql \
    -c "CREATE ROLE authentik LOGIN SUPERUSER PASSWORD '${AUTHENTIK_DB_PASSWORD}';" \
    -c "CREATE DATABASE authentik OWNER authentik;"
  pg_stop_local
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
