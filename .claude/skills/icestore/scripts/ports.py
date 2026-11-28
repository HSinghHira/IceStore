#!/usr/bin/env python3
"""List the host ports IceStore apps use and pick the next free 61xx port(s).

    python3 ports.py --repo /path/to/IceStore          # a local checkout
    python3 ports.py                                   # download HSinghHira/IceStore from GitHub
    python3 ports.py --repo . --count 2                # next 2 free ports in a row
    python3 ports.py --repo . --block                  # next free 30-port block in 66xx

Apps with many ports (more than about 4) get a block of 30 in 6600-6699
instead of using up 61xx: 6600, 6630, 6660, 6690 (Ente uses the first three).

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
BLOCK_LOW, BLOCK_HIGH, BLOCK = 6600, 6699, 30
# 61xx is full (Nov 2026): single apps continue here, after the Ente blocks,
# then on into 6800-6899. When that filled up (Nov 2026) the user opened 7000-7099.
NEXT_LOW, NEXT_HIGH = 6690, 6899
THEN_LOW, THEN_HIGH = 7000, 7099
FIXED_PORTS = {"53"}  # DNS servers (KyDNS): clients can't use another port
# Ports Chrome, Edge and Firefox refuse to open (ERR_UNSAFE_PORT), from
# Chromium's kRestrictedPorts list. KyDNS on 6697 hit this in Nov 2026.
BROWSER_BLOCKED = {1719, 1720, 1723, 2049, 3659, 4045, 4190, 5060, 5061, 6000, 6566,
                   6665, 6666, 6667, 6668, 6669, 6679, 6697, 10080}
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
        # Ports a helper container publishes for the app (Dokploy's Traefik)
        # show up only as *_PORT=61xx settings.
        env = (svc or {}).get("environment") or []
        items = env.items() if isinstance(env, dict) else (str(e).partition("=")[::2] for e in env)
        for k, v in items:
            v = str(v or "").strip('"')
            if str(k).endswith("_PORT") and v.isdigit() and LOW <= int(v) <= BLOCK_HIGH:
                found.add(v)
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
    ap.add_argument("--block", action="store_true", help="find the next free 30-port block in 6600-6699")
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
            if p not in FIXED_PORTS and not (LOW <= int(p) <= HIGH or BLOCK_LOW <= int(p) <= NEXT_HIGH
                                             or THEN_LOW <= int(p) <= THEN_HIGH):
                problems.append(f"{app}: port {p} is outside {LOW}-{HIGH}, {BLOCK_LOW}-{NEXT_HIGH} and {THEN_LOW}-{THEN_HIGH}")
            if int(p) in BROWSER_BLOCKED:
                problems.append(f"{app}: port {p} is blocked by browsers (ERR_UNSAFE_PORT)")
            if p in owner and owner[p] != app:
                problems.append(f"port {p} is used by both {owner[p]} and {app}")
            owner.setdefault(p, app)

    used = {int(p) for p in owner if p.isdigit()}
    free = lambda p: all(q not in used and q not in BROWSER_BLOCKED for q in range(p, p + args.count))
    if args.block:
        print()
        for msg in problems:
            print(f"WARNING: {msg}")
        for b in range(BLOCK_LOW, BLOCK_HIGH + 1, BLOCK):
            if not any(b <= q < b + BLOCK for q in used | BROWSER_BLOCKED):
                print(f"Next free block: {b}-{min(b + BLOCK - 1, BLOCK_HIGH)}")
                return
        sys.exit(f"no free block left in {BLOCK_LOW}-{BLOCK_HIGH}; ask the user which range to use next")
    start = None
    for p in range(LOW, HIGH - args.count + 2):
        if free(p):
            start = p
            break
    print()
    for msg in problems:
        print(f"WARNING: {msg}")
    for lo, hi in ((NEXT_LOW, NEXT_HIGH), (THEN_LOW, THEN_HIGH)):
        if start is not None:
            break
        for p in range(lo, hi - args.count + 2):
            if free(p):
                start = p
                break
    if start is None:
        sys.exit(f"no {args.count} free port(s) in a row left in {LOW}-{HIGH}, {NEXT_LOW}-{NEXT_HIGH} or {THEN_LOW}-{THEN_HIGH}; ask the user which range to use next")
    block = ", ".join(str(p) for p in range(start, start + args.count))
    print(f"Next free: {block}")


if __name__ == "__main__":
    main()
