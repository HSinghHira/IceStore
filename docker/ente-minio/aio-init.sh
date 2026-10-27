#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each service's
# environment and config, prepares the database, then hands over to supervisord.
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
# PUBLIC_URL is the Web App. Every other app has its own port on the same
# host, counted up from PUBLIC_URL's port (6630 by default):
#   +1 API            +2 Public Albums   +3 photo storage (S3)  +4 mail viewer
#   +5 Accounts       +6 Auth            +7 Cast                +8 Public Locker
#   +9 Embed          +10 Paste          +11 Locker             +12 Public Memories
# Counting from PUBLIC_URL keeps older installs (Web App, API, Albums, S3 on
# four ports in a row) working. Each address can be set to your own domain
# instead with the variables below (README variables: list).
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6630}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
proto=${PUBLIC_URL%%://*}
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
host=${hostport%:*}
BASE_PORT=6630
if [[ $hostport == *:* ]] && [[ ${hostport##*:} =~ ^[0-9]+$ ]]; then
  BASE_PORT=${hostport##*:}
fi
at() { echo "$proto://$host:$((BASE_PORT + $1))"; }
API_URL=${ENTE_API_URL:-$(at 1)}
# ENTE_ALBUMS_URL is the old name of ENTE_APPS_PUBLIC_ALBUMS; both work.
ALBUMS_URL=${ENTE_APPS_PUBLIC_ALBUMS:-${ENTE_ALBUMS_URL:-$(at 2)}}
S3_URL=${ENTE_S3_URL:-$(at 3)}
MAIL_URL=$(at 4)
ACCOUNTS_URL=${ENTE_APPS_ACCOUNTS:-$(at 5)}
AUTH_URL=$(at 6)
CAST_URL=${ENTE_APPS_CAST:-$(at 7)}
LOCKER_SHARE_URL=${ENTE_APPS_PUBLIC_LOCKER:-$(at 8)}
EMBED_URL=${ENTE_APPS_EMBED_ALBUMS:-$(at 9)}
PASTE_URL=${ENTE_APPS_PUBLIC_PASTE:-$(at 10)}
LOCKER_URL=$(at 11)
MEMORIES_URL=${ENTE_APPS_PUBLIC_MEMORIES:-$(at 12)}
for v in API_URL ALBUMS_URL S3_URL ACCOUNTS_URL CAST_URL LOCKER_SHARE_URL EMBED_URL PASTE_URL MEMORIES_URL; do
  val=${!v}
  val=${val%/}
  printf -v "$v" '%s' "$val"
  case $val in
    http://*|https://*) ;;
    *) log "every address must start with http:// or https:// (got $v: $val)"; exit 1 ;;
  esac
done
# Ente wants the S3 endpoint as host:port; "local" buckets are plain http.
S3_ENDPOINT=${S3_URL#*://}
S3_ENDPOINT=${S3_ENDPOINT%%/*}
case $S3_URL in https://*) S3_LOCAL=false ;; *) S3_LOCAL=true ;; esac
S3_REGION=eu-central-2
log "web app:          $PUBLIC_URL"
log "api (phone apps): $API_URL"
log "public albums:    $ALBUMS_URL"
log "photo storage:    $S3_URL"
log "mail viewer:      $MAIL_URL"
log "accounts:         $ACCOUNTS_URL"
log "auth:             $AUTH_URL"
log "cast:             $CAST_URL"
log "public locker:    $LOCKER_SHARE_URL"
log "embed:            $EMBED_URL"
log "paste:            $PASTE_URL"
log "locker:           $LOCKER_URL"
log "public memories:  $MEMORIES_URL"
if [ "$host" = localhost ]; then
  log "PUBLIC_URL uses localhost, so phones and other computers cannot reach Ente; set it to http://<your-zimaos-ip>:6630"
fi

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/silo"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
# ensure_secret NAME BYTES [PREFIX]: random hex. ensure_b64 NAME BYTES: base64.
ensure_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=${3:-}$(openssl rand -hex "$2")" >> "$SECRETS"
  fi
  return 0
}
ensure_b64() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -base64 "$2" | tr -d '\n')" >> "$SECRETS"
  fi
  return 0
}
secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# PG_PASSWORD: postgres superuser. ENTE_DB_PASSWORD: the "pguser" role museum uses.
# KEY_ENCRYPTION / KEY_HASH / JWT_SECRET: museum's own keys, made the same way
# as upstream's quickstart.sh. They must never change: a new KEY_ENCRYPTION
# makes stored data unreadable and a new KEY_HASH locks every account out.
# S3_KEY / S3_SECRET: Ente's key for Silo. MAIL_PASSWORD: the mail viewer.
ensure_secret PG_PASSWORD 16
ensure_secret ENTE_DB_PASSWORD 16
ensure_b64 KEY_ENCRYPTION 32
ensure_b64 KEY_HASH 64
ensure_b64 JWT_SECRET 32
ensure_secret S3_KEY 10
ensure_secret S3_SECRET 20
ensure_secret MAIL_PASSWORD 8
PG_PASSWORD=$(secret PG_PASSWORD)
ENTE_DB_PASSWORD=$(secret ENTE_DB_PASSWORD)
S3_KEY=$(secret S3_KEY)
S3_SECRET=$(secret S3_SECRET)
JWT_SECRET=$(secret JWT_SECRET | tr '+/' '-_')

# Mail viewer (/mail/) login. Sign-up codes land there, so it is never open.
# MP_UI_AUTH ("user:password") wins; blank = admin with the password made above.
MAIL_UI_AUTH=${MP_UI_AUTH:-admin:$(secret MAIL_PASSWORD)}
if [ -z "${MP_UI_AUTH:-}" ]; then
  log "mail viewer login: user admin, password $(secret MAIL_PASSWORD) (open $MAIL_URL, or $PUBLIC_URL/mail/)"
else
  log "the mail viewer login is the one you set in MP_UI_AUTH"
fi

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' museum ' "$HOSTS"; then
  echo "127.0.0.1 postgres museum web mailpit minio silo " >> "$HOSTS"
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

# ---- gateway ----
# 8080 photos (+ the PUBLIC_URL port), 8081 API, 8082 albums, 8083 S3 (+ the
# S3 address's port), 8104 mail viewer, 8105-8112 the other web apps.
# museum calls the S3 address from inside the container, so with the
# default localhost address that port must answer in here too.
INTERNAL_PORTS=" 1025 2112 3000 3001 3002 3003 3004 3005 3006 3008 3009 3010 5432 8025 8080 8081 8082 8083 8090 3200 3201 8104 8105 8106 8107 8108 8109 8110 8111 8112 "
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
S3_PORT_PUBLIC=$(port_of "$S3_URL")
EXTRA_LISTEN=$(extra_listen "$WEB_PORT")
S3_EXTRA_LISTEN=""
[ "$S3_PORT_PUBLIC" = "$WEB_PORT" ] || S3_EXTRA_LISTEN=$(extra_listen "$S3_PORT_PUBLIC")
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@S3_EXTRA_LISTEN@/$S3_EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# Silo (MinIO): one root user, who is also Ente's S3 key.
write_env silo "$TZV" \
  "MINIO_ROOT_USER=$S3_KEY" \
  "MINIO_ROOT_PASSWORD=$S3_SECRET" \
  "MINIO_SITE_REGION=$S3_REGION" \
  "MINIO_BROWSER=off"

write_env s3init "S3_KEY=$S3_KEY" "S3_SECRET=$S3_SECRET" "S3_REGION=$S3_REGION" "S3_PORT=3200"

write_env mailpit "$TZV" \
  "MP_SMTP_BIND_ADDR=127.0.0.1:1025" \
  "MP_UI_BIND_ADDR=127.0.0.1:8025" \
  "MP_WEBROOT=/mail/" \
  "MP_UI_AUTH=$MAIL_UI_AUTH" \
  "MP_SMTP_AUTH_ACCEPT_ANY=1" \
  "MP_SMTP_AUTH_ALLOW_INSECURE=1"

# The web image writes ENTE_API_ORIGIN into its JavaScript when it starts.
write_env web "$TZV" "ENTE_API_ORIGIN=$API_URL"

# ---- museum: /museum.yaml in its filesystem, rewritten on every start ----
# Same layout as upstream's quickstart.sh. Email goes to the built-in mail
# viewer unless ENTE_SMTP_HOST is set; then the port defaults to 587, or to
# implicit TLS ("ssl") on 465. Blank values always mean "use the default".
yq() { local s=${1//\\/\\\\}; s=${s//\"/\\\"}; printf '"%s"' "$s"; }
if [ -n "${ENTE_SMTP_HOST:-}" ]; then
  SMTP_HOST=$ENTE_SMTP_HOST
  SMTP_PORT=${ENTE_SMTP_PORT:-587}
  if [ "$SMTP_PORT" = 465 ]; then SMTP_ENC=${ENTE_SMTP_ENCRYPTION:-ssl}; else SMTP_ENC=${ENTE_SMTP_ENCRYPTION:-}; fi
  SMTP_USER=${ENTE_SMTP_USERNAME:-}
  SMTP_PASS=${ENTE_SMTP_PASSWORD:-}
  SMTP_EMAIL=${ENTE_SMTP_EMAIL:-${ENTE_SMTP_USERNAME:-noreply@ente.local}}
else
  SMTP_HOST=127.0.0.1
  SMTP_PORT=1025
  SMTP_ENC=""
  SMTP_USER=""
  SMTP_PASS=""
  SMTP_EMAIL=${ENTE_SMTP_EMAIL:-noreply@ente.local}
fi
SMTP_NAME=${ENTE_SMTP_SENDER_NAME:-Ente}

# Passkeys are tied to the Accounts app address. Browsers only allow them on
# https (or localhost) with a real host name, not an IP address.
acc_host=${ACCOUNTS_URL#*://}
acc_host=${acc_host%%/*}
acc_host=${acc_host%:*}
WEBAUTHN_RPID=${ENTE_WEBAUTHN_RPID:-$acc_host}

bucket() {
  cat <<EOF
    $1:
        key: $(yq "$S3_KEY")
        secret: $(yq "$S3_SECRET")
        endpoint: $(yq "$S3_ENDPOINT")
        region: $(yq "$S3_REGION")
        bucket: $1
EOF
}
mkdir -p "$ROOTFS/museum"
{
  cat <<EOF
http:
    port: 8090
db:
    host: 127.0.0.1
    port: 5432
    name: ente_db
    user: pguser
    password: $(yq "$ENTE_DB_PASSWORD")
    sslmode: disable
s3:
    are_local_buckets: $S3_LOCAL
    use_path_style_urls: true
EOF
  bucket b2-eu-cen
  bucket wasabi-eu-central-2-v3
  echo "        compliance: false"
  bucket scw-eu-fr-v3
  cat <<EOF
apps:
    public-albums: $(yq "$ALBUMS_URL")
    embed-albums: $(yq "$EMBED_URL")
    public-locker: $(yq "$LOCKER_SHARE_URL")
    public-paste: $(yq "$PASTE_URL")
    public-memories: $(yq "$MEMORIES_URL")
    accounts: $(yq "$ACCOUNTS_URL")
    cast: $(yq "$CAST_URL")
webauthn:
    rpid: $(yq "$WEBAUTHN_RPID")
    rporigins:
        - $(yq "$ACCOUNTS_URL")
key:
    encryption: $(yq "$(secret KEY_ENCRYPTION)")
    hash: $(yq "$(secret KEY_HASH)")
jwt:
    secret: $(yq "$JWT_SECRET")
smtp:
    host: $(yq "$SMTP_HOST")
    port: $(yq "$SMTP_PORT")
    username: $(yq "$SMTP_USER")
    password: $(yq "$SMTP_PASS")
    email: $(yq "$SMTP_EMAIL")
    sender-name: $(yq "$SMTP_NAME")
    encryption: $(yq "$SMTP_ENC")
EOF
} > "$ROOTFS/museum/museum.yaml"
chmod 600 "$ROOTFS/museum/museum.yaml"

write_env museum "$TZV"
# ---- settings: the compose environment: plus the README variables: list (Apps/ente-minio/) ----
# museum reads ENTE_<SECTION>_<KEY> itself; blank ones are skipped, so they
# mean "default". The SMTP ones and the addresses are wired up above.
pass_env museum 'ENTE_INTERNAL_(DISABLE_REGISTRATION|ADMIN)'
# Apps that are not in the web image: point them at your own copy.
pass_env museum 'ENTE_APPS_(FAMILY|SPACE|LEGACY|ACCOUNTS_LEGACY)'

STORAGE_GB=${ENTE_AIO_STORAGE_GB:-102400}
[[ $STORAGE_GB =~ ^[0-9]+$ ]] || { log "ENTE_AIO_STORAGE_GB must be a whole number (got: $STORAGE_GB); using 102400"; STORAGE_GB=102400; }
write_env quota "STORAGE_BYTES=$((STORAGE_GB * 1073741824))"

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

pgbin=/usr/lib/postgresql/15/bin
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

if [ ! -s "$DATA/postgres/PG_VERSION" ]; then
  log "first start: creating the database"
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg $pgbin/initdb -D "$DATA/postgres" -U postgres -E UTF8 --locale=C.UTF-8 \
    --data-checksums --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" >/dev/null
  rm -f "$pwfile"

  # Upstream's "pguser" is the Postgres superuser (POSTGRES_USER=pguser).
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
  as_pg $pgbin/psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -q \
    -c "CREATE ROLE pguser LOGIN SUPERUSER PASSWORD '${ENTE_DB_PASSWORD}';" \
    -c "CREATE DATABASE ente_db OWNER pguser;"
  as_pg $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  log "first start: database ready"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
