#!/usr/bin/env bash
# Trial run of an all-in-one app's start-up, with no Docker and no root.
#   bash .github/scripts/dry_run.sh <app>      (from the repo root; `just test <app>`)
# Runs docker/<app>/aio-init.sh twice (first boot, then a restart on the same
# data) with AIO_DRY_RUN=1, then checks what it wrote and prints the
# CREDENTIALS banner. Build workflows run it before building, so a broken
# change (in the app or in docker/_common) never reaches the registry.
set -euo pipefail

app=${1:?usage: dry_run.sh <app>}
cd "$(dirname "$0")/../.."
src=docker/$app
[ -f "$src/aio-init.sh" ] || { echo "no $src/aio-init.sh"; exit 1; }

D=$(mktemp -d)
trap 'rm -rf "$D"' EXIT
mkdir -p "$D/data" "$D/rootfs" "$D/run" "$D/meta"
cp /etc/hosts "$D/hosts" 2>/dev/null || echo "127.0.0.1 localhost" > "$D/hosts"

export AIO_DATA=$D/data AIO_ROOTFS=$D/rootfs AIO_META=$D/meta AIO_RUN=$D/run \
  AIO_HOSTS=$D/hosts AIO_NGINX_TPL=$src/nginx.conf.tpl AIO_NGINX_OUT=$D/nginx.conf \
  AIO_DRY_RUN=1 AIO_LIB=docker/_common/lib.sh AIO_CRED_FILE=$D/credentials

# Other folders the app takes as ${AIO_<NAME>:-/path} (/books, /media, ...)
# also go under $D, so the trial run needs no root.
for v in $(grep -oE '\$\{AIO_[A-Z_]+:-/' "$src/aio-init.sh" | sed -E 's/^\$\{(AIO_[A-Z_]+):-\/$/\1/' | sort -u); do
  [ -n "${!v:-}" ] || { mkdir -p "$D/extra/$v"; export "$v=$D/extra/$v"; }
done

fail() { echo "FAIL ($app): $*"; exit 1; }

# Services that run-svc starts from their own image need /run/aio/<name>.env:
# every img-<name> stage that also has a [program:<name>].
programs=$(sed -n 's/^\[program:\([A-Za-z0-9_-]*\)\]$/\1/p' "$src/supervisord.conf")
stages=$(sed -n 's/^FROM [^ ]* AS img-\([a-z0-9]*\)$/\1/p' "$src/Dockerfile")

for boot in first restart; do
  echo "== $app: $boot boot"
  rm -f "$D"/run/*.env
  bash "$src/aio-init.sh" || fail "aio-init.sh exited with an error on the $boot boot"

  for s in $stages; do
    if printf '%s\n' "$programs" | grep -qx "$s"; then
      [ -f "$D/run/$s.env" ] || fail "no env file for service $s on the $boot boot"
    fi
  done
  if grep -q '@[A-Z_]*@' "$D/nginx.conf"; then
    fail "nginx.conf still has $(grep -o '@[A-Z_]*@' "$D/nginx.conf" | sort -u | tr '\n' ' ')"
  fi
  if grep -q '^\[program:credentials\]' "$src/supervisord.conf"; then
    [ -s "$D/credentials" ] || fail "the CREDENTIALS banner is empty on the $boot boot"
    CRED_WAIT_SECONDS=0 bash docker/_common/credentials.sh || fail "credentials.sh exited with an error"
  fi
done

echo "OK ($app)"
