#!/bin/bash
# First thing that runs in the container. Makes secrets, writes each
# service's environment, then hands over to supervisord. MySQL's own
# entrypoint makes the database on first start.
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

# ---- public address: Ghost's url ----
# Ghost writes this address into every link, email and redirect, and sends
# the admin to it, so it must be the address people type. The compose file
# ships the [ZIMAOS-IP-ADDRESS] placeholder; until it is replaced Ghost runs
# on localhost and other addresses get a note.
PUBLIC_URL=${PUBLIC_URL:-http://[ZIMAOS-IP-ADDRESS]:6752}
PUBLIC_URL=${PUBLIC_URL%/}
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
case $host in
  localhost|127.0.0.1)
    log "PUBLIC_URL uses localhost, so Ghost only works on this server; set it to http://[ZIMAOS-IP-ADDRESS]:6752 with your IP" ;;
  *) log "Ghost works at $PUBLIC_URL (open it at exactly that address)" ;;
esac

# ---- one folder per stateful service under /data ----
# mysql/ holds posts, members and settings; content/ the images, themes and
# files Ghost keeps on disk.
STATE=$DATA/state
mkdir -p "$STATE/overrides" "$DATA/mysql" "$DATA/content"
SECRETS=$STATE/secrets.env
touch "$SECRETS"
chmod 600 "$SECRETS"

# ---- secrets: made once, kept in /data/state/secrets.env forever ----
ensure_secret MYSQL_ROOT_PASSWORD 16
ensure_secret GHOST_DB_PASSWORD 16
ensure_secret MAIL_PASSWORD 12
GHOST_DB_PASSWORD=$(secret GHOST_DB_PASSWORD)
MAIL_PASSWORD=$(secret MAIL_PASSWORD)

MAIL_LOGIN_FILE=$DATA/mail-password.txt
MAIL_UI_AUTH=${MP_UI_AUTH:-}
if [ -z "$MAIL_UI_AUTH" ]; then
  MAIL_UI_AUTH="admin:$MAIL_PASSWORD"
  if [ ! -s "$MAIL_LOGIN_FILE" ]; then
    printf 'Mail viewer (/mail) login\nusername: admin\npassword: %s\n' "$MAIL_PASSWORD" > "$MAIL_LOGIN_FILE"
    chmod 600 "$MAIL_LOGIN_FILE"
  fi
fi

# ---- CREDENTIALS banner, printed on every boot once the app answers ----
SHOW_URL=$(cred_url "$PUBLIC_URL")
cred_reset
cred_add SITE "$SHOW_URL"
cred_add ADMIN "$SHOW_URL/ghost/"
if [ -n "${MP_UI_AUTH:-}" ]; then
  cred_add "MAIL VIEWER" "$SHOW_URL/mail/  (the login you set in MP_UI_AUTH)"
else
  cred_add "MAIL VIEWER" "$SHOW_URL/mail/  admin / $MAIL_PASSWORD"
  cred_note "Mail viewer login also saved in $MAIL_LOGIN_FILE"
fi
cred_note "First visit to /ghost/ makes the owner account. Sign-in codes for new devices are emailed (see the mail viewer)."

# ---- hostnames from upstream's compose, all pointed at 127.0.0.1 ----
if ! grep -q 'ghost-mailpit' "$HOSTS"; then
  echo "127.0.0.1 db ghost ghost-mailpit" >> "$HOSTS"
fi

# ---- chroot services: the generic part is prep_chroots (lib.sh) ----
chroot_extra() {
  local d=$1 name=$2
  # APP-SPECIFIC: keep MySQL's data and Ghost's content in /data. Both images'
  # entrypoints give the folder to their own user (mysql, node).
  case $name in
    mysql)
      mkdir -p "$d/var/lib/mysql"
      mountpoint -q "$d/var/lib/mysql" || mount --bind "$DATA/mysql" "$d/var/lib/mysql"
      ;;
    ghost)
      mkdir -p "$d/var/lib/ghost/content"
      mountpoint -q "$d/var/lib/ghost/content" || mount --bind "$DATA/content" "$d/var/lib/ghost/content"
      ;;
  esac
  return 0
}
prep_chroots

# ---- gateway: also listen on the PUBLIC_URL port, so services that call
# ---- PUBLIC_URL from inside the container reach the gateway ----
PUBLIC_PORT=""
[[ $hostport == *:* ]] && PUBLIC_PORT=${hostport##*:}
EXTRA_LISTEN=""
INTERNAL_PORTS=" 1025 2368 3306 8025 33060 "
if [[ $PUBLIC_PORT =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" != "$GATEWAY_PORT" ]; then
  case "$INTERNAL_PORTS" in
    *" $PUBLIC_PORT "*) log "PUBLIC_URL port $PUBLIC_PORT is used inside the container; internal calls to $PUBLIC_URL may fail" ;;
    *) EXTRA_LISTEN="listen $PUBLIC_PORT;"
       log "also listening on $PUBLIC_PORT inside the container so services can reach $PUBLIC_URL" ;;
  esac
fi

GUARD_FILE=$(dirname "$NGINX_OUT")/aio-guard.conf
case $host in
  localhost|127.0.0.1)
    cat > "$GUARD_FILE" <<'EOF'
if ($host !~* "^(localhost|127\.0\.0\.1)$") {
    return 503 "Ghost is not set up for this address yet.\n\nPUBLIC_URL still has no ZimaOS IP in it, so Ghost would send you to localhost.\n\nOpen the Ghost app settings in ZimaOS, set PUBLIC_URL to http://$host:6752 and save. The app restarts and then works here.\n";
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
pass_env() { env | grep -E "^($2)=." >> "$RUN/$1.env" || true; }
TZV="TZ=${TZ:-UTC}"

# MySQL: the official entrypoint makes the root password, the ghost database
# and the ghost user on the first start only (empty data folder).
write_env mysql "$TZV" \
  "MYSQL_ROOT_PASSWORD=$(secret MYSQL_ROOT_PASSWORD)" \
  "MYSQL_DATABASE=ghost" \
  "MYSQL_USER=ghost" \
  "MYSQL_PASSWORD=$GHOST_DB_PASSWORD"

# Email: blank mail__options__host = the built-in mail viewer at /mail.
SMTP_HOST=${mail__options__host:-}
if [ -z "$SMTP_HOST" ]; then
  log "no mail__options__host set: emails go to the mail viewer at $PUBLIC_URL/mail/"
  SMTP=("mail__options__host=127.0.0.1" "mail__options__port=1025"
        "mail__options__secure=false" "mail__options__ignoreTLS=true")
else
  SMTP=("mail__options__host=$SMTP_HOST" "mail__options__port=${mail__options__port:-587}")
fi

# From upstream's ghost-docker compose.yml, with MySQL on 127.0.0.1.
write_env ghost "$TZV" \
  "NODE_ENV=production" \
  "url=$PUBLIC_URL" \
  "server__host=127.0.0.1" \
  "server__port=2368" \
  "database__client=mysql" \
  "database__connection__host=127.0.0.1" \
  "database__connection__port=3306" \
  "database__connection__user=ghost" \
  "database__connection__password=$GHOST_DB_PASSWORD" \
  "database__connection__database=ghost" \
  "mail__transport=SMTP" \
  "${SMTP[@]}" \
  "mail__from=${mail__from:-Ghost <noreply@ghost.local>}"

# ---- settings: the README variables: list (Apps/ghost/) ----
# Ghost reads these itself on every start; blank ones are skipped, so they
# mean "default". With the mail viewer, the SMTP login is skipped.
if [ -n "$SMTP_HOST" ]; then
  pass_env ghost 'mail__options__(secure|service|auth__user|auth__pass)'
fi
pass_env ghost 'admin__url|security__staffDeviceVerification|privacy__[A-Za-z]+|logging__level'

write_env mailpit "$TZV" \
  "MP_SMTP_AUTH_ACCEPT_ANY=1" \
  "MP_SMTP_AUTH_ALLOW_INSECURE=1" \
  "MP_SMTP_BIND_ADDR=127.0.0.1:1025" \
  "MP_UI_BIND_ADDR=127.0.0.1:8025" \
  "MP_WEBROOT=/mail/" \
  "MP_UI_AUTH=$MAIL_UI_AUTH"
pass_env mailpit 'MP_MAX_MESSAGES'

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

[ -d "$DATA/mysql/mysql" ] || log "first start: MySQL makes the ghost database now (about a minute)"

exec /usr/bin/supervisord -n -c /etc/supervisor/aio.conf
