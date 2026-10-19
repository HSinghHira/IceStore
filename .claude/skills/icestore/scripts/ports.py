#!/usr/bin/env python3
"""List the host ports IceStore apps use and pick the next free 61xx port(s).

    python3 ports.py --repo /path/to/IceStore          # a local checkout
    python3 ports.py                                   # download HSinghHira/IceStore from GitHub
    python3 ports.py --repo . --count 2                # next 2 free ports in a row

The ports come straight from every Apps/*/docker-compose.yml (published ports
and x-casaos.port_map), so there is no ledger file to keep in sync.
"""
import argparse
import io
import re
import sys
import tarfile
import urllib.request
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("pyyaml is missing: pip install pyyaml --break-system-packages")

REPO = "HSinghHira/IceStore"
LOW, HIGH = 6101, 6199
SOURCES = [
    f"https://codeload.github.com/{REPO}/tar.gz/refs/heads/main",
    f"https://github.com/{REPO}/archive/refs/heads/main.tar.gz",
]


def ports_of(raw):
    data = yaml.safe_load(raw) or {}
    found = set()
    for svc in (data.get("services") or {}).values():
        for p in (svc or {}).get("ports") or []:
            if isinstance(p, dict):
                v = p.get("published")
            else:
                parts = str(p).split("/")[0].split(":")
                v = parts[-2] if len(parts) > 1 else None
            if v not in (None, ""):
                found.add(str(v))
    pm = (data.get("x-casaos") or {}).get("port_map")
    if pm not in (None, ""):
        found.add(str(pm))
    return sorted(found, key=lambda x: int(x) if x.isdigit() else 0)


def from_local(root):
    apps = {}
    for f in sorted(Path(root, "Apps").glob("*/docker-compose.y*ml")):
        apps[f.parent.name] = ports_of(f.read_text(encoding="utf-8-sig"))
    return apps


def from_github():
    last = None
    for url in SOURCES:
        try:
            with urllib.request.urlopen(url, timeout=30) as r:
                blob = r.read()
        except Exception as ex:  # try the next source
            last = ex
            continue
        apps = {}
        with tarfile.open(fileobj=io.BytesIO(blob), mode="r:gz") as tar:
            for m in tar.getmembers():
                parts = m.name.split("/")
                if len(parts) == 4 and parts[1] == "Apps" and re.fullmatch(r"docker-compose\.ya?ml", parts[3]):
                    apps[parts[2]] = ports_of(tar.extractfile(m).read().decode("utf-8-sig"))
        return apps
    raise SystemExit(
        f"could not download {REPO} ({last}).\n"
        "Clone the repo and pass --repo, or ask the user for the list of ports in use.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", help="path to a local IceStore checkout")
    ap.add_argument("--count", type=int, default=1, help="how many ports in a row the new app needs")
    args = ap.parse_args()

    apps = from_local(args.repo) if args.repo else from_github()
    owner = {}
    problems = []
    print("App ports in use:")
    for app, ports in sorted(apps.items(), key=lambda kv: (kv[1] or ["0"])[0]):
        print(f"  {app:<28} {', '.join(ports) or '(no published port)'}")
        for p in ports:
            if not p.isdigit():
                problems.append(f"{app}: port '{p}' is not a number (a $PORT variable?)")
                continue
            if not LOW <= int(p) <= HIGH:
                problems.append(f"{app}: port {p} is outside {LOW}-{HIGH}")
            if p in owner and owner[p] != app:
                problems.append(f"port {p} is used by both {owner[p]} and {app}")
            owner.setdefault(p, app)

    used = {int(p) for p in owner if p.isdigit()}
    start = None
    for p in range(LOW, HIGH - args.count + 2):
        if all(q not in used for q in range(p, p + args.count)):
            start = p
            break
    print()
    for msg in problems:
        print(f"WARNING: {msg}")
    if start is None:
        sys.exit(f"no {args.count} free port(s) in a row left in {LOW}-{HIGH}; ask the user which range to use next")
    block = ", ".join(str(p) for p in range(start, start + args.count))
    print(f"Next free: {block}")


if __name__ == "__main__":
    main()
