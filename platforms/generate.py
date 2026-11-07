#!/usr/bin/env python3
"""Make each platform's app store from the master app files in Apps/.

    python platforms/generate.py                       # every platform, every app -> _platforms/
    python platforms/generate.py --platform mos        # one platform
    python platforms/generate.py --app ntfy --app k7   # some apps only
    python platforms/generate.py --check               # exit 1 on any error
    python platforms/generate.py --compose-config      # also run `docker compose config` on the output
    python platforms/generate.py --write-repo          # also update the store files in the repo root

Writes _platforms/<platform>/ (that platform's store) and _platforms/report.md
(which app went where, and why some were left out). With --write-repo the
stores are also copied to the repo root, where MOS Hub reads them:
maintainer.json + compose/ + docker/*.json. Apps/ is only read, never changed.
"""
import argparse
import os
import shutil
import subprocess
import sys
import traceback
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))

from adapters import ADAPTERS, AppResult, Skip  # noqa: E402
from model import ROOT, load_apps  # noqa: E402

CONFIG = Path(__file__).resolve().parent / "config.yml"

def run(platform, adapter, apps, out):
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    results = {}
    for app in apps:
        r = results[app.slug] = AppResult(app.slug)
        try:
            adapter.build_app(app, out, r)
        except Skip as e:
            r.status, r.reason = "skipped", str(e)
        except Exception as e:  # one broken app must not stop the others
            r.status, r.reason = "error", f"{type(e).__name__}: {e}"
            r.errors.append(r.reason)
            if os.environ.get("DEBUG"):
                traceback.print_exc()
    if not adapter.native:
        adapter.build_store(apps, results, out)
        adapter.check(out, results)
    for r in results.values():
        if r.errors and r.status == "ok":
            r.status = "error"
    return results


def compose_config(platform, out, results):
    """Let Docker Compose itself parse every generated file."""
    if not shutil.which("docker"):
        print("docker not found; skipping docker compose config", file=sys.stderr)
        return
    for r in results.values():
        if r.status != "ok":
            continue
        if not (r.path and r.path.is_dir()):
            continue                     # only compose stacks have a compose file
        f, cwd = str(r.path / "compose.yaml"), r.path
        p = subprocess.run(["docker", "compose", "--project-directory", str(cwd), "-f", f, "config", "-q"],
                           cwd=cwd, capture_output=True, text=True)
        if p.returncode != 0:
            r.status = "error"
            r.errors.append("docker compose config: " + (p.stderr.strip().splitlines() or ["failed"])[-1])


def write_repo(adapter, out, root):
    """Replace this platform's generated files in the repo root with the new ones."""
    for p in adapter.owned(root):
        if p.is_dir():
            shutil.rmtree(p)
        elif p.exists():
            p.unlink()
    for src in adapter.outputs(out):
        if not src.exists():
            continue
        dst = root / src.relative_to(out)
        dst.parent.mkdir(parents=True, exist_ok=True)
        if src.is_dir():
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)


def report(all_results, cfg):
    lines = ["# Platform report", "", "Made by `platforms/generate.py` from `Apps/`.", ""]
    for platform, results in all_results.items():
        pc = cfg["platforms"][platform]
        ok = sum(r.status == "ok" for r in results.values())
        lines += [f"## {pc.get('title', platform)}: {ok} of {len(results)} apps", ""]
        if pc.get("native"):
            lines += ["Read straight from `Apps/` by `release-store.yml`.", ""]
        rows = [r for r in results.values() if r.status != "ok" or r.warnings]
        if rows:
            lines += ["| App | Status | Notes |", "|---|---|---|"]
            for r in rows:
                notes = "; ".join([r.reason] * bool(r.reason) + r.errors * (r.status == "error" and not r.reason)
                                  + r.warnings).replace("|", "\\|")
                lines.append(f"| {r.slug} | {r.status} | {notes} |")
            lines.append("")
    return "\n".join(lines) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--platform", action="append", choices=sorted(ADAPTERS), help="platform to build (repeat)")
    ap.add_argument("--app", action="append", help="app folder to build (repeat); default: all")
    ap.add_argument("--out", default=str(ROOT / "_platforms"), help="output folder (default: _platforms)")
    ap.add_argument("--check", action="store_true", help="exit 1 when any app has an error")
    ap.add_argument("--compose-config", action="store_true", help="run `docker compose config` on the output")
    ap.add_argument("--write-repo", action="store_true",
                    help="also put the output in the repo root, where MOS Hub reads it")
    args = ap.parse_args()
    if args.write_repo and args.app:
        ap.error("--write-repo builds the whole store; leave out --app")

    cfg = yaml.safe_load(CONFIG.read_text(encoding="utf-8"))
    apps = load_apps(args.app)
    out_root = Path(args.out).resolve()
    platforms = args.platform or [p for p in ADAPTERS if p in cfg["platforms"]]

    all_results, failed = {}, False
    for platform in platforms:
        adapter = ADAPTERS[platform](cfg["platforms"].get(platform) or {}, cfg.get("store") or {})
        out = out_root / platform
        results = run(platform, adapter, apps, out)
        if adapter.native:
            shutil.rmtree(out, ignore_errors=True)
        if args.compose_config and not adapter.native:
            compose_config(platform, out, results)
        if args.write_repo and not adapter.native:
            write_repo(adapter, out, ROOT)
        all_results[platform] = results
        counts = {s: sum(r.status == s for r in results.values()) for s in ("ok", "skipped", "error")}
        print(f"{platform:8} ok {counts['ok']:3}  skipped {counts['skipped']:3}  errors {counts['error']:3}"
              + ("" if adapter.native else f"  -> {out}"))
        for r in results.values():
            for e in r.errors:
                print(f"  ERROR {platform}/{r.slug}: {e}")
        failed |= counts["error"] > 0

    out_root.mkdir(parents=True, exist_ok=True)
    (out_root / "report.md").write_text(report(all_results, cfg), encoding="utf-8", newline="\n")
    print(f"report: {out_root / 'report.md'}")
    return 1 if failed and args.check else 0


if __name__ == "__main__":
    sys.exit(main())
