#!/usr/bin/env bash
# move_pin.sh <app> <version>
#
# Run by build-image.yml after the image has been pushed. An app whose compose
# file pins its own image to a version (ghcr.io/hsinghhira/<app>:1.2.3 instead of
# :latest, so ZimaOS fetches the new image even when it holds an older one) gets
# that pin moved to <version> here, and only here: a build that fails never
# points installs at a tag that does not exist.
#
# The pin only moves forward, a `<version>-<commit>` rollback pin is left alone,
# and apps on :latest are skipped. The commit is made with GITHUB_TOKEN, which
# starts no workflows, so the store, the MOS templates and the README pictures
# are started here with `gh workflow run`.
set -euo pipefail

app=$1
version=$2
compose="Apps/$app/docker-compose.yml"
owner=${GITHUB_REPOSITORY_OWNER,,}
pin_re="image:[[:space:]]*ghcr\.io/$owner/$app:[0-9]+\.[0-9]+\.[0-9]+([^0-9A-Za-z.-]|$)"

[ -f "$compose" ] || { echo "No $compose; nothing to pin."; exit 0; }
grep -Eq "$pin_re" "$compose" || { echo "$app is not pinned to a version; nothing to move."; exit 0; }

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

for attempt in 1 2 3 4 5; do
  git fetch -q --depth=1 origin main
  git checkout -q -B pin-move FETCH_HEAD
  current=$(grep -Eo "ghcr\.io/$owner/$app:[0-9]+\.[0-9]+\.[0-9]+" "$compose" | head -1 | sed 's/.*://')
  if [ -z "$current" ]; then
    echo "The pin is gone from main; leaving it."; exit 0
  fi
  if [ "$current" = "$version" ]; then
    echo "Already pinned to $version."; exit 0
  fi
  if [ "$(printf '%s\n%s\n' "$current" "$version" | sort -V | tail -1)" != "$version" ]; then
    echo "main pins $current, newer than $version; leaving it."; exit 0
  fi
  sed -E -i "s#(image:[[:space:]]*ghcr\.io/$owner/$app:)$current([^0-9A-Za-z.-]|\$)#\1$version\2#" "$compose"
  git add "$compose"
  git commit -q -m "$app: pin image $version" -m "Moved by build-image.yml after ghcr.io/$owner/$app:$version was pushed."
  if git push -q origin HEAD:main; then
    echo "Pinned $app to $version (was $current)."
    for wf in release-store.yml platforms.yml update-readme-svgs.yml; do
      gh workflow run "$wf" --ref main || echo "::warning::Could not start $wf; run it by hand."
    done
    exit 0
  fi
  echo "Push lost a race (attempt $attempt); retrying."
  sleep $((RANDOM % 10 + 5))
done

echo "::error::Could not push the pin for $app after 5 attempts. Set image: ghcr.io/$owner/$app:$version in $compose by hand."
exit 1
