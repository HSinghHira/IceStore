#!/bin/bash
# First thing that runs in the container. Makes secrets, writes Revolt.toml,
# livekit.yml and each service's environment, fills in the web app's
# addresses, then hands over to supervisord.
set -euo pipefail

DATA=${AIO_DATA:-/data}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}
HOSTS=${AIO_HOSTS:-/etc/hosts}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/aio.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/aio.conf}
WEB_SRC=${AIO_WEB_SRC:-/opt/stoat-web}
WEB_OUT=${AIO_WEB_OUT:-/run/stoat-web}
GATEWAY_PORT=8080
# LiveKit's media ports: the same number inside and outside the container,
# because LiveKit tells browsers which port to send audio and video to.
LIVEKIT_TCP_PORT=6168
LIVEKIT_UDP_PORT=6169

log() { echo "[init] $*"; }

# ---- public address: every link and websocket the web app uses ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6167}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  https://*) WS_URL=wss://${PUBLIC_URL#https://} ;;
  *)         WS_URL=ws://${PUBLIC_URL#http://} ;;
esac
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
host=${hostport%:*}
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL, so Stoat only works on this server;"
    log "set PUBLIC_URL to the address you open Stoat at, like http://192.168.1.20:6167" ;;
esac
case $PUBLIC_URL in
  https://*) ;;
  *) log "browsers only allow the microphone and camera over HTTPS (or on localhost); put Stoat behind HTTPS for voice and video" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/mongodb" "$DATA/rabbit" "$DATA/redis" "$DATA/silo"
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

# RABBIT_PASSWORD, S3_*: logins between Stoat's own services.
# FILES_ENCRYPTION_KEY encrypts every uploaded file: lose it and the files
# can't be read. LIVEKIT_*: the key LiveKit and the API share. VAPID_*: the
# key pair for browser push notifications. Made the way upstream's
# generate_config.sh makes them.
ensure_secret RABBIT_PASSWORD 16
ensure_secret S3_KEY 10
ensure_secret S3_SECRET 24
ensure_secret LIVEKIT_KEY 6
ensure_secret LIVEKIT_SECRET 24
if ! grep -q '^FILES_ENCRYPTION_KEY=' "$SECRETS"; then
  echo "FILES_ENCRYPTION_KEY=$(openssl rand -base64 32)" >> "$SECRETS"
fi
if ! grep -q '^VAPID_PRIVATE_KEY=' "$SECRETS"; then
  pem=$(mktemp)
  openssl ecparam -name prime256v1 -genkey -noout -out "$pem" 2>/dev/null
  {
    echo "VAPID_PRIVATE_KEY=$(base64 -w0 < "$pem" | tr -d '=')"
    echo "VAPID_PUBLIC_KEY=$(openssl ec -in "$pem" -outform DER 2>/dev/null | tail -c 65 | base64 -w0 | tr '/+' '_-' | tr -d '=')"
  } >> "$SECRETS"
  rm -f "$pem"
fi
S3_KEY=$(secret S3_KEY)
S3_SECRET=$(secret S3_SECRET)
RABBIT_PASSWORD=$(secret RABBIT_PASSWORD)
LIVEKIT_KEY=$(secret LIVEKIT_KEY)
LIVEKIT_SECRET=$(secret LIVEKIT_SECRET)
S3_REGION=minio
S3_BUCKET=revolt-uploads

# ---- hostnames from upstream's compose, all pointed at 127.0.0.1 ----
if ! grep -q 'voice-ingress' "$HOSTS"; then
  echo "127.0.0.1 database redis rabbit minio revolt-uploads.minio api events autumn january gifbox livekit voice-ingress web" >> "$HOSTS"
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

  # APP-SPECIFIC: MongoDB keeps its data in /data/db and RabbitMQ in
  # /var/lib/rabbitmq (upstream's volumes); both images' entrypoints give the
  # folder to their own user.
  case $(basename "$d") in
    mongo)  sub=data/db           src=$DATA/mongodb ;;
    rabbit) sub=var/lib/rabbitmq  src=$DATA/rabbit ;;
    *)      sub="" src="" ;;
  esac
  if [ -n "$sub" ]; then
    mkdir -p "$d/$sub"
    if ! mountpoint -q "$d/$sub"; then
      mount --bind "$src" "$d/$sub" 2>/dev/null \
        || log "WARNING: could not bind $src to $d/$sub; its data would be lost on update"
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

# ---- Revolt.toml: upstream's generate_config.sh output, for one address ----
# Every Stoat service reads /Revolt.toml. Secrets come from the environment
# (REVOLT__SECTION__KEY, as in upstream's secrets.env), so your own
# REVOLT__... settings from the app settings win over this file.
STOAT_SERVICES="api events autumn january gifbox crond pushd voice"
revolt_toml() {
  cat <<EOF
# Written by IceStore's aio-init on every start; your changes here are lost.
# Change settings with REVOLT__SECTION__KEY variables in the app settings.
[database]
mongodb = "mongodb://127.0.0.1:27017"
redis = "redis://127.0.0.1:6379/"

[hosts]
app = "$PUBLIC_URL"
api = "$PUBLIC_URL/api"
events = "$WS_URL/ws"
autumn = "$PUBLIC_URL/autumn"
january = "$PUBLIC_URL/january"
gifbox = "$PUBLIC_URL/gifbox"

[hosts.livekit]
worldwide = "$WS_URL/livekit"

[rabbit]
host = "127.0.0.1"
port = 5672
username = "stoat"
password = "$RABBIT_PASSWORD"

[api.security.captcha]
# hCaptcha's public test keys, which always pass. Without a captcha key set,
# sign-up failed with CaptchaFailed. Set your own with
# REVOLT__API__SECURITY__CAPTCHA__HCAPTCHA_KEY and ..._SITEKEY.
hcaptcha_key = "0x0000000000000000000000000000000000000000"
hcaptcha_sitekey = "10000000-ffff-ffff-ffff-000000000001"

[api.livekit.nodes.worldwide]
url = "http://127.0.0.1:7880"
lat = 0.0
lon = 0.0

[files.s3]
endpoint = "http://127.0.0.1:9000"
path_style_buckets = true
region = "$S3_REGION"
access_key_id = "$S3_KEY"
secret_access_key = "$S3_SECRET"
default_bucket = "$S3_BUCKET"
EOF
}
for s in $STOAT_SERVICES; do
  [ -d "$ROOTFS/$s" ] || continue
  revolt_toml > "$ROOTFS/$s/Revolt.toml"
  chmod 644 "$ROOTFS/$s/Revolt.toml"
done

# ---- livekit.yml ----
# LiveKit tells each browser an IP and port to send audio and video to. With
# an IP address in PUBLIC_URL that IP is used; with a domain LiveKit finds
# your public IP itself (upstream's use_external_ip). STOAT_VOICE_IP sets it
# by hand.
VOICE_IP=${STOAT_VOICE_IP:-}
if [ -z "$VOICE_IP" ] && [[ $host =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ "$host" != 127.0.0.1 ]; then
  VOICE_IP=$host
fi
if [ -n "$VOICE_IP" ]; then
  RTC_IP="  use_external_ip: false
  node_ip: $VOICE_IP"
else
  RTC_IP="  use_external_ip: true"
fi
if [ -d "$ROOTFS/livekit" ]; then
  mkdir -p "$ROOTFS/livekit/etc"
  cat > "$ROOTFS/livekit/etc/livekit.yml" <<EOF
port: 7880
rtc:
  tcp_port: $LIVEKIT_TCP_PORT
  udp_port: $LIVEKIT_UDP_PORT
$RTC_IP
redis:
  address: 127.0.0.1:6379
turn:
  enabled: false
keys:
  $LIVEKIT_KEY: $LIVEKIT_SECRET
webhook:
  api_key: $LIVEKIT_KEY
  urls:
    - "http://127.0.0.1:8500/worldwide"
EOF
  chmod 600 "$ROOTFS/livekit/etc/livekit.yml"
fi
log "voice and video: ${VOICE_IP:-your public IP} on port $LIVEKIT_TCP_PORT/tcp and $LIVEKIT_UDP_PORT/udp"

# ---- web app: fill in the addresses (upstream's inject.js) ----
# The files are built with placeholders: __VITE_ plus the setting's name
# (API_URL, HOST, ...) plus two underscores. A blank value becomes
# undefined, as inject.js does.
P=__VITE_
inject() {
  local file
  while IFS= read -r -d '' file; do
    grep -q "$P" "$file" || continue
    sed -i \
      -e "s|${P}HOST__|$hostport|g" \
      -e "s|${P}API_URL__|$PUBLIC_URL/api|g" \
      -e "s|${P}GIFBOX_URL__|$PUBLIC_URL/gifbox|g" \
      -e "s|\"${P}[A-Z_]*__\"|void 0|g" \
      "$file"
  done < <(find "$WEB_OUT" -type f \( -name '*.js' -o -name '*.html' \) -print0)
}
if [ -d "$WEB_SRC" ]; then
  rm -rf "$WEB_OUT"
  mkdir -p "$WEB_OUT"
  cp -a "$WEB_SRC/." "$WEB_OUT/"
  inject
  chmod -R a+rX "$WEB_OUT"
else
  log "warning: no web app files in $WEB_SRC"
fi

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 4369 5672 6168 6169 6379 7880 8080 8500 9000 9001 14702 14703 14704 14705 14706 15692 25672 27017 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
# The addresses have slashes in them, so they are escaped for sed.
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@API_URL@/$(sed_escape "$PUBLIC_URL/api")/g" -e "s/@WEB_ROOT@/$(sed_escape "$WEB_OUT")/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

write_env silo "$TZV" \
  "MINIO_ROOT_USER=$S3_KEY" \
  "MINIO_ROOT_PASSWORD=$S3_SECRET"
write_env s3init "S3_KEY=$S3_KEY" "S3_SECRET=$S3_SECRET" "S3_REGION=$S3_REGION" "S3_BUCKET=$S3_BUCKET"

write_env mongo "$TZV"
write_env rabbit "$TZV" \
  "RABBITMQ_DEFAULT_USER=stoat" \
  "RABBITMQ_DEFAULT_PASS=$RABBIT_PASSWORD" \
  "RABBITMQ_NODENAME=rabbit@localhost"
write_env livekit "$TZV"

# Upstream's secrets.env, plus the logs each service writes. All the Stoat
# services get the same environment.
STOAT_ENV=("$TZV"   "RUST_LOG=${RUST_LOG:-info}"   "REVOLT__PUSHD__VAPID__PRIVATE_KEY=$(secret VAPID_PRIVATE_KEY)"   "REVOLT__PUSHD__VAPID__PUBLIC_KEY=$(secret VAPID_PUBLIC_KEY)"   "REVOLT__FILES__ENCRYPTION_KEY=$(secret FILES_ENCRYPTION_KEY)"   "REVOLT__API__LIVEKIT__NODES__WORLDWIDE__KEY=$LIVEKIT_KEY"   "REVOLT__API__LIVEKIT__NODES__WORLDWIDE__SECRET=$LIVEKIT_SECRET")
write_env api     "${STOAT_ENV[@]}"
write_env events  "${STOAT_ENV[@]}"
write_env autumn  "${STOAT_ENV[@]}"
write_env january "${STOAT_ENV[@]}"
write_env gifbox  "${STOAT_ENV[@]}"
write_env crond   "${STOAT_ENV[@]}"
write_env pushd   "${STOAT_ENV[@]}"
write_env voice   "${STOAT_ENV[@]}"

# ---- settings: the README variables: list (Apps/stoatchat/) ----
# Any Revolt.toml setting as REVOLT__SECTION__KEY, read by every Stoat
# service on start; blank ones are skipped, so they mean "default".
pass_env api     'REVOLT__[A-Z0-9_]+'
pass_env events  'REVOLT__[A-Z0-9_]+'
pass_env autumn  'REVOLT__[A-Z0-9_]+'
pass_env january 'REVOLT__[A-Z0-9_]+'
pass_env gifbox  'REVOLT__[A-Z0-9_]+'
pass_env crond   'REVOLT__[A-Z0-9_]+'
pass_env pushd   'REVOLT__[A-Z0-9_]+'
pass_env voice   'REVOLT__[A-Z0-9_]+'

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

# ---- built-in data folders ----
chown redis:redis "$DATA/redis"

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
