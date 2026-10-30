#!/bin/sh
# IceStore start script for Dokploy.
#
# Dokploy's own installer (dokploy.com/install.sh) runs on the host. On ZimaOS
# the app is a normal container instead, so this script does the installer's
# work through the Docker socket on every start (each step is skipped when it
# is already done):
#
#   1. BETTER_AUTH_SECRET and the Postgres password: made once per install
#      and kept in /data (.better_auth_secret, .postgres_password). A
#      BETTER_AUTH_SECRET from the app settings wins and is written there.
#   2. Docker Swarm: joined with `docker swarm init` if the host isn't in a
#      swarm yet (Dokploy deploys apps as swarm services).
#   3. The dokploy-network overlay network, and this container joined to it
#      with the alias "dokploy" (Traefik and Postgres are reached by name).
#   4. The dokploy-postgres swarm service, like upstream's, but with its data
#      in this app's data folder (/data/postgres) and endpoint mode dnsrr
#      (ZimaOS kernels have no IPVS).
#   5. The dokploy-traefik container, on TRAEFIK_PORT / TRAEFIK_SSL_PORT
#      (6184 / 6185) instead of 80 / 443, which ZimaOS uses itself. Made once
#      Dokploy has written /etc/dokploy/traefik/traefik.yml.
#
# Then upstream's own start command runs (wait for Postgres, migrate, serve).
# Paths can be moved for testing outside Docker (ICESTORE_DATA, ...); put a
# fake `docker` first in PATH to test without a Docker host.
set -eu

DATA=${ICESTORE_DATA:-/data}
ETC=${ICESTORE_ETC:-/etc/dokploy}
APP_DIR=${ICESTORE_APP_DIR:-/app}
NET=dokploy-network
POSTGRES_IMAGE=postgres:16
log() { echo "[icestore] $*"; }
fail() { log "ERROR: $*"; exit 1; }

mkdir -p "$DATA" "$ETC"

# ---- 1. secrets ------------------------------------------------------------
# new_secret FILE: 32 random bytes as 64 hex characters, made once.
new_secret() {
  old_umask=$(umask)
  umask 077
  head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$1.tmp"
  mv "$1.tmp" "$1"
  umask "$old_umask"
}

auth_file=$DATA/.better_auth_secret
if [ -n "${BETTER_AUTH_SECRET:-}" ]; then
  if [ -s "$auth_file" ] && [ "$(cat "$auth_file")" != "$BETTER_AUTH_SECRET" ]; then
    log "BETTER_AUTH_SECRET differs from the one used before; using BETTER_AUTH_SECRET. The old one is saved as .better_auth_secret.previous."
    cp "$auth_file" "$auth_file.previous"
  fi
  old_umask=$(umask); umask 077
  printf '%s' "$BETTER_AUTH_SECRET" > "$auth_file.tmp"
  mv "$auth_file.tmp" "$auth_file"
  umask "$old_umask"
elif [ ! -s "$auth_file" ]; then
  new_secret "$auth_file"
  log "first start: made this install's BETTER_AUTH_SECRET in the data folder (.better_auth_secret)."
fi
# Dokploy reads the file (BETTER_AUTH_SECRET_FILE, set in the image).
unset BETTER_AUTH_SECRET

pg_file=$DATA/.postgres_password
if [ ! -s "$pg_file" ]; then
  new_secret "$pg_file"
  log "first start: made this install's Postgres password in the data folder (.postgres_password)."
fi

# ---- settings ----------------------------------------------------------------
[ -n "${TRAEFIK_PORT:-}" ] || TRAEFIK_PORT=6184
[ -n "${TRAEFIK_SSL_PORT:-}" ] || TRAEFIK_SSL_PORT=6185
[ -n "${TRAEFIK_HTTP3_PORT:-}" ] || TRAEFIK_HTTP3_PORT=$TRAEFIK_SSL_PORT
export TRAEFIK_PORT TRAEFIK_SSL_PORT TRAEFIK_HTTP3_PORT

# Blank values from the app settings mean "use the default".
for name in TRAEFIK_VERSION ADVERTISE_ADDR DOCKER_SWARM_INIT_ARGS \
            DOKPLOY_DOCKER_API_VERSION OPENAPI_MAX_JSON_BODY_SIZE \
            OPENAPI_MAX_UPLOAD_SIZE; do
  eval "val=\${$name-unset}"
  [ -n "$val" ] || unset "$name"
done

# The Traefik version Dokploy itself uses when it recreates Traefik.
traefik_version=${TRAEFIK_VERSION:-}
if [ -z "$traefik_version" ]; then
  traefik_version=$(grep -rhoE 'TRAEFIK_VERSION *\|\| *"[0-9][0-9.]*"' "$APP_DIR/dist" 2>/dev/null \
    | head -n 1 | grep -oE '[0-9][0-9.]*' || true)
  [ -n "$traefik_version" ] || traefik_version=3.6.25
fi

# ---- 2. swarm ----------------------------------------------------------------
docker version >/dev/null 2>&1 \
  || fail "can't reach Docker. The app needs /var/run/docker.sock mounted."

state=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || true)
case $state in
  active) ;;
  inactive|"")
    addr=${ADVERTISE_ADDR:-127.0.0.1}
    log "Docker isn't in a swarm yet: running docker swarm init --advertise-addr $addr ${DOCKER_SWARM_INIT_ARGS:-}"
    # shellcheck disable=SC2086 # DOCKER_SWARM_INIT_ARGS is a list of flags
    if ! docker swarm init --advertise-addr "$addr" ${DOCKER_SWARM_INIT_ARGS:-}; then
      # Some Docker versions refuse a loopback address: use the host's
      # address on this container's network (the default gateway).
      gw=$(ip route 2>/dev/null | awk '/^default/ {print $3; exit}')
      [ -z "${ADVERTISE_ADDR:-}" ] && [ -n "$gw" ] \
        || fail "docker swarm init failed. Set ADVERTISE_ADDR to your ZimaOS IP and restart the app."
      log "retrying with --advertise-addr $gw"
      # shellcheck disable=SC2086
      docker swarm init --advertise-addr "$gw" ${DOCKER_SWARM_INIT_ARGS:-} \
        || fail "docker swarm init failed. Set ADVERTISE_ADDR to your ZimaOS IP and restart the app."
    fi
    ;;
  *)
    fail "Docker's swarm state is '$state'. Fix it on the host (docker info) and restart the app." ;;
esac
[ "$(docker info --format '{{.Swarm.ControlAvailable}}' 2>/dev/null || true)" = true ] \
  || fail "this Docker host is in a swarm but isn't a manager. Dokploy must run on a swarm manager."

# ---- 3. network --------------------------------------------------------------
if ! docker network inspect "$NET" >/dev/null 2>&1; then
  docker network create --driver overlay --attachable "$NET" >/dev/null
  log "made the $NET network."
fi

self=${ICESTORE_SELF:-}
if [ -z "$self" ]; then
  for c in dokploy "$(hostname)"; do
    if docker inspect "$c" >/dev/null 2>&1; then self=$c; break; fi
  done
fi
[ -n "$self" ] || fail "can't find this app's own container (named dokploy)."

if ! docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$self" \
     | tr ' ' '\n' | grep -qx "$NET"; then
  docker network connect --alias dokploy "$NET" "$self"
  log "joined this container to $NET."
fi

# ---- 4. postgres -------------------------------------------------------------
if ! docker service inspect dokploy-postgres >/dev/null 2>&1; then
  host_data=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "'"$DATA"'"}}{{.Source}}{{end}}{{end}}' "$self")
  [ -n "$host_data" ] || fail "can't find where $DATA is on the host."
  mkdir -p "$DATA/postgres"
  # Swarm secrets can't change while in use; nothing uses this one now.
  docker secret rm dokploy_postgres_password >/dev/null 2>&1 || true
  docker secret create dokploy_postgres_password "$pg_file" >/dev/null
  docker service create --detach \
    --name dokploy-postgres \
    --constraint 'node.role==manager' \
    --network "$NET" \
    --endpoint-mode dnsrr \
    --env POSTGRES_USER=dokploy \
    --env POSTGRES_DB=dokploy \
    --secret source=dokploy_postgres_password,target=/run/secrets/postgres_password \
    --env POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password \
    --mount "type=bind,source=$host_data/postgres,target=/var/lib/postgresql/data" \
    "$POSTGRES_IMAGE" >/dev/null
  log "made the dokploy-postgres service ($POSTGRES_IMAGE, data in $host_data/postgres)."
fi

if [ -n "${ICESTORE_DRY_RUN:-}" ]; then
  env | grep -E '^(TRAEFIK_|BETTER_AUTH|POSTGRES_|DOCKER_SWARM|ADVERTISE)' | sort
  echo "traefik_version=$traefik_version"
  exit 0
fi

# ---- 5. traefik (once Dokploy has written its config) ------------------------
start_traefik() {
  i=0
  while [ ! -s "$ETC/traefik/traefik.yml" ]; do
    i=$((i + 1))
    [ "$i" -le 300 ] || { log "no $ETC/traefik/traefik.yml after 5 minutes; Traefik not started."; return 1; }
    sleep 1
  done
  # Already there, or left for Dokploy to restore after an interrupted update.
  for c in dokploy-traefik dokploy-traefik-previous; do
    docker inspect "$c" >/dev/null 2>&1 && return 0
  done
  docker service inspect dokploy-traefik >/dev/null 2>&1 && return 0
  docker run -d --name dokploy-traefik --restart always --network "$NET" \
    -v "$ETC/traefik/traefik.yml:/etc/traefik/traefik.yml" \
    -v "$ETC/traefik/dynamic:/etc/dokploy/traefik/dynamic" \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -p "$TRAEFIK_PORT:$TRAEFIK_PORT/tcp" \
    -p "$TRAEFIK_SSL_PORT:$TRAEFIK_SSL_PORT/tcp" \
    -p "$TRAEFIK_HTTP3_PORT:$TRAEFIK_HTTP3_PORT/udp" \
    "traefik:v$traefik_version" >/dev/null
  log "made the dokploy-traefik container (traefik:v$traefik_version) on ports $TRAEFIK_PORT and $TRAEFIK_SSL_PORT."
}
( start_traefik || log "Traefik could not be started; open Dokploy > Web Server > Traefik and reload it." ) &

# ---- hand over to upstream ----------------------------------------------------
cd "$APP_DIR"
exec "$@"
