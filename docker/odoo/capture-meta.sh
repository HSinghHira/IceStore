#!/usr/bin/env bash
# Records each upstream image's start-up config (entrypoint, command, env,
# working dir, user, ports) into ./meta/<name>.json. The Dockerfile copies it in,
# and run-svc.sh uses it to start each service the way its own image would.
# Every "FROM <image> AS img-<name>" line in the Dockerfile is captured.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p meta
expected=$(grep -cE '^FROM .* AS img-' Dockerfile || true)
count=0
while read -r _ image _ stage; do
  name=${stage#img-}
  docker pull -q "$image" >/dev/null
  docker image inspect "$image" --format '{{json .Config}}' > "meta/$name.json"
  echo "meta/$name.json  <-  $image"
  count=$((count + 1))
done < <(grep -E '^FROM [^ ]+ AS img-[a-z0-9]+$' Dockerfile)
[ "$count" -gt 0 ] || { echo "no 'FROM <image> AS img-<name>' lines found in Dockerfile"; exit 1; }
[ "$count" -eq "$expected" ] || {
  echo "captured $count of $expected img- stages. Each must be exactly: FROM <image> AS img-<lowercase name>"
  exit 1
}
