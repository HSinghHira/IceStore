# shellcheck shell=bash
# Rules for this folder (it reaches every app built on it at once):
#   - only app-neutral code; app-specific setup stays in docker/<app>/
#   - never rename a function or change what an argument means; add a new one
#   - test with `just test <app>` on at least one app before pushing
#
# Shared helpers for IceStore images. The build copies this file to
# /usr/local/lib/icestore/lib.sh. All-in-one apps source it from aio-init.sh
# (bash); wrapper apps may source it from a plain /bin/sh start script, so the
# secret and banner helpers stay POSIX sh.
#
# Secrets (set SECRETS to the secrets file first):
#   ensure_secret NAME BYTES [PRE]  add NAME=<PRE><random hex> once;
#                                   sets NEW_<NAME>=1 when it was just made
#   ensure_b64 NAME BYTES           the same with base64 instead of hex
#   secret NAME                     print a saved secret
# CREDENTIALS banner (printed by credentials.sh):
#   cred_reset                      start an empty list (call once per boot)
#   cred_add LABEL VALUE            add a "LABEL: VALUE" line
#   cred_note TEXT                  add a free-text line under them
# All-in-one only (bash, root):
#   prep_chroots                    get every $ROOTFS/<name>/ ready to run
#   pg_setup PGBIN [DIR]            Postgres folders; then pg_is_new, pg_initdb,
#                                   pg_start_local, pg_psql, pg_stop_local
#   as_pg CMD...                    run a command as the postgres user
# Logging:
#   log TEXT...                     print "[init] TEXT" (LOG_TAG changes "init")

log() { echo "[${LOG_TAG:-init}] $*"; }

# ---- secrets ----
ensure_secret() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=${3:-}$(openssl rand -hex "$2")" >> "$SECRETS"
    eval "NEW_$1=1"
  fi
  return 0
}

ensure_b64() {
  if ! grep -q "^$1=" "$SECRETS"; then
    echo "$1=$(openssl rand -base64 "$2" | tr -d '\n')" >> "$SECRETS"
    eval "NEW_$1=1"
  fi
  return 0
}

secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# ---- CREDENTIALS banner ----
# credentials.sh reads this file. Wrapper apps with a read-only root set
# AIO_CRED_FILE to a writable place (e.g. /tmp/icestore-credentials) first.
CRED_FILE=${AIO_CRED_FILE:-/run/icestore/credentials}

cred_reset() {
  mkdir -p "$(dirname "$CRED_FILE")"
  (umask 077; : > "$CRED_FILE")
}

cred_add() { printf 'K\t%s\t%s\n' "$1" "$2" >> "$CRED_FILE"; }

cred_note() { printf 'N\t%s\n' "$1" >> "$CRED_FILE"; }

# cred_url URL: the address to show users. localhost, 127.0.0.1 or the
# [ZIMAOS-IP-ADDRESS] placeholder become "<your ZimaOS IP>", since the banner
# is read from another device.
cred_url() {
  case $1 in
    *://localhost*|*://127.0.0.1*|*'://[ZIMAOS-IP-ADDRESS]'*) ;;
    *) printf '%s\n' "$1"; return 0 ;;
  esac
  _cu_proto=${1%%://*}
  _cu_rest=${1#*://}
  _cu_host=${_cu_rest%%/*}
  _cu_path=${_cu_rest#"$_cu_host"}
  case $_cu_host in
    *]:*|[!\[]*:*) _cu_port=:${_cu_host##*:} ;;
    *) _cu_port= ;;
  esac
  printf '%s://<your ZimaOS IP>%s%s\n' "$_cu_proto" "$_cu_port" "$_cu_path"
}

# ---- chroot services ----
# Mounts /proc, /sys and /dev/shm and makes the basic /dev files in every
# $ROOTFS/<name>/. If the app defines chroot_extra, it is called as
# `chroot_extra <dir> <name>` for app-specific mounts (data folders, /dev/dri).
# End chroot_extra with `return 0`: a false test as its last line would
# otherwise stop aio-init.sh (set -e).
# CHROOT_SHM_SIZE (e.g. 512m) sizes /dev/shm; blank = the tmpfs default.
prep_chroots() {
  local d name err f
  for d in "$ROOTFS"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
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
    mountpoint -q "$d/dev/shm" || mount -t tmpfs ${CHROOT_SHM_SIZE:+-o size=$CHROOT_SHM_SIZE} tmpfs "$d/dev/shm" 2>/dev/null || true
    chmod 1777 "$d/dev/shm" 2>/dev/null || true
    [ -e "$d/dev/fd" ] || ln -s /proc/self/fd "$d/dev/fd" 2>/dev/null || true
    if [ -f "$d/proc/version" ]; then
      log "$d procfs mounted successfully"
    else
      log "WARNING: $d procfs is NOT mounted"
    fi

    if declare -F chroot_extra >/dev/null; then
      chroot_extra "$d" "$name"
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
}

# ---- built-in Postgres ----
# pg_setup /usr/lib/postgresql/<ver>/bin [data dir, default $DATA/postgres]
# then, on a first start:
#   if pg_is_new; then
#     pg_initdb [extra initdb options]      superuser $PG_SUPERUSER (postgres),
#                                           password $PG_PASSWORD
#     pg_start_local                        socket only, no TCP
#     pg_psql -c "CREATE ROLE ..." ...      as the superuser, stops on errors
#     pg_stop_local
#   fi
as_pg() { setpriv --reuid=postgres --regid=postgres --init-groups "$@"; }

pg_setup() {
  PGBIN=$1
  PG_DIR=${2:-$DATA/postgres}
  id postgres >/dev/null
  mkdir -p /run/postgresql
  chown postgres:postgres /run/postgresql "$PG_DIR"
  chmod 700 "$PG_DIR"
}

pg_is_new() { [ ! -s "$PG_DIR/PG_VERSION" ]; }

pg_initdb() {
  local pwfile
  pwfile=$(mktemp)
  printf '%s' "$PG_PASSWORD" > "$pwfile"
  chown postgres:postgres "$pwfile"
  as_pg "$PGBIN/initdb" -D "$PG_DIR" -U "${PG_SUPERUSER:-postgres}" -E UTF8 --locale=C.UTF-8 \
    --auth-host=scram-sha-256 --auth-local=trust --pwfile="$pwfile" "$@" >/dev/null
  rm -f "$pwfile"
}

pg_start_local() {
  as_pg "$PGBIN/pg_ctl" -D "$PG_DIR" \
    -o "-c listen_addresses='' -c unix_socket_directories=/run/postgresql" -w start >/dev/null
}

pg_stop_local() { as_pg "$PGBIN/pg_ctl" -D "$PG_DIR" -w stop >/dev/null; }

pg_psql() {
  as_pg "$PGBIN/psql" -h /run/postgresql -U "${PG_SUPERUSER:-postgres}" -v ON_ERROR_STOP=1 -q "$@"
}
