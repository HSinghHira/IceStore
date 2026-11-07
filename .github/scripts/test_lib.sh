#!/usr/bin/env bash
# Tests the parts of docker/_common/lib.sh that need root: prep_chroots and the
# Postgres helpers. Runs on the GitHub runner (it has root and PostgreSQL) in
# every all-in-one build, before the image is built:
#   sudo bash .github/scripts/test_lib.sh
# Skips the Postgres part when no PostgreSQL is installed.
set -euo pipefail
cd "$(dirname "$0")/../.."
[ "$(id -u)" = 0 ] || { echo "run as root (sudo)"; exit 1; }

# Run in a private mount namespace. The host's mounts are shared, so
# unmounting the test's rbind of /sys would also unmount the host's
# /sys/fs/cgroup and break Docker for the rest of the job. A private namespace
# drops every test mount on exit without touching the host.
if [ -z "${TEST_LIB_NS:-}" ]; then
  exec unshare --mount --propagation private env TEST_LIB_NS=1 bash "$0" "$@"
fi

T=$(mktemp -d)
chmod 755 "$T"   # the postgres user must be able to reach $T/data/postgres
cleanup() {
  [ -n "${PGBIN:-}" ] && [ -s "$T/data/postgres/postmaster.pid" ] && pg_stop_local || true
  # safe here: unmounts stay inside this private namespace (see above)
  for m in $(awk -v t="$T" 'index($2, t) == 1 {print $2}' /proc/mounts | sort -r); do umount -l "$m" 2>/dev/null || true; done
  rm -rf --one-file-system "$T" 2>/dev/null || true
}
trap cleanup EXIT

DATA=$T/data ROOTFS=$T/rootfs HOSTS=$T/hosts SECRETS=$T/secrets.env
mkdir -p "$DATA/postgres" "$ROOTFS/demo/etc" "$DATA/demo"
echo "127.0.0.1 localhost demo-host" > "$HOSTS"
: > "$SECRETS"
# shellcheck source=../../docker/_common/lib.sh
. docker/_common/lib.sh

fail() { echo "FAIL: $*"; exit 1; }

echo "== prep_chroots"
chroot_extra() {
  [ "$2" = demo ] || return 0
  mkdir -p "$1/data"
  mount --bind "$DATA/demo" "$1/data"
}
CHROOT_SHM_SIZE=64m prep_chroots
d=$ROOTFS/demo
[ -f "$d/proc/version" ] || fail "proc not mounted"
mountpoint -q "$d/dev/shm" || fail "/dev/shm not mounted"
grep " $d/dev/shm " /proc/mounts | grep -q "size=65536k" || fail "/dev/shm size not applied"
mountpoint -q "$d/data" || fail "chroot_extra did not run"
[ -c "$d/dev/null" ] || fail "/dev/null missing"
[ -p "$d/dev/stdout" ] || fail "/dev/stdout is not a pipe"
grep -q demo-host "$d/etc/hosts" || fail "hosts not copied"
prep_chroots >/dev/null   # a second boot must not fail on existing mounts
echo "ok"

pgbin=$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$pgbin" ]; then
  echo "== Postgres: skipped (no PostgreSQL on this machine)"
  exit 0
fi
echo "== Postgres ($pgbin)"
ensure_secret PG_PASSWORD 16
PG_PASSWORD=$(secret PG_PASSWORD)
pg_setup "$pgbin"
pg_is_new || fail "pg_is_new is false on an empty folder"
pg_initdb --data-checksums
pg_is_new && fail "pg_is_new is still true after pg_initdb"
pg_start_local
pg_psql -v pw="$PG_PASSWORD" <<'SQL'
CREATE ROLE demo LOGIN PASSWORD :'pw';
CREATE DATABASE demo OWNER demo;
SQL
pg_psql -c "CREATE ROLE demo2 LOGIN;" -c "CREATE DATABASE demo2 OWNER demo2;"
[ "$(pg_psql -tA -c "SELECT count(*) FROM pg_database WHERE datname IN ('demo','demo2')")" = 2 ] \
  || fail "databases were not created"
pg_stop_local
echo "ok"
