#!/usr/bin/env python3
"""Build the site and preview it on localhost, rebuilding when files change.

    python site/serve.py               # http://localhost:8000
    python site/serve.py --port 3000
    python site/serve.py --no-watch    # build once, then serve

Watches site/ (templates, static, build.py, site.json) and Apps/. Refresh the
browser after a rebuild. Unknown paths get _site/404.html, like the live host.
"""
import argparse
import functools
import http.server
import subprocess
import sys
import threading
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = ROOT / "_site"
WATCH = [HERE, ROOT / "Apps"]


def build():
    t = time.time()
    r = subprocess.run([sys.executable, str(HERE / "build.py"), "--out", str(OUT)])
    if r.returncode == 0:  # app badges need pillow and fonttools; the site works without them
        b = subprocess.run([sys.executable, str(ROOT / ".github" / "scripts" / "app_badges.py"), "--out", str(OUT)])
        if b.returncode:
            print("app badges skipped (pip install pillow fonttools)", flush=True)
    print(f"build {'ok' if r.returncode == 0 else 'FAILED'} in {time.time() - t:.1f}s", flush=True)


def snapshot():
    return {p: p.stat().st_mtime for d in WATCH if d.exists()
            for p in d.rglob("*") if p.is_file() and "__pycache__" not in p.parts}


def watch():
    last = snapshot()
    while True:
        time.sleep(1)
        now = snapshot()
        if now != last:
            changed = sorted({p.relative_to(ROOT) for p in now.keys() ^ last.keys()}
                             | {p.relative_to(ROOT) for p in now.keys() & last.keys() if now[p] != last[p]})
            print("changed:", ", ".join(map(str, changed[:5])) + (" ..." if len(changed) > 5 else ""), flush=True)
            build()
            last = snapshot()


class Handler(http.server.SimpleHTTPRequestHandler):
    def send_error(self, code, message=None, explain=None):
        page = OUT / "404.html"
        if code == 404 and page.exists():
            body = page.read_bytes()
            self.send_response(404)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)
            return
        super().send_error(code, message, explain)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8000)
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--no-watch", action="store_true")
    args = ap.parse_args()

    build()
    if not args.no_watch:
        threading.Thread(target=watch, daemon=True).start()

    handler = functools.partial(Handler, directory=str(OUT))
    with http.server.ThreadingHTTPServer((args.host, args.port), handler) as srv:
        print(f"serving {OUT} at http://localhost:{args.port}  (Ctrl+C to stop)", flush=True)
        try:
            srv.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
