#!/usr/bin/env python3
"""Bump the upstream images that IceStore's all-in-one apps are built from.

For every docker/<app>/Dockerfile, each pinned `FROM image:tag` line is checked
against its registry. A newer tag is taken only when it has the same shape as
the current one (0.19.2 -> 0.19.3, v1.31.4 -> v1.32.0, RELEASE.<date> -> a later
date), so betas, nightlies and `latest` are never picked up. Tags with no digits
(debian:trixie-slim) are base images and are left alone.

Images that only publish `latest` plus one tag per git commit (ghcr.io/ente/*)
are pinned to a 40-character commit tag, or a `sha-<short sha>` tag
(ghcr.io/benno93/*). Those follow `latest`: when `latest`
points somewhere else, the line moves to the commit tag with the same digest.
For them, `version:` in the compose file may be the first 7 characters of the
main image's commit tag.

To keep an image where it is, put this comment on the line above its FROM:
    # auto-update: hold
To take newer tags only while the first number stays the same (odoo
20.0-20261015 -> 20.0-20261101, never 21.0-...), put this one there instead:
    # auto-update: keep-major

When something changes in an app, this also:
  - raises the patch number of AIO_VERSION in .github/workflows/build-<app>.yml
  - in Apps/<app>/docker-compose.yml: sets `version:` when the main image moved
    (the FROM line whose tag equals the current `version:`), sets `update_at:`
    to today, adds a release-notes line and refreshes "<image> <tag>" mentions

Usage: update_upstream.py [--write] [--repo DIR]
Without --write it only prints what it would change. With GITHUB_OUTPUT set it
writes `apps=<space separated app names>` and `summary=<one line>` there.
"""

import argparse
import datetime
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

FROM_RE = re.compile(r"^(FROM\s+(?:--platform=\S+\s+)?)(\S+?):([^\s@]+)(\s.*)?$")
HOLD_RE = re.compile(r"#\s*auto-update:\s*hold", re.I)
KEEP_MAJOR_RE = re.compile(r"#\s*auto-update:\s*keep-major", re.I)
NUM_RE = re.compile(r"\d+")
# Per-commit tags: a full 40-character sha (ghcr.io/ente/*) or the
# `sha-<short sha>` tags docker/metadata-action makes. Both follow `latest`.
COMMIT_RE = re.compile(r"^(?:[0-9a-f]{40}|sha-[0-9a-f]{7,40})$")
MANIFEST_TYPES = ", ".join([
    "application/vnd.oci.image.index.v1+json",
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.oci.image.manifest.v1+json",
    "application/vnd.docker.distribution.manifest.v2+json",
])


# ---------------------------------------------------------------- registry ---

def split_image(image):
    """'appflowyinc/gotrue' -> ('registry-1.docker.io', 'appflowyinc/gotrue')."""
    first, _, rest = image.partition("/")
    if rest and ("." in first or ":" in first or first == "localhost"):
        return first, rest
    if not rest:
        return "registry-1.docker.io", "library/" + image
    return "registry-1.docker.io", image


def http_get(url, token=None):
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    if token:
        req.add_header("Authorization", "Bearer " + token)
    return urllib.request.urlopen(req, timeout=30)


def get_token(registry, repo):
    """Anonymous pull token, found from the registry's WWW-Authenticate header."""
    try:
        http_get(f"https://{registry}/v2/")
        return None
    except urllib.error.HTTPError as e:
        challenge = e.headers.get("WWW-Authenticate", "")
    params = dict(re.findall(r'(\w+)="([^"]*)"', challenge))
    if "realm" not in params:
        return None
    query = {"scope": f"repository:{repo}:pull"}
    if "service" in params:
        query["service"] = params["service"]
    with http_get(params["realm"] + "?" + urllib.parse.urlencode(query)) as r:
        data = json.load(r)
    return data.get("token") or data.get("access_token")


def list_tags(image):
    registry, repo = split_image(image)
    token = get_token(registry, repo)
    url = f"https://{registry}/v2/{repo}/tags/list?n=1000"
    tags = []
    while url:
        with http_get(url, token) as r:
            tags += json.load(r).get("tags") or []
            link = r.headers.get("Link", "")
        m = re.search(r"<([^>]+)>", link)
        url = urllib.parse.urljoin(f"https://{registry}", m.group(1)) if m else None
    return tags


def digest(registry, repo, tag, token):
    req = urllib.request.Request(f"https://{registry}/v2/{repo}/manifests/{tag}", method="HEAD",
                                 headers={"Accept": MANIFEST_TYPES})
    if token:
        req.add_header("Authorization", "Bearer " + token)
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.headers.get("Docker-Content-Digest")


def follow_latest(image, current):
    """For commit-tagged images: the commit tag `latest` points at, if it moved."""
    registry, repo = split_image(image)
    token = get_token(registry, repo)
    target = digest(registry, repo, "latest", token)
    if not target or digest(registry, repo, current, token) == target:
        return None
    for tag in reversed(list_tags(image)):
        if tag != current and COMMIT_RE.match(tag) and digest(registry, repo, tag, token) == target:
            return tag
    raise RuntimeError("no commit tag has the same digest as latest")


# -------------------------------------------------------------------- tags ---

def shape(tag):
    """Regex that matches tags laid out like `tag`, with any numbers."""
    return re.compile("^" + r"\d+".join(re.escape(p) for p in NUM_RE.split(tag)) + "$")


def key(tag):
    return tuple(int(n) for n in NUM_RE.findall(tag))


def newest(image, current, keep_major=False):
    pattern = shape(current)
    candidates = [t for t in list_tags(image) if pattern.match(t)]
    if keep_major:
        candidates = [t for t in candidates if key(t)[:1] == key(current)[:1]]
    best = max(candidates, key=key, default=current)
    return best if key(best) > key(current) else None


# ------------------------------------------------------------------- files ---

def update_dockerfile(path):
    """Return [(image, old, new)] and the new text."""
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    changes = []
    for i, line in enumerate(lines):
        m = FROM_RE.match(line.rstrip("\n"))
        if not m:
            continue
        prefix, image, tag, rest = m.group(1), m.group(2), m.group(3), m.group(4) or ""
        if not NUM_RE.search(tag) or tag == "latest":
            continue
        if i > 0 and HOLD_RE.search(lines[i - 1]):
            print(f"  hold  {image}:{tag}")
            continue
        try:
            keep_major = i > 0 and bool(KEEP_MAJOR_RE.search(lines[i - 1]))
            new = follow_latest(image, tag) if COMMIT_RE.match(tag) else newest(image, tag, keep_major)
        except Exception as e:  # one bad registry should not stop the others
            print(f"  WARN  {image}: could not list tags ({e})", file=sys.stderr)
            continue
        if new:
            print(f"  bump  {image}: {tag} -> {new}")
            lines[i] = f"{prefix}{image}:{new}{rest}\n"
            changes.append((image, tag, new))
        else:
            print(f"  ok    {image}:{tag}")
    return changes, "".join(lines)


def bump_aio_version(text):
    def repl(m):
        major, minor, patch = m.group(2).split(".")
        return f'{m.group(1)}{major}.{minor}.{int(patch) + 1}"'
    return re.sub(r'(AIO_VERSION:\s*")(\d+\.\d+\.\d+)"', repl, text, count=1)


def update_compose(text, changes, today):
    m = re.search(r'^  version:\s*"([^"]*)"', text, re.M)
    current_version = m.group(1) if m else None
    for image, old, new in changes:
        short = (COMMIT_RE.match(old) and current_version and len(current_version) >= 7
                 and old.startswith(current_version))
        if old == current_version or short:
            value = new[:len(current_version)] if short else new
            text = re.sub(r'^(  version:\s*)"[^"]*"', rf'\g<1>"{value}"', text, count=1, flags=re.M)
            current_version = None
        pairs = [(old, new)] + ([(old[:7], new[:7])] if COMMIT_RE.match(old) else [])
        for name in {image, image.rsplit("/", 1)[-1]}:
            for o, n in pairs:
                text = re.sub(rf"(?<![\w/.-]){re.escape(name)} {re.escape(o)}(?![\w.])", f"{name} {n}", text)
    text = re.sub(r'^(  update_at:\s*)"[^"]*"', rf'\g<1>"{today}"', text, count=1, flags=re.M)
    def show(tag):
        return tag[:7] if COMMIT_RE.match(tag) else tag
    note = "Updated " + ", ".join(f"{i.rsplit('/', 1)[-1]} {show(o)} to {show(n)}" for i, o, n in changes)
    text = re.sub(r"^(  release_notes:\n    en_US: \|-?\n)", rf"\g<1>      - {note}\n", text, count=1, flags=re.M)
    return text, note


# -------------------------------------------------------------------- main ---

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=".")
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()
    repo = Path(args.repo)
    today = datetime.date.today().isoformat()

    changed, notes = [], []
    for dockerfile in sorted(repo.glob("docker/*/Dockerfile")):
        app = dockerfile.parent.name
        print(f"{app}:")
        changes, new_dockerfile = update_dockerfile(dockerfile)
        if not changes:
            continue
        workflow = repo / ".github/workflows" / f"build-{app}.yml"
        compose = repo / "Apps" / app / "docker-compose.yml"
        new_compose, note = update_compose(compose.read_text(encoding="utf-8"), changes, today)
        changed.append(app)
        notes.append(f"{app}: {note.removeprefix('Updated ')}")
        if args.write:
            dockerfile.write_text(new_dockerfile, encoding="utf-8")
            workflow.write_text(bump_aio_version(workflow.read_text(encoding="utf-8")), encoding="utf-8")
            compose.write_text(new_compose, encoding="utf-8")

    summary = "; ".join(notes) if notes else "no upstream updates"
    print("\n" + summary)
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as f:
            f.write(f"apps={' '.join(changed)}\nsummary={summary}\n")


if __name__ == "__main__":
    main()
