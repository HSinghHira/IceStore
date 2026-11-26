"""Write starter files for a new IceStore app from the icestore skill templates.

    python tools/new_app.py <spec.yml> [--force]

spec.yml (only `app`, `kind` and `title` are required):

    app: vikunja                  # Apps/ folder name, lowercase
    kind: simple                  # simple | wrapper | aio
    title: Vikunja
    port: 6874                    # default: python tools/free_port.py --claim <app>
    upstream_image: vikunja/vikunja
    upstream_tag: 0.24.6
    container_port: 3456
    data_path: /app/vikunja/files
    category: Productivity
    developer: Vikunja
    tagline: Open-source to-do lists and kanban boards
    pitch: Vikunja is a to-do app ...
    repo_url: https://github.com/go-vikunja/vikunja
    docs_url: https://vikunja.io/docs
    homepage_url: https://vikunja.io
    health_path: /health          # aio only

Writes:
  simple   Apps/<app>/docker-compose.yml, Apps/<app>/README.md
  wrapper  the same + docker/<app>/{Dockerfile,VERSION,icestore-init.sh}
           + .github/workflows/build-<app>.yml (kind: wrapper)
  aio      the same layout from templates/aio + docker-compose.aio.yml

Every __PLACEHOLDER__ the spec does not fill stays in the files. The script
prints the ones left, per file: fill them in, then run the checker. It never
overwrites an existing app unless --force is given.
"""
import argparse, datetime, os, re, shutil, subprocess, sys

import yaml

ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip()
TPL = os.path.join(ROOT, ".claude", "skills", "icestore", "templates")

KEYS = {  # spec key -> placeholder
    "app": "__APP__", "title": "__TITLE__", "port": "__PORT__", "upstream_image": "__UPSTREAM_IMAGE__",
    "upstream_tag": "__UPSTREAM_TAG__", "container_port": "__CONTAINER_PORT__", "data_path": "__DATA_PATH__",
    "category": "__CATEGORY__", "developer": "__DEVELOPER__", "tagline": "__TAGLINE__", "pitch": "__PITCH__",
    "repo_url": "__REPO_URL__", "docs_url": "__DOCS_URL__", "homepage_url": "__HOMEPAGE_URL__",
    "health_path": "__HEALTH_PATH__", "app_prefix": "__APP_PREFIX__", "internal_port": "__APP_INTERNAL_PORT__",
}

WRAPPER_DOCKERFILE = """# syntax=docker/dockerfile:1.7
#
# __TITLE__, as upstream ships it, plus one IceStore start script that gives
# every install its own secrets (made on first start, kept in /config).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM __UPSTREAM_IMAGE__:__UPSTREAM_TAG__

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="__APP__" \\
      org.opencontainers.image.description="__TITLE__ for IceStore" \\
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
# __UPSTREAM_CMD__: hand over to upstream's own entrypoint/cmd at the end of icestore-init.sh
"""

WRAPPER_INIT = """#!/bin/sh
# IceStore start script for __TITLE__. Makes this install's secrets once and
# keeps them in /config, then hands over to upstream's own start command.
#   - A secret set in the app settings is used and saved to its file.
#   - Blank or missing: the saved one is used, or a new one is made.
set -eu

DIR=${ICESTORE_DIR:-/config}
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DIR"
# make_secret NAME BYTES: NAME from the app settings, the saved file, or new.
make_secret() {
  _f="$DIR/.icestore-$(echo "$1" | tr 'A-Z_' 'a-z-')"
  eval "_v=\\${$1:-}"
  ( umask 077
    if [ -n "$_v" ]; then
      printf '%s' "$_v" > "$_f.tmp" && mv "$_f.tmp" "$_f"
    elif [ ! -s "$_f" ]; then
      head -c "$2" /dev/urandom | od -An -tx1 | tr -d ' \\n' > "$_f.tmp" && mv "$_f.tmp" "$_f"
      log "first start: made $1 ($_f)"
    fi )
  eval "$1=\\$(cat \\"\\$_f\\")"
  export "$1"
}

# __SECRETS__: make_secret __APP_PREFIX___SECRET_KEY 32

exec __UPSTREAM_CMD__ "$@"
"""


def fill(text, spec):
    for k, ph in KEYS.items():
        if spec.get(k) not in (None, ""):
            text = text.replace(ph, str(spec[k]))
    return text.replace("__DATE__", datetime.date.today().isoformat())


def write(path, text, created):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    created.append(path)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    spec = yaml.safe_load(open(a.spec, encoding="utf-8")) or {}
    for k in ("app", "kind", "title"):
        if not spec.get(k):
            sys.exit(f"spec needs `{k}`")
    app, kind = spec["app"], spec["kind"]
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", app):
        sys.exit("app must be lowercase letters, digits and hyphens")
    if kind not in ("simple", "wrapper", "aio"):
        sys.exit("kind must be simple, wrapper or aio")
    if os.path.exists(os.path.join(ROOT, "Apps", app)) and not a.force:
        sys.exit(f"Apps/{app} exists; use --force to overwrite")
    spec.setdefault("app_prefix", app.upper().replace("-", "_"))
    if not spec.get("port"):
        out = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "free_port.py"), "--claim", app],
                             capture_output=True, text=True, cwd=ROOT)
        if out.returncode:
            sys.exit(out.stderr)
        spec["port"] = out.stdout.split()[0]

    created = []
    rd = lambda *p: open(os.path.join(TPL, *p), encoding="utf-8").read()
    compose = rd("docker-compose.aio.yml") if kind == "aio" else rd("docker-compose.simple.yml")
    if kind != "simple":  # IceStore builds the image
        compose = compose.replace("__UPSTREAM_IMAGE__:__UPSTREAM_TAG__", "ghcr.io/hsinghhira/__APP__:latest")
    write(os.path.join(ROOT, "Apps", app, "docker-compose.yml"), fill(compose, spec), created)
    write(os.path.join(ROOT, "Apps", app, "README.md"), fill(rd("README.md"), spec), created)

    if kind != "simple":
        d = os.path.join(ROOT, "docker", app)
        if kind == "aio":
            for f in sorted(os.listdir(os.path.join(TPL, "aio"))):
                write(os.path.join(d, f), fill(rd("aio", f), spec), created)
        else:
            write(os.path.join(d, "Dockerfile"), fill(WRAPPER_DOCKERFILE, spec), created)
            write(os.path.join(d, "icestore-init.sh"), fill(WRAPPER_INIT, spec), created)
        write(os.path.join(d, "VERSION"), "1.0.0\n", created)
        wf = fill(rd("build-workflow.yml"), spec)
        if kind == "wrapper":
            wf = wf.rstrip("\n") + "\n      kind: wrapper\n"
        write(os.path.join(ROOT, ".github", "workflows", f"build-{app}.yml"), wf, created)

    print(f"{kind} app {app} on port {spec['port']}: wrote")
    left_total = 0
    for p in created:
        left = sorted(set(re.findall(r"__[A-Z0-9_]+__", open(p, encoding="utf-8").read())))
        left_total += len(left)
        print(f"  {os.path.relpath(p, ROOT)}" + (f"  (fill: {', '.join(left)})" if left else ""))
    print(f"\n{left_total} placeholder(s) left. Then: python .claude/skills/icestore/scripts/check_app.py . {app}")


if __name__ == "__main__":
    main()
