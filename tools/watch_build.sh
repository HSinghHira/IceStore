#!/usr/bin/env bash
# Wait for an app's GitHub Actions build and report the result in a few lines.
#
#   tools/watch_build.sh <app> [commit-sha]      (sha defaults to HEAD)
#
# Watches build-<app>.yml for that commit (apps built by IceStore), then the
# "Build MOS Hub templates" run (platforms.yml) for the same commit when one
# starts. On a green build it checks ghcr.io/hsinghhira/<app> pulls without a
# login. On a failure it prints only the error lines of the failed steps.
# One blocking call: no need to poll from a chat.
# Exit codes: 0 green, 1 a run failed, 2 usage, 5 no run started, 6 image
# not pullable anonymously.
set -uo pipefail

APP="${1:-}"; [ -n "$APP" ] || { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
ROOT=$(git rev-parse --show-toplevel); cd "$ROOT"
SHA=$(git rev-parse "${2:-HEAD}")
REPO=HSinghHira/IceStore

find_run() { # workflow file, seconds to wait -> run id
  local wf=$1 wait=$2 id="" t=0
  while [ $t -le "$wait" ]; do
    id=$(gh run list -R "$REPO" --workflow "$wf" --commit "$SHA" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null)
    [ -n "$id" ] && { echo "$id"; return 0; }
    sleep 10; t=$((t + 10))
  done
  return 1
}

watch() { # run id, label -> 0 green / 1 failed
  local id=$1 label=$2
  gh run watch "$id" -R "$REPO" --exit-status --interval 30 >/dev/null 2>&1
  local rc=$?
  local info; info=$(gh run view "$id" -R "$REPO" --json conclusion,url -q '.conclusion + " " + .url')
  echo "$label: $info"
  if [ $rc -ne 0 ]; then
    echo "--- error lines ---"
    gh run view "$id" -R "$REPO" --log-failed 2>/dev/null \
      | sed -E 's/^[^\t]*\t[^\t]*\t[0-9TZ:.-]+ //' \
      | grep -iE '::error|error|failed|denied|not found|no such|exit code|unauthorized|manifest unknown' \
      | grep -vE '^\s*$' | tail -40
    return 1
  fi
}

status=0
if [ -f ".github/workflows/build-$APP.yml" ]; then
  if id=$(find_run "build-$APP.yml" 180); then
    watch "$id" "Build $APP" || status=1
  else
    echo "Build $APP: no run for ${SHA:0:7} after 3 min (paths filter not matched, or Actions queued)"; status=5
  fi
  if [ $status -eq 0 ]; then
    tok=$(curl -fsS "https://ghcr.io/token?scope=repository:hsinghhira/$APP:pull" | sed -E 's/.*"token":"([^"]+)".*/\1/')
    code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $tok" \
      -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json' \
      "https://ghcr.io/v2/hsinghhira/$APP/manifests/latest")
    if [ "$code" = 200 ]; then echo "image: ghcr.io/hsinghhira/$APP:latest pulls anonymously"
    else echo "image: ghcr.io/hsinghhira/$APP:latest NOT pullable anonymously (HTTP $code): make the package public"; status=6; fi
  fi
fi

if id=$(find_run platforms.yml 60); then
  watch "$id" "MOS Hub templates" || { [ $status -eq 0 ] && status=1; }
fi
exit $status
