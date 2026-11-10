#!/bin/bash
# First thing that runs in the container. Writes the AI keys from the app
# settings into the key files upstream reads, makes this install's push key,
# writes each service's environment, then hands over to supervisord.
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

# ---- the address people open. TEF Notes follows the browser's address;
# ---- this one is only shown in the CREDENTIALS banner. ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6718}
PUBLIC_URL=${PUBLIC_URL%/}
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
case $PUBLIC_URL in
  https://*) ;;
  *) log "over plain http the web app works, but browsers hide the microphone and won't install the app; use an https address (a reverse proxy) for those" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
KEYS=$DATA/keys
PROVIDER=${TEF_NOTES_PROVIDER:-deepseek}
mkdir -p "$STATE/overrides" "$DATA/pb_data" "$DATA/agent" "$DATA/stt" \
  "$KEYS/typesafe" "$KEYS/llm" "$KEYS/exa" "$KEYS/push"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- keys: upstream reads each from a file named api-key in its own folder,
# ---- on every use. A key set in the app settings is written there; a blank
# ---- one removes the file, so that feature is off. ----
put_key() {  # put_key <folder> <value>
  if [ -n "$2" ]; then
    printf '%s' "$2" > "$KEYS/$1/api-key"
  else
    rm -f "$KEYS/$1/api-key"
  fi
}
put_key typesafe "${TEF_NOTES_TYPESAFE_KEY:-}"
put_key llm "${TEF_NOTES_LLM_KEY:-}"
put_key exa "${TEF_NOTES_EXA_KEY:-}"
# Push reminders: this install's VAPID private key (unpadded base64url of
# the raw P-256 key, as web-push makes it), made once.
if ! grep -q '^VAPID_PRIVATE_KEY=' "$SECRETS"; then
  pem=$(mktemp)
  openssl ecparam -name prime256v1 -genkey -noout -out "$pem" 2>/dev/null
  echo "VAPID_PRIVATE_KEY=$(openssl ec -in "$pem" -outform DER 2>/dev/null | dd bs=1 skip=7 count=32 2>/dev/null | base64 -w0 | tr '/+' '_-' | tr -d '=')" >> "$SECRETS"
  rm -f "$pem"
fi
put_key push "${TEF_NOTES_PUSH_KEY:-$(secret VAPID_PRIVATE_KEY)}"
[ -n "${TEF_NOTES_LLM_KEY:-}" ] || [ "$PROVIDER" = ollama ] \
  || log "no TEF_NOTES_LLM_KEY: the AI agent and clip write-ups are off until you add your $PROVIDER key in the app settings"

# ---- CREDENTIALS banner, printed on every boot once TEF Notes answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add "ADMIN UI" "$(cred_url "$PUBLIC_URL/_/")"
cred_note "TEF Notes has no sign-in: keep it on your home network or behind a VPN."
cred_note "PocketBase prints a one-time link to make the admin UI's superuser in these logs on the first start."

# ---- hostnames from upstream's compose, all pointed at 127.0.0.1 ----
if ! grep -q ' pocketbase agent stt' "$HOSTS"; then
  echo "127.0.0.1 pocketbase agent stt" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
bind_dir() {  # bind_dir <chroot dir> <path inside> <host dir> [user to own it]
  mkdir -p "$1/$2"
  mountpoint -q "$1/$2" || mount --bind "$3" "$1/$2" 2>/dev/null \
    || log "warning: could not mount $3 at $2 in $(basename "$1")"
  if [ -n "${4:-}" ]; then
    uid=$(awk -F: -v u="$4" '$1==u {print $3":"$4; exit}' "$1/etc/passwd")
    [ -n "$uid" ] && chown -R "$uid" "$3"
  fi
  return 0
}
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: upstream's volumes and key mounts.
  case $name in
    pocketbase)
      bind_dir "$d" pb/pb_data "$DATA/pb_data"
      bind_dir "$d" run/typesafe "$KEYS/typesafe"
      bind_dir "$d" run/llm "$KEYS/llm" ;;
    agent)
      bind_dir "$d" data "$DATA/agent" bun
      bind_dir "$d" run/llm "$KEYS/llm"
      bind_dir "$d" run/exa "$KEYS/exa"
      bind_dir "$d" run/push "$KEYS/push"
      uid=$(awk -F: '$1=="bun" {print $3":"$4; exit}' "$d/etc/passwd")
      [ -n "$uid" ] && chown -R "$uid" "$KEYS" ;;
    stt)
      bind_dir "$d" data "$DATA/stt" stt ;;
  esac
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port inside the container ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 8090 8098 8099 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;" ;;
  esac
fi
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# Upstream's three services, as its compose file sets them.
write_env pocketbase "$TZV" "TEF_NOTES_PROVIDER=$PROVIDER"
write_env agent "$TZV" \
  "TEF_NOTES_PB=http://127.0.0.1:8090" \
  "TEF_NOTES_PROVIDER=$PROVIDER" \
  "TEF_NOTES_MCP=${TEF_NOTES_MCP:-0}" \
  "TEF_NOTES_STT=${TEF_NOTES_STT-http://127.0.0.1:8099}"
write_env stt "$TZV"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# The README Variables list, by upstream's own names.
pass_env pocketbase 'TEF_NOTES_(MODEL|LLM_URL|OLLAMA_URL)'
pass_env agent      'TEF_NOTES_(MODEL|LLM_URL|OLLAMA_URL|VAPID_SUBJECT)'

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
