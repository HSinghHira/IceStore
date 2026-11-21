"""Trim the build-appstore-action image caches before a store build.

The action looks up every image's digest and size in its registry, one by one,
which is most of the store build time. It keeps the answers in
.cache/build_appstore/*.json, keyed "<image>|<arch>", and never expires them.
The workflow keeps that folder between runs, so this script first drops every
entry whose tag can move (latest, main, 16-alpine, ...): those are looked up
fresh on every build, the same as without a cache, so a rebuilt :latest image
still reaches the store. Only tags that name an exact release (x.y or a commit
sha) are reused. The workflow also starts a new cache every week.
"""

import json
import re
import sys
from pathlib import Path

CACHE_DIR = Path(".cache/build_appstore")
FILES = {
    "image-digest-cache.json": "image_digest_cache",
    "image-size-cache.json": "image_size_cache",
}
MOVING_WORDS = re.compile(
    r"latest|main|master|stable|edge|nightly|dev|develop|beta|alpha|rc|next|release|canary|preview",
    re.I,
)
EXACT_VERSION = re.compile(r"\d+\.\d+")      # 1.2, v2.14.0, 20.0-20261015
COMMIT_SHA = re.compile(r"^[0-9a-f]{7,40}$")  # 20fb631


def tag_of(key: str) -> str | None:
    image = key.split("|", 1)[0]
    if "@" in image:  # already pinned to a digest, never changes
        return "@"
    last = image.rsplit("/", 1)[-1]
    return last.split(":", 1)[1] if ":" in last else None  # no tag = latest


def is_fixed(key: str) -> bool:
    tag = tag_of(key)
    if tag == "@":
        return True
    if not tag or MOVING_WORDS.search(tag):
        return False
    return bool(EXACT_VERSION.search(tag) or COMMIT_SHA.match(tag))


def main() -> int:
    for name, field in FILES.items():
        path = CACHE_DIR / name
        if not path.exists():
            print(f"{name}: no cache yet, full lookup")
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            entries = data[field]
        except Exception as exc:  # unreadable cache: start over
            print(f"{name}: unreadable ({exc}), removed")
            path.unlink()
            continue
        kept = {k: v for k, v in entries.items() if is_fixed(k)}
        data[field] = kept
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"{name}: kept {len(kept)} fixed-tag entries, dropped {len(entries) - len(kept)} moving ones")
    return 0


if __name__ == "__main__":
    sys.exit(main())
