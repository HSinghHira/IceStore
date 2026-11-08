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

# ---- public address: K7's BaseUrl. The web app follows the browser's own
# ---- address; BaseUrl matters for sign-in with OIDC, federation and share
# ---- link previews. ----
PUBLIC_URL=${PUBLIC_URL:-http://localhost:6186}
PUBLIC_URL=${PUBLIC_URL%/}
case $PUBLIC_URL in
  http://*|https://*) ;;
  *) log "PUBLIC_URL must start with http:// or https:// (got: $PUBLIC_URL)"; exit 1 ;;
esac
case $PUBLIC_URL in
  *://localhost:*|*://localhost|*://127.0.0.1*)
    log "PUBLIC_URL is $PUBLIC_URL. That is fine for watching on your network."
    log "For OIDC sign-in or federation, set PUBLIC_URL to http://<your ZimaOS IP>:6186 (or your https address)." ;;
esac
ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
ADMIN_PASSWORD_ENV=${ADMIN_PASSWORD:-}

# ---- one folder per stateful service under /data ----
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/postgres" "$DATA/k7"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret PG_PASSWORD 16
# HMAC secret for API key hashes. K7 refuses to start without it; changing it
# later invalidates every API key.
ensure_secret API_KEYS_HASH_SECRET 32
# K7's password rules: 10+ characters with an uppercase letter, a lowercase
# letter and a digit. Hex alone has no uppercase, hence the K7a- prefix.
ensure_secret ADMIN_PASSWORD 8 K7a-

PG_PASSWORD=$(secret PG_PASSWORD)
API_KEYS_HASH_SECRET=$(secret API_KEYS_HASH_SECRET)
ADMIN_PASSWORD=$(secret ADMIN_PASSWORD)

# ---- CREDENTIALS banner, printed on every boot once K7 answers ----
# K7 only uses the admin values on the very first start (see write_env k7).
cred_reset
cred_add URL "$(cred_url "$PUBLIC_URL")"
cred_add USERNAME "$ADMIN_USERNAME"
if [ -n "$ADMIN_PASSWORD_ENV" ]; then
  ADMIN_PASSWORD=$ADMIN_PASSWORD_ENV
  cred_add PASSWORD "(the one you set in ADMIN_PASSWORD)"
else
  cred_add PASSWORD "$ADMIN_PASSWORD"
fi
cred_note "Also saved in $SECRETS"
cred_note "Changed it in K7? Your new password is the one that works."

# ---- hostnames from upstream's docker-compose, all pointed at 127.0.0.1 ----
if ! grep -q ' k7-postgres' "$HOSTS"; then
  echo "127.0.0.1 postgres k7-postgres k7-server" >> "$HOSTS"
fi

# ---- media folders: every volume the user added, at any container path ----
# Upstream K7 reads media from whatever paths are mounted (/media, /movies,
# /tv ...). K7 runs in a chroot here, so each user volume is mounted into it at
# the same path. System paths and /data (handled on its own) are skipped, and
# a path inside another one is left to that one's rbind.
media_mounts() {
  local mp
  while read -r _ _ _ _ mp _; do
    mp=$(printf '%b' "$mp")
    case $mp in
      /|/data|/data/*) continue ;;
    esac
    case ${mp#/} in
      proc|proc/*|sys|sys/*|dev|dev/*|etc|etc/*|usr|usr/*|bin|bin/*|sbin|sbin/*) continue ;;
      lib|lib/*|lib32|lib32/*|lib64|lib64/*|libx32|libx32/*|opt|opt/*|run|run/*) continue ;;
      tmp|tmp/*|var|var/*|root|root/*|boot|boot/*|k7|k7/*|app|app/*) continue ;;
    esac
    printf '%s\n' "$mp"
  done < /proc/self/mountinfo | LC_ALL=C sort -u | {
    local kept=() k
    while IFS= read -r mp; do
      for k in "${kept[@]}"; do
        case $mp in "$k"/*) continue 2 ;; esac
      done
      kept+=("$mp")
      printf '%s\n' "$mp"
    done
  }
}

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: K7 keeps config, artwork, logs and transcodes in /data, reads
  # media from every user volume (see media_mounts), and uses /dev/dri for
  # hardware transcoding. Its own entrypoint gives /data to appuser (PUID/PGID)
  # and joins the /dev/dri groups; media folders keep their host owner.
  if [ "$(basename "$d")" = k7 ]; then
    mkdir -p "$d/data"
    mountpoint -q "$d/data" || mount --bind "$DATA/k7" "$d/data" 2>/dev/null \
      || log "warning: could not mount $DATA/k7 into the k7 chroot"
    local p found=0
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      found=1
      if [ -d "$p" ]; then
        mkdir -p "$d$p"
      else
        mkdir -p "$(dirname "$d$p")"; [ -e "$d$p" ] || : > "$d$p"
      fi
      if mountpoint -q "$d$p" || mount --rbind "$p" "$d$p" 2>/dev/null; then
        log "media folder $p is available to K7"
      else
        log "warning: could not mount $p into the k7 chroot"
      fi
    done < <(media_mounts)
    [ "$found" = 1 ] || log "no media folder found: add a volume in the app settings (like /media or /movies) to build libraries"
    if [ -d /dev/dri ]; then
      mkdir -p "$d/dev/dri"
      mountpoint -q "$d/dev/dri" || mount --rbind /dev/dri "$d/dev/dri" 2>/dev/null || true
      log "found /dev/dri: hardware transcoding is available"
    fi
  fi
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so calls to PUBLIC_URL
# ---- from inside the container reach the gateway ----
hostport=${PUBLIC_URL#*://}
hostport=${hostport%%/*}
PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 7080 5432 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi
sed -e "s/@GATEWAY_PORT@/$GATEWAY_PORT/g" -e "s/@EXTRA_LISTEN@/$EXTRA_LISTEN/g" "$NGINX_TPL" > "$NGINX_OUT"

# ---- one env file per service: /run/aio/<service>.env ----
mkdir -p "$RUN"
umask 077
write_env() { local svc=$1; shift; printf '%s\n' "$@" > "$RUN/$svc.env"; }
TZV="TZ=${TZ:-UTC}"

# Same environment as upstream's k7-server service. K7 only uses the
# K7_ADMIN_* values while setup is not done yet: they create the first admin
# on the first start and are ignored after that.
# Security__ForceHttps defaults to false here (upstream's compose does the
# same): Secure cookies break sign-in and /setup on a plain http:// address.
write_env k7 "$TZV" \
  "PUID=${PUID:-911}" \
  "PGID=${PGID:-911}" \
  "BaseUrl=$PUBLIC_URL" \
  "Database__Provider=Postgres" \
  "Database__Server=127.0.0.1" \
  "Database__Port=5432" \
  "Database__Name=k7" \
  "Database__UserID=k7" \
  "Database__Password=$PG_PASSWORD" \
  "Security__ApiKeys__HashSecret=$API_KEYS_HASH_SECRET" \
  "Security__ForceHttps=${Security__ForceHttps:-false}" \
  "Paths__Config=/data/config" \
  "Paths__Metadatas=/data/metadatas" \
  "Paths__Logs=/data/logs" \
  "Paths__Transcoding=/data/transcoding" \
  "K7_ADMIN_USERNAME=$ADMIN_USERNAME" \
  "K7_ADMIN_PASSWORD=$ADMIN_PASSWORD"
if [ -n "${ADMIN_EMAIL:-}" ]; then
  echo "K7_ADMIN_EMAIL=$ADMIN_EMAIL" >> "$RUN/k7.env"
fi

# pass_env <service> <regex>: copy container variables whose NAME matches the
# regex into that service's env file. Blank values are skipped, so an empty box
# in the app settings means "use the default" instead of "set it to nothing".
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }

# Every optional K7 setting from the README Variables list, by its own name.
pass_env k7 'Server__Name|AllowedHosts|Cors__Origins__[0-9]+|Authentication__(Local|Oidc)__[A-Za-z]+|Security__TrustPrivateProxies|Security__KnownProxies__[0-9]+|Security__Federation__[A-Za-z]+|Serilog__MinimumLevel__[A-Za-z0-9_.]+|OTEL_EXPORTER_OTLP_ENDPOINT'

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
pg_setup /usr/lib/postgresql/18/bin

if pg_is_new; then
  log "first start: creating the database"
  pg_initdb

  # K7's own role and database (upstream's postgres service makes the database
  # from POSTGRES_DB). K7's migrations create the tables on its first start;
  # pg_trgm (used for search) is made here so the role needs no superuser.
  pg_start_local
  pg_psql \
      -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE k7 LOGIN PASSWORD :'pw';
CREATE DATABASE k7 OWNER k7;
\c k7
CREATE EXTENSION IF NOT EXISTS pg_trgm;
SQL
  pg_stop_local
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
