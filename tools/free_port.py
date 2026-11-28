"""Next free IceStore port(s), also skipping ports held by apps still being built.

    python tools/free_port.py [--count N] [--claim <app>]

ports.py (the icestore skill) only sees apps already in Apps/. When several
apps are built at once, each in its own git worktree, a port can be taken by a
worktree that has not been pushed yet. This script also reads:
  - .task/queue.md lines like `vikunja | coding | port 6874 | note`
  - Apps/*/docker-compose.yml in every git worktree of this repo
--claim <app> writes the port into that app's queue line (adding the line if
it is missing), so the next call skips it.
"""
import argparse, os, re, subprocess, sys

ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip()
MAIN = subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"], capture_output=True, text=True,
                      cwd=ROOT, check=True).stdout.strip()
MAIN_ROOT = os.path.dirname(MAIN) if os.path.basename(MAIN) == ".git" else ROOT
QUEUE = os.path.join(MAIN_ROOT, ".task", "queue.md")
PORTS_PY = os.path.join(ROOT, ".claude", "skills", "icestore", "scripts", "ports.py")


def ports_in(text):
    return {int(p) for p in re.findall(r'(?:published|port_map)\s*:\s*"?(\d{4,5})', text)}


def held_ports():
    held = set()
    if os.path.exists(QUEUE):
        for line in open(QUEUE, encoding="utf-8"):
            held |= {int(p) for p in re.findall(r"port[s]?\s+([\d, ]+)", line) for p in re.findall(r"\d{4,5}", p)}
    out = subprocess.run(["git", "worktree", "list", "--porcelain"], capture_output=True, text=True, cwd=ROOT).stdout
    for wt in re.findall(r"^worktree (.+)$", out, re.M):
        apps = os.path.join(wt, "Apps")
        if not os.path.isdir(apps):
            continue
        for a in os.listdir(apps):
            f = os.path.join(apps, a, "docker-compose.yml")
            if os.path.exists(f):
                held |= ports_in(open(f, encoding="utf-8", errors="ignore").read())
    return held


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=1)
    ap.add_argument("--claim", metavar="APP")
    a = ap.parse_args()
    out = subprocess.run([sys.executable, PORTS_PY, "--repo", ROOT, "--count", "1"], capture_output=True, text=True)
    m = re.search(r"Next free:\s*(\d+)", out.stdout)
    if not m:
        sys.exit("ports.py gave no 'Next free' line:\n" + out.stdout + out.stderr)
    held, p = held_ports(), int(m.group(1))
    while any(q in held for q in range(p, p + a.count)):
        p += 1
    if 6899 < p + a.count - 1 < 7000:
        p = 7000
        while any(q in held for q in range(p, p + a.count)):
            p += 1
    if p + a.count - 1 > 7099:
        sys.exit("7000-7099 is full: open a new range in ports.py and check_app.py first")
    ports = list(range(p, p + a.count))
    if a.claim:
        os.makedirs(os.path.dirname(QUEUE), exist_ok=True)
        lines = open(QUEUE, encoding="utf-8").read().splitlines() if os.path.exists(QUEUE) else []
        tag = "port " + ", ".join(map(str, ports))
        for i, line in enumerate(lines):
            cells = [c.strip() for c in line.split("|")]
            if cells and cells[0] == a.claim:
                while len(cells) < 4:
                    cells.append("")
                cells[2] = tag
                lines[i] = " | ".join(cells)
                break
        else:
            lines.append(f"{a.claim} | coding | {tag} | ")
        open(QUEUE, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print(" ".join(map(str, ports)))


if __name__ == "__main__":
    main()
