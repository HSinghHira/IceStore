#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each
# service's environment and SearXNG's settings, then hands over to
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

# Shared IceStore helpers (docker/_common/lib.sh): log, ensure_secret, secret,
# cred_add, prep_chroots.
. "${AIO_LIB:-/usr/local/lib/icestore/lib.sh}"

# Odysseus follows the browser's address (ALLOWED_ORIGINS is only for other
# sites calling its API), so it needs no public URL. The banner shows the
# published port.
APP_URL=http://localhost:6753

# ---- one folder per stateful service under /data ----
# odysseus/ holds the app's data, logs, SSH keys, model downloads and
# pip-installed tools (upstream's five bind mounts); chromadb/ the vectors;
# searxng/ its settings.yml.
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/chromadb" "$DATA/searxng" \
         "$DATA/odysseus/data" "$DATA/odysseus/logs" "$DATA/odysseus/ssh" \
         "$DATA/odysseus/huggingface" "$DATA/odysseus/local"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
# ADMIN_PASSWORD is handed to Odysseus's first-start setup, which only uses
# it while there is no admin yet (data/auth.json). SEARXNG_SECRET signs
# SearXNG's cookies.
ensure_secret ADMIN_PASSWORD 9
ensure_secret SEARXNG_SECRET 32
ADMIN_USER=${ODYSSEUS_ADMIN_USER:-admin}
ADMIN_PW=${ODYSSEUS_ADMIN_PASSWORD:-$(secret ADMIN_PASSWORD)}

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
cred_reset
cred_add URL "$(cred_url "$APP_URL")"
cred_add USERNAME "$ADMIN_USER"
if [ -n "${ODYSSEUS_ADMIN_PASSWORD:-}" ]; then
  cred_add PASSWORD "(the one you set in ODYSSEUS_ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PW"
fi
cred_note "Used to make the admin on first start; change it in Settings afterwards. Add a model provider in Settings (Ollama, OpenAI, ...)."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q 'chromadb' "$HOSTS"; then
  echo "127.0.0.1 odysseus chromadb searxng" >> "$HOSTS"
fi

# ---- SearXNG settings: upstream's defaults plus JSON output for Odysseus ----
# Written once; edit /DATA/AppData/odysseus/data/searxng/settings.yml to
# change search engines.
SX_SETTINGS=$DATA/searxng/settings.yml
if [ ! -s "$SX_SETTINGS" ]; then
  cat > "$SX_SETTINGS" <<EOF
# SearXNG for Odysseus (IceStore). Upstream defaults plus the JSON API.
use_default_settings: true
general:
  instance_name: "Odysseus search"
server:
  secret_key: "$(secret SEARXNG_SECRET)"
  base_url: "http://127.0.0.1:8888/"
  limiter: false
  image_proxy: false
search:
  safe_search: 0
  formats:
    - html
    - json
EOF
  log "first start: wrote SearXNG settings to $SX_SETTINGS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
bind_dir() {
  mkdir -p "$2"
  mountpoint -q "$2" || mount --bind "$1" "$2"
}
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: every folder that keeps data comes from /data. Odysseus's
  # and SearXNG's entrypoints give theirs to their own users.
  case $name in
    odysseus)
      bind_dir "$DATA/odysseus/data"        "$d/app/data"
      bind_dir "$DATA/odysseus/logs"        "$d/app/logs"
      bind_dir "$DATA/odysseus/ssh"         "$d/app/.ssh"
      bind_dir "$DATA/odysseus/huggingface" "$d/app/.cache/huggingface"
      bind_dir "$DATA/odysseus/local"       "$d/app/.local"
      ;;
    chromadb) bind_dir "$DATA/chromadb" "$d/data" ;;
    searxng)  bind_dir "$DATA/searxng"  "$d/etc/searxng" ;;
  esac
  return 0
}
prep_chroots

# ---- gateway ----
# Nothing inside calls the public address, so the gateway listens on 8080 only.
EXTRA_LISTEN=""
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

write_env chromadb "$TZV" "ANONYMIZED_TELEMETRY=FALSE"

# SearXNG's image listens on 8080 (the gateway's), so it moves to 8888.
write_env searxng "$TZV" \
  "GRANIAN_HOST=127.0.0.1" \
  "GRANIAN_PORT=8888" \
  "SEARXNG_BASE_URL=http://127.0.0.1:8888/" \
  "SEARXNG_SECRET=$(secret SEARXNG_SECRET)"

# From upstream's docker-compose.yml, with SearXNG and ChromaDB on 127.0.0.1.
write_env odysseus "$TZV" \
  "PUID=${PUID:-1000}" \
  "PGID=${PGID:-1000}" \
  "SEARXNG_INSTANCE=http://127.0.0.1:8888" \
  "CHROMADB_HOST=127.0.0.1" \
  "CHROMADB_PORT=8000" \
  "DATABASE_URL=sqlite:///./data/app.db" \
  "AUTH_ENABLED=true" \
  "LOCALHOST_BYPASS=false" \
  "ODYSSEUS_ADMIN_USER=$ADMIN_USER" \
  "ODYSSEUS_ADMIN_PASSWORD=$ADMIN_PW" \
  "LLM_HOST=${LLM_HOST:-localhost}" \
  "ALLOWED_ORIGINS=${ALLOWED_ORIGINS:-http://localhost,http://127.0.0.1}" \
  "FASTEMBED_MODEL=${FASTEMBED_MODEL:-sentence-transformers/all-MiniLM-L6-v2}"

# ---- settings: the README variables: list (Apps/odysseus/) ----
# Odysseus reads these itself on every start; blank ones are skipped, so they
# mean "default".
pass_env odysseus 'LLM_HOSTS|OPENAI_API_KEY|OLLAMA_BASE_URL|LM_STUDIO_URL|RESEARCH_LLM_ENDPOINT|HF_TOKEN|HUGGING_FACE_HUB_TOKEN'
pass_env odysseus 'EMBEDDING_URL|EMBEDDING_MODEL|EMBEDDING_API_KEY|SECURE_COOKIES|COMPANION_BASE_URL'
pass_env odysseus 'DATA_BRAVE_API_KEY|GOOGLE_API_KEY|GOOGLE_PSE_CX|TAVILY_API_KEY|SERPER_API_KEY|YDC_API_KEY'
pass_env odysseus 'GOOGLE_OAUTH_CLIENT_ID|GOOGLE_OAUTH_CLIENT_SECRET|GOOGLE_OAUTH_REDIRECT_URI|OAUTH_REDIRECT_BASE_URL'
pass_env odysseus 'CLEANUP_INTERVAL_HOURS|ODYSSEUS_CHAT_UPLOAD_MAX_BYTES|ODYSSEUS_FIRST_TOKEN_TIMEOUT'

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

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
