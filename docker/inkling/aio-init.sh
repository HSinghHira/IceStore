#!/bin/bash
# First thing that runs in the container. Makes secrets and the first signup
# key, writes each service's environment, prepares the database, then hands
# over to supervisord.
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

# ---- public address: upstream's PUBLIC_URL. Mail links, the MCP OAuth
# ---- issuer and share previews use it; https turns on Secure cookies. The
# ---- web app itself works from any address. ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6703}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
case $PUBLIC_URL in
  *://localhost*|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL: Inkling opens from any address, but links and AI agent (MCP) sign-in use it;"
    log "set PUBLIC_URL to the address you open it at, like http://192.168.1.20:6703" ;;
esac

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/inkling"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret PG_PASSWORD 16
# Encrypts two-step verification secrets (upstream: openssl rand -base64 32).
# Without one, nobody can turn on two-step verification.
ensure_b64 APP_SECRET_KEY 32
# This install's first signup key, in Inkling's own format (XXXX-XXXX-XXXX-XXXX).
if ! grep -q '^FIRST_KEY=' "$SECRETS"; then
  k=$(openssl rand -base64 48 | tr -dc 'ABCDEFGHJKMNPQRSTUVWXYZ23456789' | head -c 16)
  echo "FIRST_KEY=${k:0:4}-${k:4:4}-${k:8:4}-${k:12:4}" >> "$SECRETS"
fi
PG_PASSWORD=$(secret PG_PASSWORD)
FIRST_KEY=$(secret FIRST_KEY)

# ---- CREDENTIALS banner, printed on every boot once Inkling answers ----
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add "SIGN UP" "$(cred_url "$PUBLIC_URL/register?key=$FIRST_KEY")"
cred_add "SIGNUP KEY" "$FIRST_KEY"
cred_note "The first person to sign up with this key becomes the admin."
cred_note "After that, make keys for others under Admin; this one stops working once used."

# ---- hostnames from upstream's compose, all pointed at 127.0.0.1 ----
if ! grep -q ' db app backup' "$HOSTS"; then
  echo "127.0.0.1 db app backup" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: Inkling keeps uploads and plugins in /data (DATA_DIR).
  if [ "$name" = inkling ]; then
    mkdir -p "$d/data"
    mountpoint -q "$d/data" || mount --bind "$DATA/inkling" "$d/data" 2>/dev/null \
      || log "warning: could not mount $DATA/inkling into the inkling chroot; uploads would be lost on update"
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 3000 5432 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" \
    "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

write_env postgres "$TZV"
write_env firstkey "PG_PASSWORD=$PG_PASSWORD" "FIRST_KEY=$FIRST_KEY"

# Upstream's app service. PORT, DATA_DIR, WEB_DIST and DRIZZLE_DIR come from
# the image, as upstream's compose file leaves them.
write_env inkling "$TZV" \
  "DATABASE_URL=postgres://nodian:$PG_PASSWORD@127.0.0.1:5432/nodian" \
  "NODE_ENV=production" \
  "NODE_OPTIONS=${INKLING_NODE_OPTIONS:---max-old-space-size=512}" \
  "PUBLIC_URL=$PUBLIC_URL" \
  "APP_SECRET_KEY=$(secret APP_SECRET_KEY)" \
  "COOKIE_SECURE=${COOKIE_SECURE:-0}"

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional Inkling setting from the README Variables list, by its own
# name: sign-up, OIDC and delegated login, mail, brute-force protection,
# imports, updates, language, Notion, embeds, experimental features.
pass_env inkling 'SIGNUP_REQUIRE_KEY|OIDC_[A-Z_]+|DELEGATED_(AUTH_URL|AUTH_NAME|EMAIL_DOMAIN)|SMTP_(HOST|PORT|SECURE|USER|PASS)|MAIL_FROM|APP_URL|REQUIRE_EMAIL_VERIFICATION|TRUST_PROXY|ALLOWLIST_IPS|AUTH_GUARD_[A-Z_]+|IMPORT_MAX_[A-Z_]+|UPDATE_(MODE|CHECK|CHECK_REPO)|DEFAULT_LOCALE|NOTION_TOKEN|EMBED_EXTRA_FRAME_SRC|EXPERIMENTAL_FEATURES'

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
  pg_initdb
  # Upstream's postgres image makes "nodian" (Inkling's old name) the owner
  # of its database; the app's migrations make the tables and extensions.
  pg_start_local
  pg_psql -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE nodian LOGIN SUPERUSER PASSWORD :'pw';
CREATE DATABASE nodian OWNER nodian;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
