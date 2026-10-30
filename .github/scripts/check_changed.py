#!/usr/bin/env python3
"""Run the IceStore checker only on apps that changed.

    python .github/scripts/check_changed.py          # changed apps only
    python .github/scripts/check_changed.py --all    # every app

An app counts as changed when anything under Apps/<app>/, docker/<app>/ or
.github/workflows/build-<app>.yml is new, edited or committed but not pushed.
If the checker itself changed, every app is checked.
Stops on the first app with an ERROR (exit code 1).
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHECKER = ".claude/skills/icestore/scripts/check_app.py"
PATTERNS = [
    re.compile(r"^Apps/([^/]+)/"),
    re.compile(r"^docker/([^/]+)/"),
    re.compile(r"^\.github/workflows/build-([^/]+)\.ya?ml$"),
]


def git_lines(*args):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)
    return r.stdout.splitlines() if r.returncode == 0 else []


def changed_files():
    files = set(git_lines("diff", "--name-only", "HEAD"))                      # edited, staged or not
    files |= set(git_lines("ls-files", "--others", "--exclude-standard"))     # new files
    files |= set(git_lines("diff", "--name-only", "@{u}..HEAD"))              # committed, not pushed
    return files


def all_apps():
    return sorted(p.name for p in (ROOT / "Apps").iterdir() if p.is_dir())


def main():
    files = changed_files()
    if "--all" in sys.argv or CHECKER in files:
        apps = all_apps()
    else:
        apps = sorted({m.group(1) for f in files for p in PATTERNS if (m := p.match(f))})
        # skip apps that were deleted
        apps = [a for a in apps if (ROOT / "Apps" / a).is_dir()]

    if not apps:
        print("No app changes to check.")
        return 0

    print(f"Checking {len(apps)} app(s): {', '.join(apps)}", flush=True)
    for app in apps:
        if subprocess.run([sys.executable, CHECKER, ".", app], cwd=ROOT).returncode != 0:
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
