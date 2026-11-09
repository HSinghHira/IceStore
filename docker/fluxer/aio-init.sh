#!/bin/bash
# First thing that runs in the container. Makes secrets, works out every
# Fluxer address from PUBLIC_URL, writes each service's environment and the
# NATS, LiveKit and SeaweedFS config files, then hands over to supervisord.
set -euo pipefail

DATA=${AIO_DATA:-/data}
ROOTFS=${AIO_ROOTFS:-/opt/rootfs}
META=${AIO_META:-/opt/meta}
RUN=${AIO_RUN:-/run/aio}
HOSTS=${AIO_HOSTS:-/etc/hosts}
NGINX_TPL=${AIO_NGINX_TPL:-/etc/nginx/aio.conf.tpl}
NGINX_OUT=${AIO_NGINX_OUT:-/etc/nginx/aio.conf}
STATIC_ROOT=${AIO_STATIC_ROOT:-/opt/fluxer-static}
GATEWAY_PORT=8080
# LiveKit's media ports: the same number inside and outside the container,
# because LiveKit tells browsers which port to send audio and video to.
LIVEKIT_TCP_PORT=6693
LIVEKIT_UDP_PORT=6694

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots, pg_*.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# ---- public address: every link, websocket and sign-in check uses it ----
# The compose file ships http://[ZIMAOS-IP-ADDRESS]:6692 so people see they
# must put their IP (or their https:// domain) there. Until they do, run on
# localhost so the services start, and show a "set PUBLIC_URL" note to every
# other address (below): Fluxer only accepts the one address it was given.
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6692}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "PUBLIC_URL is still $PUBLIC_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP (or use your https:// domain) in the app settings"
    PUBLIC_URL=${PUBLIC_URL//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
SCHEME=${PUBLIC_URL%%://*}
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
case $hostport in
  \[*\]:*) host=${hostport%:*}; PUBLIC_PORT=${hostport##*:} ;;
  \[*\])   host=$hostport; PUBLIC_PORT="" ;;
  *:*)     host=${hostport%:*}; PUBLIC_PORT=${hostport##*:} ;;
  *)       host=$hostport; PUBLIC_PORT="" ;;
esac
if [ -z "$PUBLIC_PORT" ]; then
  if [ "$SCHEME" = https ]; then PUBLIC_PORT=443; else PUBLIC_PORT=80; fi
fi
ORIGIN=$SCHEME://$hostport
if [ "$SCHEME" = https ]; then WS_ORIGIN=wss://$hostport; else WS_ORIGIN=ws://$hostport; fi
case $host in
  localhost|127.0.0.1)
    log "PUBLIC_URL uses localhost, so Fluxer only works on this server; set it to http://[ZIMAOS-IP-ADDRESS]:6692 with your IP" ;;
esac
if [ "$SCHEME" = http ]; then
  log "PUBLIC_URL is plain http: chat, uploads and the admin panel work, but browsers turn off the microphone, camera, screen sharing, passkeys and notifications"
  log "for those, put Fluxer behind HTTPS (a reverse proxy to port 6692) and set PUBLIC_URL to https://your.domain"
fi

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/valkey" "$DATA/nats" \
  "$DATA/meilisearch" "$DATA/seaweedfs"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
# The same list upstream's docker-compose docs make with openssl. The
# database, search and push keys must never change once Fluxer has data.
ensure_secret PG_PASSWORD 32
ensure_secret MEILI_MASTER_KEY 32
ensure_secret S3_SECRET 32
ensure_secret SUDO_MODE_SECRET 32
ensure_secret CONNECTION_INITIATION_SECRET 32
ensure_secret PROFILE_PSEUDONYM_SECRET 32
ensure_secret GATEWAY_RPC_AUTH_TOKEN 32
ensure_secret ERLANG_COOKIE 32
ensure_secret MEDIA_PROXY_SECRET_KEY 32
ensure_secret ADMIN_SECRET_KEY_BASE 32
ensure_secret ADMIN_OAUTH_CLIENT_SECRET 32
ensure_secret LIVEKIT_SECRET 32
ensure_secret SETUP_TOKEN 32
ensure_b64 UPLOAD_RELAY_SECRET 32
if ! grep -q '^ACTIVITYPUB_KEY=' "$SECRETS"; then
  echo "ACTIVITYPUB_KEY=$(openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform DER 2>/dev/null | base64 -w0)" >> "$SECRETS"
fi
# VAPID (browser push): unpadded base64url of the raw P-256 private key
# (32 bytes) and public point (65 bytes), as upstream asks for.
if ! grep -q '^VAPID_PRIVATE_KEY=' "$SECRETS"; then
  pem=$(mktemp)
  openssl ecparam -name prime256v1 -genkey -noout -out "$pem" 2>/dev/null
  b64url() { base64 -w0 | tr '/+' '_-' | tr -d '='; }
  {
    echo "VAPID_PRIVATE_KEY=$(openssl ec -in "$pem" -outform DER 2>/dev/null | dd bs=1 skip=7 count=32 2>/dev/null | b64url)"
    echo "VAPID_PUBLIC_KEY=$(openssl ec -in "$pem" -pubout -outform DER 2>/dev/null | tail -c 65 | b64url)"
  } >> "$SECRETS"
  rm -f "$pem"
fi
PG_PASSWORD=$(secret PG_PASSWORD)
S3_KEY=fluxer
S3_SECRET=$(secret S3_SECRET)
S3_REGION=us-east-1
LIVEKIT_KEY=fluxer
LIVEKIT_SECRET=$(secret LIVEKIT_SECRET)
# Your own FLUXER_SETUP_TOKEN from the app settings wins.
SETUP_TOKEN=${FLUXER_SETUP_TOKEN:-$(secret SETUP_TOKEN)}

# ---- hostnames from upstream's compose, all pointed at 127.0.0.1 ----
if ! grep -q 'meilisearch' "$HOSTS"; then
  echo "127.0.0.1 edge postgres valkey nats meilisearch seaweedfs livekit api worker gateway media-proxy push static-proxy app-proxy snowflakes users gifs messages unfurl admin" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 sub="" src=""
  # APP-SPECIFIC: the data folders of upstream's volumes. These images run
  # as root, so no chown is needed.
  case $(basename "$d") in
    nats)        sub=data         src=$DATA/nats ;;
    meilisearch) sub=meili_data   src=$DATA/meilisearch ;;
    seaweedfs)   sub=data         src=$DATA/seaweedfs ;;
  esac
  if [ -n "$sub" ]; then
    mkdir -p "$d/$sub"
    if ! mountpoint -q "$d/$sub"; then
      mount --bind "$src" "$d/$sub" 2>/dev/null \
        || log "WARNING: could not bind $src to $d/$sub; its data would be lost on update"
    fi
  fi
  return 0
}
prep_chroots

# ---- config files the chroot services read ----
# NATS: upstream's nats.conf, on 127.0.0.1.
if [ -d "$ROOTFS/nats" ]; then
  mkdir -p "$ROOTFS/nats/etc"
  cat > "$ROOTFS/nats/etc/nats-aio.conf" <<EOF
host: 127.0.0.1
port: 4222
http: 127.0.0.1:8222
jetstream {
  store_dir: /data
  max_memory_store: ${FLUXER_NATS_MAX_MEMORY_STORE:-64MB}
  max_file_store: ${FLUXER_NATS_MAX_FILE_STORE:-10GB}
}
EOF
fi

# SeaweedFS: the S3 login for Fluxer, rewritten on every start (the key and
# secret are plain text, so no JSON escaping is needed).
if [ -d "$ROOTFS/seaweedfs" ]; then
  mkdir -p "$ROOTFS/seaweedfs/etc/seaweedfs"
  cat > "$ROOTFS/seaweedfs/etc/seaweedfs/s3.json" <<EOF
{
  "identities": [
    {
      "name": "fluxer",
      "credentials": [{"accessKey": "$S3_KEY", "secretKey": "$S3_SECRET"}],
      "actions": ["Admin", "Read", "Write", "List", "Tagging"]
    }
  ]
}
EOF
  chmod 600 "$ROOTFS/seaweedfs/etc/seaweedfs/s3.json"
fi

# LiveKit: upstream's LIVEKIT_CONFIG. It tells each browser an IP and port to
# send audio and video to. With an IP address in PUBLIC_URL that IP is used;
# with a domain LiveKit finds your public IP itself through STUN.
# FLUXER_LIVEKIT_NODE_IP sets it by hand.
VOICE_IP=${FLUXER_LIVEKIT_NODE_IP:-}
if [ -z "$VOICE_IP" ] && [[ $host =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ "$host" != 127.0.0.1 ]; then
  VOICE_IP=$host
fi
if [ -n "$VOICE_IP" ]; then
  RTC_IP="  use_external_ip: false
  node_ip: \"$VOICE_IP\""
else
  RTC_IP="  use_external_ip: ${FLUXER_LIVEKIT_USE_EXTERNAL_IP:-true}"
fi
TURN_SERVERS=${FLUXER_LIVEKIT_TURN_SERVERS:-[]}
if [ -d "$ROOTFS/livekit" ]; then
  mkdir -p "$ROOTFS/livekit/etc"
  cat > "$ROOTFS/livekit/etc/livekit.yml" <<EOF
port: 7880
bind_addresses:
  - 127.0.0.1
log_level: ${FLUXER_LIVEKIT_LOG_LEVEL:-info}
rtc:
  tcp_port: $LIVEKIT_TCP_PORT
  udp_port: $LIVEKIT_UDP_PORT
$RTC_IP
  stun_servers:
    - ${FLUXER_LIVEKIT_STUN_PRIMARY:-stun.l.google.com:19302}
    - ${FLUXER_LIVEKIT_STUN_SECONDARY:-stun1.l.google.com:19302}
  turn_servers: $TURN_SERVERS
keys:
  $LIVEKIT_KEY: $LIVEKIT_SECRET
webhook:
  api_key: $LIVEKIT_KEY
  urls:
    - http://127.0.0.1:8100/webhooks/livekit
EOF
  chmod 644 "$ROOTFS/livekit/etc/livekit.yml"
fi
log "voice and video: ${VOICE_IP:-your public IP} on port $LIVEKIT_TCP_PORT/tcp and $LIVEKIT_UDP_PORT/udp"

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
EXTRA_LISTEN=""
INTERNAL_PORTS=" 4222 4369 5432 6379 6693 6694 7700 7880 8080 8081 8085 8100 8101 8102 8103 8104 8110 8111 8112 8113 8114 8126 8222 8333 8888 9333 18085 18333 18888 19333 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ] \
    && [ "$PUBLIC_PORT" != 80 ] && [ "$PUBLIC_PORT" != 443 ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

# host is localhost: anyone on another address gets a note, not a broken page
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Fluxer is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, and Fluxer only accepts the address it was given.\n\nOpen the Fluxer app settings in ZimaOS, set PUBLIC_URL to http://$host:6692 (or to your https:// domain) and save. After the app restarts, open that address again.\n";
}
EOF
    ;;
  *) : > "$GUARD_FILE" ;;
esac
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@GUARD_FILE@/$(sed_escape "$GUARD_FILE")/g" \
    -e "s/@STATIC_ROOT@/$(sed_escape "$STATIC_ROOT")/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
rm -f "$RUN/s3-ready"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

write_env postgres "PG_SHARED_BUFFERS=${FLUXER_POSTGRES_SHARED_BUFFERS:-256MB}"
write_env s3init "S3_KEY=$S3_KEY" "S3_SECRET=$S3_SECRET" "S3_REGION=$S3_REGION" \
  "S3_BUCKETS=fluxer fluxer-uploads fluxer-reports fluxer-harvests" \
  "UPLOADS_TTL=${FLUXER_SEAWEEDFS_UPLOADS_TTL:-1d}"
write_env nats "$TZV" "GOMEMLIMIT=200MiB"
write_env meilisearch "$TZV" \
  "MEILI_HTTP_ADDR=127.0.0.1:7700" \
  "MEILI_ENV=production" \
  "MEILI_NO_ANALYTICS=true" \
  "MEILI_UPGRADE_DB=true" \
  "MEILI_MAX_INDEXING_MEMORY=256mb" \
  "MEILI_MAX_INDEXING_THREADS=2" \
  "MEILI_LOG_LEVEL=WARN" \
  "MEILI_MASTER_KEY=$(secret MEILI_MASTER_KEY)"
write_env seaweedfs "$TZV" "GOMEMLIMIT=1024MiB" "WEED_MASTER_VOLUME_GROWTH_COPY_1=1"
write_env livekit "$TZV" "GOMEMLIMIT=435MiB"

# Upstream's x-fluxer-env block, which every Fluxer service gets: one
# address set built from PUBLIC_URL, every internal address on 127.0.0.1
# and the shared secrets.
FLUXER_ENV=(
  "$TZV"
  "FLUXER_ENV=production"
  "FLUXER_SELF_HOSTED=true"
  "LOG_LEVEL=${LOG_LEVEL:-info}"
  "RUST_LOG=${RUST_LOG:-info}"
  "NO_PROXY=localhost,127.0.0.1,::1,edge,postgres,valkey,nats,meilisearch,seaweedfs,livekit,api,worker,gateway,media-proxy,push,static-proxy,app-proxy,snowflakes,users,gifs,messages,unfurl,admin"
  "no_proxy=localhost,127.0.0.1,::1,edge,postgres,valkey,nats,meilisearch,seaweedfs,livekit,api,worker,gateway,media-proxy,push,static-proxy,app-proxy,snowflakes,users,gifs,messages,unfurl,admin"
  "FLUXER_DATABASE_BACKEND=postgres"
  "FLUXER_POSTGRES_HOST=127.0.0.1"
  "FLUXER_POSTGRES_PORT=5432"
  "FLUXER_POSTGRES_DATABASE=fluxer"
  "FLUXER_POSTGRES_USERNAME=fluxer"
  "FLUXER_POSTGRES_PASSWORD=$PG_PASSWORD"
  "FLUXER_BASE_DOMAIN=$host"
  "FLUXER_PUBLIC_SCHEME=$SCHEME"
  "FLUXER_PUBLIC_PORT=$PUBLIC_PORT"
  "FLUXER_PUBLIC_ORIGIN=$ORIGIN"
  "FLUXER_TRUST_CLIENT_IP_HEADER=true"
  "FLUXER_APP_ENDPOINT=$ORIGIN"
  "FLUXER_API_ENDPOINT=$ORIGIN/api"
  "FLUXER_API_CLIENT_ENDPOINT=$ORIGIN/api"
  "FLUXER_GATEWAY_ENDPOINT=$WS_ORIGIN/gateway"
  "FLUXER_MEDIA_ENDPOINT=$ORIGIN/media"
  "FLUXER_MEDIA_PROXY_PUBLIC_ENDPOINT=$ORIGIN/media"
  "FLUXER_STATIC_CDN_ENDPOINT=$ORIGIN"
  "FLUXER_ADMIN_ENDPOINT=$ORIGIN/admin"
  "FLUXER_MARKETING_ENDPOINT=$ORIGIN"
  "FLUXER_KV_URL=redis://127.0.0.1:6379/0"
  "FLUXER_NATS_URL=nats://127.0.0.1:4222"
  "FLUXER_NATS_JETSTREAM_URL=nats://127.0.0.1:4222"
  "FLUXER_SVC_NATS_URL=nats://127.0.0.1:4222"
  "FLUXER_SVC_SHARD_COUNT=1"
  "FLUXER_SEARCH_ENGINE=meilisearch"
  "FLUXER_SEARCH_URL=http://127.0.0.1:7700"
  "FLUXER_SEARCH_API_KEY=$(secret MEILI_MASTER_KEY)"
  "FLUXER_S3_ENDPOINT=http://127.0.0.1:8333"
  "FLUXER_S3_PUBLIC_ENDPOINT=http://127.0.0.1:8333"
  "FLUXER_S3_REGION=$S3_REGION"
  "FLUXER_S3_ACCESS_KEY_ID=$S3_KEY"
  "FLUXER_S3_SECRET_ACCESS_KEY=$S3_SECRET"
  "FLUXER_S3_FORCE_PATH_STYLE=true"
  "FLUXER_S3_BUCKET_CDN=fluxer"
  "FLUXER_S3_BUCKET_UPLOADS=fluxer-uploads"
  "FLUXER_S3_BUCKET_REPORTS=fluxer-reports"
  "FLUXER_S3_BUCKET_HARVESTS=fluxer-harvests"
  "FLUXER_API_PRESIGNED_HARVEST_DOWNLOADS_ENABLED=false"
  "FLUXER_LIVEKIT_ENABLED=true"
  "FLUXER_LIVEKIT_API_KEY=$LIVEKIT_KEY"
  "FLUXER_LIVEKIT_API_SECRET=$LIVEKIT_SECRET"
  "FLUXER_LIVEKIT_INTERNAL_URL=http://127.0.0.1:7880"
  "FLUXER_LIVEKIT_BUNDLED=true"
  'FLUXER_LIVEKIT_DEFAULT_REGION={"id":"default","name":"Default","emoji":"🌍","latitude":0,"longitude":0}'
  "FLUXER_LIVEKIT_URL=$ORIGIN/livekit"
  "FLUXER_LIVEKIT_TURN_SERVERS=$TURN_SERVERS"
  "FLUXER_EMAIL_FROM_EMAIL=noreply@$host"
  "FLUXER_SUDO_MODE_SECRET=$(secret SUDO_MODE_SECRET)"
  "FLUXER_CONNECTION_INITIATION_SECRET=$(secret CONNECTION_INITIATION_SECRET)"
  "FLUXER_PROFILE_PSEUDONYM_SECRET=$(secret PROFILE_PSEUDONYM_SECRET)"
  "FLUXER_VAPID_PUBLIC_KEY=$(secret VAPID_PUBLIC_KEY)"
  "FLUXER_VAPID_PRIVATE_KEY=$(secret VAPID_PRIVATE_KEY)"
  "FLUXER_VAPID_EMAIL=admin@$host"
  "FLUXER_PASSKEY_RP_ID=$host"
  "FLUXER_PASSKEY_ADDITIONAL_ALLOWED_ORIGINS=$ORIGIN"
  "FLUXER_GATEWAY_RPC_AUTH_TOKEN=$(secret GATEWAY_RPC_AUTH_TOKEN)"
  "FLUXER_MEDIA_PROXY_SECRET_KEY=$(secret MEDIA_PROXY_SECRET_KEY)"
  "FLUXER_MEDIA_PROXY_UPLOAD_RELAY_SECRET_BASE64=$(secret UPLOAD_RELAY_SECRET)"
  "FLUXER_ADMIN_SECRET_KEY_BASE=$(secret ADMIN_SECRET_KEY_BASE)"
  "FLUXER_ADMIN_OAUTH_CLIENT_SECRET=$(secret ADMIN_OAUTH_CLIENT_SECRET)"
  "FLUXER_INTERNAL_API_ENDPOINT=http://127.0.0.1:8100"
  "FLUXER_INTERNAL_MEDIA_PROXY_ENDPOINT=http://127.0.0.1:8102"
  "FLUXER_MEDIA_PROXY_UPLOAD_RELAY_ENDPOINT=$ORIGIN/media"
)
# upstream's x-fluxer-rust-env: the Rust services get two threads each.
RUST_ENV=("${FLUXER_ENV[@]}" "TOKIO_WORKER_THREADS=2" "MALLOC_ARENA_MAX=2")

# The internal services (upstream's svc block). Each one gets its own port.
write_env snowflakes "${RUST_ENV[@]}" "FLUXER_SVC_NAME=snowflakes" "FLUXER_SVC_MODE=combined" "FLUXER_SVC_PORT=8110"
write_env users      "${RUST_ENV[@]}" "FLUXER_SVC_NAME=users"      "FLUXER_SVC_MODE=combined" "FLUXER_SVC_PORT=8111" "FLUXER_POSTGRES_MAX_CONNECTIONS=20"
write_env gifs       "${RUST_ENV[@]}" "FLUXER_SVC_NAME=gifs"       "FLUXER_SVC_MODE=combined" "FLUXER_SVC_PORT=8112" "FLUXER_GIFS_SHARD_CACHE_MAX_BYTES=134217728"
write_env messages   "${RUST_ENV[@]}" "FLUXER_SVC_NAME=messages"   "FLUXER_SVC_MODE=combined" "FLUXER_SVC_PORT=8113" "FLUXER_POSTGRES_MAX_CONNECTIONS=20"
write_env unfurl     "${RUST_ENV[@]}" "FLUXER_SVC_NAME=unfurl"     "FLUXER_SVC_MODE=combined" "FLUXER_SVC_PORT=8114" \
  "FLUXER_MEDIA_PROXY_ENDPOINT=http://127.0.0.1:8102" \
  "FLUXER_ACTIVITYPUB_SIGNING_KEY_BASE64=$(secret ACTIVITYPUB_KEY)"

# The API and the worker: the same image. Node's heap is capped, since both
# share this container's memory with everything else.
write_env api "${FLUXER_ENV[@]}" \
  "FLUXER_API_PORT=8100" \
  "FLUXER_SETUP_TOKEN=$SETUP_TOKEN" \
  "NODE_OPTIONS=--max-old-space-size=${FLUXER_API_NODE_HEAP_MB:-1536}" \
  "NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt" \
  "FLUXER_POSTGRES_MAX_CONNECTIONS=25" \
  "FLUXER_API_PRESIGNED_ATTACHMENT_UPLOADS_ENABLED=true" \
  "FLUXER_API_EMBEDDED_WORKER=false"
write_env worker "${FLUXER_ENV[@]}" \
  "NODE_OPTIONS=--max-old-space-size=${FLUXER_WORKER_NODE_HEAP_MB:-1024}" \
  "NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt" \
  "FLUXER_API_WORKER_MODE=all_lanes" \
  "FLUXER_API_WORKER_ENABLE_CRON_SCHEDULER=true" \
  "FLUXER_POSTGRES_MAX_CONNECTIONS=25"

# The realtime gateway (upstream's "gateway"): Erlang, distribution on 8081.
write_env realtime "${FLUXER_ENV[@]}" \
  "FLUXER_GATEWAY_PORT=8101" \
  "FLUXER_GATEWAY_MEDIA_PROXY_ENDPOINT=$ORIGIN/media" \
  "FLUXER_GATEWAY_STATIC_CDN_ENDPOINT=$ORIGIN" \
  "FLUXER_ERLANG_COOKIE=$(secret ERLANG_COOKIE)" \
  "FLUXER_ERLANG_DIST_PORT=8081" \
  "HOME=/opt/fluxer_gateway"

write_env media "${FLUXER_ENV[@]}" \
  "FLUXER_MEDIA_PROXY_PORT=8102" \
  "TOKIO_WORKER_THREADS=4" \
  "FLUXER_MEDIA_PROXY_MODE=upload" \
  "FLUXER_MEDIA_PROXY_STORAGE_BACKEND=s3" \
  "FLUXER_MEDIA_PROXY_CORS_ALLOWED_ORIGINS=$ORIGIN" \
  "FLUXER_MEDIA_PROXY_UPLOAD_RELAY_SPOOL_MAX_TOTAL_BYTES=2147483648" \
  "FLUXER_S3_READ_SIGNED=true"

write_env push "${RUST_ENV[@]}" "FLUXER_PUSH_SERVICE_PORT=8126"

write_env app "$TZV" \
  "RUST_LOG=${RUST_LOG:-info}" \
  "TOKIO_WORKER_THREADS=2" \
  "FLUXER_APP_PROXY_PORT=8103" \
  "FLUXER_S3_BUCKET_UPLOADS=fluxer-uploads" \
  "DISCOVERY_UPSTREAM_URL=http://127.0.0.1:8100/.well-known/fluxer" \
  "DISCOVERY_REFRESH_INTERVAL_MS=5000"

write_env admin "${RUST_ENV[@]}" \
  "FLUXER_ADMIN_PORT=8104" \
  "FLUXER_ADMIN_BASE_PATH=/admin" \
  "FLUXER_API_ENDPOINT=http://127.0.0.1:8100" \
  "FLUXER_API_PUBLIC_ENDPOINT=$ORIGIN/api"

# ---- settings: the README variables: list (Apps/fluxer/) ----
# Every Fluxer service reads its own FLUXER_* settings by name, so any you
# add in the app settings are passed on as they are; blank ones are skipped,
# so they mean "default". Env files are read top to bottom, so yours win.
pass_env snowflakes 'FLUXER_[A-Z0-9_]+'
pass_env users      'FLUXER_[A-Z0-9_]+'
pass_env gifs       'FLUXER_[A-Z0-9_]+'
pass_env messages   'FLUXER_[A-Z0-9_]+'
pass_env unfurl     'FLUXER_[A-Z0-9_]+'
pass_env api        'FLUXER_[A-Z0-9_]+'
pass_env worker     'FLUXER_[A-Z0-9_]+'
pass_env realtime   'FLUXER_[A-Z0-9_]+'
pass_env media      'FLUXER_[A-Z0-9_]+'
pass_env push       'FLUXER_[A-Z0-9_]+'
pass_env app        'FLUXER_(APP|CSP|STATIC|MEDIA|LIVEKIT|S3)_[A-Z0-9_]+'
pass_env admin      'FLUXER_[A-Z0-9_]+'

# Files in /data/state/overrides/<service>.env are appended last, so users can
# change any service setting without rebuilding the image.
for f in "$STATE"/overrides/*.env; do
  [ -f "$f" ] || continue
  svc=$(basename "$f" .env)
  log "applying your overrides to $svc"
  cat "$f" >> "$RUN/$svc.env"
done

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add "SETUP TOKEN" "$SETUP_TOKEN"
cred_add "ADMIN PANEL" "$(cred_url "$PUBLIC_URL/admin")"
cred_note "On the first visit, enter the setup token to create the admin account."

if [ "${AIO_DRY_RUN:-}" = 1 ]; then
  log "dry run finished"
  exit 0
fi

# ---- built-in data folders and first-start database ----
chown valkey:valkey "$DATA/valkey"
pg_setup /usr/lib/postgresql/16/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb --data-checksums
  # Upstream's postgres image makes "fluxer" the superuser of its own
  # database; the API makes its tables and extensions on start.
  pg_start_local
  pg_psql -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE fluxer LOGIN SUPERUSER PASSWORD :'pw';
CREATE DATABASE fluxer OWNER fluxer;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
