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

# Shared IceStore helpers: log, ensure_secret, secret, cred_add (docker/_common).
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# ---- public address: Reelsaw's APP_URL. Sign-in cookies, the allowed
# ---- origin and links in emails come from it, so sign-in only works on the
# ---- address written here. ----
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6690}
PUBLIC_URL=${PUBLIC_URL%/}
# The compose file ships http://[ZIMAOS-IP-ADDRESS]:6690 so people see they
# must put their IP there. Until they do, run on localhost (so Reelsaw
# starts) and show the "set PUBLIC_URL" note to every other address (below).
case $PUBLIC_URL in
  *"[ZIMAOS-IP-ADDRESS]"*)
    log "PUBLIC_URL is still $PUBLIC_URL: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP in the app settings"
    PUBLIC_URL=${PUBLIC_URL//"[ZIMAOS-IP-ADDRESS]"/localhost} ;;
esac
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
host=${hostport%:*}

# No AI provider at all: Reelsaw stops at start. Say what to do first.
if [ -z "${OPENAI_API_KEY:-}${ANTHROPIC_API_KEY:-}${GOOGLE_GENERATIVE_AI_API_KEY:-}${GROQ_API_KEY:-}${AI_GATEWAY_API_KEY:-}${OPENAI_COMPATIBLE_BASE_URL:-}${OPENAI_BASE_URL:-}" ]; then
  log "no AI provider is set: Reelsaw will stop at start unless an admin already saved one in its Settings."
  log "Set OPENAI_API_KEY (or another provider from the Variables tab) in the app settings."
fi

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/reelsaw"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret PG_PASSWORD 16
# Signs sessions and encrypts the provider keys admins enter in Settings;
# changing it makes those keys unreadable.
ensure_b64 BETTER_AUTH_SECRET 32

PG_PASSWORD=$(secret PG_PASSWORD)
BETTER_AUTH_SECRET=$(secret BETTER_AUTH_SECRET)

# ---- CREDENTIALS banner, printed on every boot once Reelsaw answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_note "Open the URL and sign up: the first account is the admin."
cred_note "Others who sign up wait for your approval (SIGNUP_MODE)."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' reelsaw-db' "$HOSTS"; then
  echo "127.0.0.1 db app reelsaw-db" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: Reelsaw keeps uploads, renders, caches and its log in
  # /data (DATA_DIR). Its own entrypoint gives the folder to the node user.
  if [ "$name" = reelsaw ]; then
    mkdir -p "$d/data"
    mountpoint -q "$d/data" || mount --bind "$DATA/reelsaw" "$d/data" 2>/dev/null \
      || log "warning: could not mount $DATA/reelsaw into the reelsaw chroot"
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 5432 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

# Sign-in only works on PUBLIC_URL, so with the default (localhost) anyone on
# another address gets a short note saying what to set instead. Requests to
# localhost/127.0.0.1 (the box itself, the healthcheck) still go through.
GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Reelsaw is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so sign-in would be refused here.\n\nOpen the Reelsaw app settings in ZimaOS, set PUBLIC_URL to http://$host:6690 and save. After the app restarts, open this page again.\n";
}
EOF
    ;;
  *) : > "$GUARD_FILE" ;;
esac
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    -e "s/@GUARD_FILE@/$(sed_escape "$GUARD_FILE")/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# Same environment as upstream's app service (web and workers in one
# process). The gateway is the reverse proxy in front, so the client address
# comes from X-Forwarded-For.
write_env reelsaw "$TZV" \
  "DATABASE_URL=postgres://reelsaw:$PG_PASSWORD@127.0.0.1:5432/reelsaw" \
  "PORT=3000" \
  "DATA_DIR=/data" \
  "WATERMARK_LOGO_PATH=/app/server/assets/watermark.png" \
  "LOG_FILE=/data/logs/reelsaw.log" \
  "RUN_HTTP=true" \
  "RUN_WORKERS=true" \
  "APP_URL=$PUBLIC_URL" \
  "BETTER_AUTH_SECRET=$BETTER_AUTH_SECRET" \
  "TRUST_PROXY=true" \
  "SHUTDOWN_GRACE_SECONDS=${SHUTDOWN_GRACE_SECONDS:-60}" \
  "SIGNUP_MODE=${SIGNUP_MODE:-approval}" \
  "AI_MODEL=${AI_MODEL:-openai:gpt-4o-mini}" \
  "TRANSCRIPTION_MODEL=${TRANSCRIPTION_MODEL:-openai:whisper-1}"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional Reelsaw setting from the README Variables list (and the
# provider key in the compose file), by its own name: provider keys and
# servers, extra models, email, uploads, stock media, MCP, logs.
pass_env reelsaw 'OPENAI_(API_KEY|BASE_URL|API_MODE)|ANTHROPIC_API_KEY|GOOGLE_GENERATIVE_AI_API_KEY|GROQ_API_KEY|DEEPGRAM_API_KEY|ASSEMBLYAI_API_KEY|AI_GATEWAY_API_KEY|OPENAI_COMPATIBLE_(BASE_URL|API_KEY|NAME|STRUCTURED_OUTPUTS)|TRANSCRIPT_ALIGN_MODEL|ANALYZE_JUDGE_MODEL|EMAIL_(DRIVER|FROM)|SMTP_URL|RESEND_API_KEY|REQUIRE_EMAIL_VERIFICATION|MAX_UPLOAD_MB|MAX_SOURCE_FILE_MB|ALLOW_PRIVATE_SOURCE_URLS|MCP_OAUTH|UPDATE_CHECK|PEXELS_API_KEY|PIXABAY_API_KEY|FREESOUND_API_KEY|RENDER_CONCURRENCY|LOG_LEVEL'

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
pg_setup /usr/lib/postgresql/17/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb

  # Reelsaw's own role and database. Its migrations create the tables;
  # pg_trgm (clip search) is made here so it never depends on the role.
  pg_start_local
  pg_psql \
      -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE reelsaw LOGIN PASSWORD :'pw';
CREATE DATABASE reelsaw OWNER reelsaw;
\c reelsaw
CREATE EXTENSION IF NOT EXISTS pg_trgm;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
