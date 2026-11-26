#!/usr/bin/env bash
# Ship one IceStore app: check it, commit only its own files, rebase, push.
#
#   tools/ship_app.sh <app> [--message "Add Foo (port 6874)"] [--dry-run]
#
# What it stages, and nothing else:
#   Apps/<app>/  docker/<app>/  .github/workflows/build-<app>.yml
# README.md, readme/*.svg and the MOS files (maintainer.json, compose/,
# docker/*.json) are left alone: update-readme-svgs.yml and platforms.yml
# rewrite them on main after the push.
#
# Default message: "Add <Title> (port <port_map>)" for a new app, else
# "Update <Title>". Exit codes: 0 pushed (or dry run ok), 1 check failed,
# 2 usage, 3 nothing to ship, 4 git refused (dirty tree, conflict, push).
set -euo pipefail

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

APP="" MSG="" DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --message|-m) MSG="${2:?--message needs text}"; shift 2 ;;
    --dry-run|-n) DRY=1; shift ;;
    -h|--help) usage ;;
    -*) echo "unknown option $1" >&2; usage ;;
    *) [ -z "$APP" ] || usage; APP="$1"; shift ;;
  esac
done
[ -n "$APP" ] || usage

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"
PY=$(command -v python3 || command -v python)
[ -d "Apps/$APP" ] || { echo "no Apps/$APP folder" >&2; exit 2; }

echo "== check Apps/$APP"
"$PY" .claude/skills/icestore/scripts/check_app.py . "$APP" || { echo "checker found errors: fix them first" >&2; exit 1; }

echo "== MOS preview"
if ! "$PY" platforms/generate.py --check --app "$APP" >/dev/null; then
  echo "MOS generator reports an error for $APP; see _platforms/report.md" >&2
  grep -n -i -A3 "$APP" _platforms/report.md 2>/dev/null | head -20 >&2 || true
  exit 1
fi

PATHS=("Apps/$APP")
[ -d "docker/$APP" ] && PATHS+=("docker/$APP")
[ -f ".github/workflows/build-$APP.yml" ] && PATHS+=(".github/workflows/build-$APP.yml")

if [ -z "$MSG" ]; then
  INFO=$("$PY" - "$APP" <<'EOF'
import sys, yaml
d = yaml.safe_load(open(f"Apps/{sys.argv[1]}/docker-compose.yml", encoding="utf-8"))
x = d.get("x-casaos", {})
print((x.get("title") or {}).get("en_US") or sys.argv[1])
print(x.get("port_map", "-"))
EOF
)
  TITLE=$(printf '%s\n' "$INFO" | sed -n 1p | tr -d '\r')
  PORT=$(printf '%s\n' "$INFO" | sed -n 2p | tr -d '\r')
  if git cat-file -e "origin/main:Apps/$APP/docker-compose.yml" 2>/dev/null; then
    MSG="Update $TITLE"
  else
    MSG="Add $TITLE (port $PORT)"
  fi
fi

CHANGES=$(git status --porcelain -- "${PATHS[@]}")
[ -n "$CHANGES" ] || { echo "nothing to ship for $APP"; exit 3; }
echo "== files"
echo "$CHANGES"
echo "== message: $MSG"

if [ "$DRY" = 1 ]; then
  echo "dry run: nothing committed or pushed"
  exit 0
fi

# Never touch anything outside this app: commit only these paths, even if
# other files are already staged by someone else.
git add -- "${PATHS[@]}"
git commit --quiet -m "$MSG" -- "${PATHS[@]}"

push() {
  git pull --rebase --quiet origin main || { echo "rebase failed: resolve it (git status), then push" >&2; git rebase --abort 2>/dev/null || true; exit 4; }
  git push --quiet origin HEAD:main
}
push || { echo "push rejected, retrying once"; push || exit 4; }

SHA=$(git rev-parse HEAD)
echo "== pushed $SHA ($MSG)"
echo "next: tools/watch_build.sh $APP $SHA"
