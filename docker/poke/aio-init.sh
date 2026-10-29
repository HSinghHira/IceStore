#!/bin/bash
# First thing that runs in the container. Makes secrets, writes the config
# files of Poke and Invidious and each service's environment, prepares the
# database, then hands over to supervisord.
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

# ---- public address ----
# Poke has no setting for its own address. It puts the video address (the
# companion, served by the gateway at /companion) into its pages; that is
# http://127.0.0.1:8080 here, and the gateway rewrites it to whatever address
# the browser used. So Poke works from localhost, the LAN IP or a domain.
GATEWAY_URL=http://127.0.0.1:$GATEWAY_PORT

# ---- one folder per stateful service under /data ----
#   postgres/  Invidious' database (video and channel cache)
#   poke/      json.sqlite: Poke accounts and subscriptions
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/poke"
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

# PG_PASSWORD: postgres superuser. INVIDIOUS_DB_PASSWORD: the "kemal" role.
# INVIDIOUS_HMAC_KEY signs Invidious tokens. COMPANION_KEY is shared by
# Invidious and its companion and must be exactly 16 characters (8 bytes hex).
# POKE_SUB_SECRET signs Poke's account and subscription tokens; changing it
# signs everyone out.
ensure_secret PG_PASSWORD 16
ensure_secret INVIDIOUS_DB_PASSWORD 16
ensure_secret INVIDIOUS_HMAC_KEY 32
ensure_secret COMPANION_KEY 8
ensure_secret POKE_SUB_SECRET 32
PG_PASSWORD=$(secret PG_PASSWORD)
INVIDIOUS_DB_PASSWORD=$(secret INVIDIOUS_DB_PASSWORD)
INVIDIOUS_HMAC_KEY=$(secret INVIDIOUS_HMAC_KEY)
COMPANION_KEY=$(secret COMPANION_KEY)
POKE_SUB_SECRET=$(secret POKE_SUB_SECRET)

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'invidious-db' "$HOSTS"; then
  echo "127.0.0.1 invidious invidious-db companion poke" >> "$HOSTS"
fi

# uid:gid of a user inside a chroot filesystem (empty if not found)
ids_of() { awk -F: -v u="$2" '$1==u {print $3":"$4; exit}' "$ROOTFS/$1/etc/passwd" 2>/dev/null || true; }

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

  # APP-SPECIFIC: Poke keeps accounts and subscriptions in json.sqlite in its
  # working folder (/poketube). Keep that one file in /data/poke.
  if [ "$(basename "$d")" = poke ]; then
    touch "$DATA/poke/json.sqlite"
    mkdir -p "$d/poketube"
    [ -e "$d/poketube/json.sqlite" ] || : > "$d/poketube/json.sqlite"
    mountpoint -q "$d/poketube/json.sqlite" || mount --bind "$DATA/poke/json.sqlite" "$d/poketube/json.sqlite" \
      || log "warning: could not bind $DATA/poke/json.sqlite into $d/poketube/json.sqlite"
    uid=$(ids_of poke node)
    [ -n "$uid" ] && chown -R "$uid" "$DATA/poke"
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
# Poke follows the browser's address, so the gateway only listens on 8080.
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@//g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- config files, rewritten on every start so setting changes apply ----
# Invidious: its config.yml in its working folder. Only Poke and the
# gateway talk to it, on 127.0.0.1; its own web pages are not published.
inv_conf=$ROOTFS/invidious/invidious/config/config.yml
mkdir -p "$(dirname "$inv_conf")"
cat > "$inv_conf" <<EOF
db:
  dbname: invidious
  user: kemal
  password: "$INVIDIOUS_DB_PASSWORD"
  host: 127.0.0.1
  port: 5432
check_tables: true
host_binding: 127.0.0.1
port: 3000
https_only: false
registration_enabled: false
login_enabled: false
channel_threads: 1
feed_threads: 1
invidious_companion:
  - private_url: "http://127.0.0.1:8282/companion"
invidious_companion_key: "$COMPANION_KEY"
hmac_key: "$INVIDIOUS_HMAC_KEY"
EOF
inv_ids=$(ids_of invidious invidious)
if [ -n "$inv_ids" ]; then
  chown "0:${inv_ids#*:}" "$inv_conf"
  chmod 640 "$inv_conf"
fi

# Poke: config.json in its working folder, from upstream's config.json.example
# with the API and video addresses pointed inside this container.
# media_proxy, p_url and the dislike counts still use Poke's public services.
# The watch page's usage ping (t_url) goes to the gateway, which drops it.
case ${POKE_ALWAYS_HTTPS:-false} in
  true|1|yes|on) ALWAYS_HTTPS=true ;;
  *) ALWAYS_HTTPS=false ;;
esac
poke_conf=$ROOTFS/poke/poketube/config.json
mkdir -p "$(dirname "$poke_conf")"
jq -n \
  --arg invapi "http://127.0.0.1:3000/api/v1" \
  --arg videourl "$GATEWAY_URL" \
  --arg media_proxy "${POKE_MEDIA_PROXY:-https://image-proxy.poketube.fun}" \
  --arg banner "${POKE_BANNER:-welcome to poke!}" \
  --arg subSecret "$POKE_SUB_SECRET" \
  --argjson https "$ALWAYS_HTTPS" \
  '{
    tubeApi: "https://inner-api.poketube.fun/api/",
    invapi: $invapi,
    dislikes: "https://returnyoutubedislikeapi.com/votes?videoId=",
    invchannel: $invapi,
    p_url: "https://p.poketube.fun",
    useragent: "PokeTube/2.0.0 (GNU/Linux; Android 14; Trisquel 11; poketube-vidious; like FreeTube)",
    media_proxy: $media_proxy,
    videourl: $videourl,
    email_main_url: "https://email-server.poketube.fun",
    mastodon_client_url: "https://social.poketube.fun",
    subSecret: $subSecret,
    mastodon_client_server_name: "PokeSocial",
    libreoffice_online_url: "https://office.poketube.fun",
    cacher_max_age: "86400",
    enablealwayshttps: $https,
    proxylocation: "USA",
    banner: $banner,
    t_url: "/aio-usage-ping/",
    server_port: "6003"
  }' > "$poke_conf"
poke_ids=$(ids_of poke node)
if [ -n "$poke_ids" ]; then
  chown "0:${poke_ids#*:}" "$poke_conf"
  chmod 640 "$poke_conf"
fi

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

write_env invidious "$TZV"

# The companion image listens on 0.0.0.0; keep it on 127.0.0.1 behind the gateway.
write_env companion "$TZV" \
  "HOST=127.0.0.1" \
  "PORT=8282" \
  "SERVER_BASE_PATH=/companion" \
  "SERVER_SECRET_KEY=$COMPANION_KEY" \
  "CONFIG_FILE=/app/config/config.toml"
if [ -n "${POKE_YOUTUBE_PROXY:-}" ]; then
  echo "PROXY=$POKE_YOUTUBE_PROXY" >> "$RUN/companion.env"
fi

write_env poke "$TZV"

# ---- settings: the README variables: list (Apps/poke/) ----
# Blank ones are skipped, so they mean "default".
pass_env poke 'POKE_WORKERS|POKE_CLUSTER'
pass_env companion 'YOUTUBE_SESSION_COOKIES|CAPTIONS_ENABLED'

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

  # Invidious makes its own tables (check_tables: true).
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE kemal LOGIN PASSWORD '${INVIDIOUS_DB_PASSWORD}';" \
    -c "CREATE DATABASE invidious OWNER kemal;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
