"""IceStore setup page for strava-dawarich-sync.

Does in the browser what upstream's `python authorize.py` does in a terminal:
shows the Strava sign-in link, takes the address the browser lands on, and
saves tokens.json with upstream's own code. Also shows which settings are
still missing and how many activities were imported.

Only the Python standard library and upstream's modules in /app are used.
"""
import html
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlencode

sys.path.insert(0, "/app")

from authorize import SCOPE, parse_code  # noqa: E402  (upstream)
from common import exchange_token, load_json, state_file, tokens_file  # noqa: E402

PORT = int(os.environ.get("ICESTORE_SETUP_PORT", "8080"))
PLACEHOLDER = "[ZIMAOS-IP-ADDRESS]"

STYLE = """
:root { color-scheme: light dark; --bg:#f6f5f2; --card:#fff; --fg:#1d1d1f; --muted:#666; --ok:#1a7f37; --bad:#c62828; --accent:#fc4c02; }
@media (prefers-color-scheme: dark) { :root { --bg:#151515; --card:#202020; --fg:#eee; --muted:#aaa; --ok:#4cc26b; --bad:#ff6b6b; } }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--fg); font:16px/1.5 system-ui, sans-serif; }
main { max-width:720px; margin:0 auto; padding:24px 16px 48px; }
h1 { font-size:1.5rem; margin:0 0 4px; }
.card { background:var(--card); border-radius:12px; padding:16px 20px; margin:16px 0; box-shadow:0 1px 3px rgba(0,0,0,.08); }
.ok { color:var(--ok); } .bad { color:var(--bad); } .muted { color:var(--muted); }
ul.check { list-style:none; padding:0; margin:0; } ul.check li { padding:4px 0; }
code { background:rgba(127,127,127,.15); padding:1px 5px; border-radius:4px; word-break:break-all; }
a.button, button { display:inline-block; background:var(--accent); color:#fff; border:0; border-radius:8px; padding:10px 16px; font-size:1rem; text-decoration:none; cursor:pointer; }
input[type=text] { width:100%; padding:10px; font-size:1rem; border-radius:8px; border:1px solid rgba(127,127,127,.5); background:transparent; color:inherit; margin:8px 0; }
ol li { margin:6px 0; }
"""


def settings():
    url = os.environ.get("DAWARICH_URL", "")
    return [
        ("STRAVA_CLIENT_ID", bool(os.environ.get("STRAVA_CLIENT_ID")),
         "The Client ID (a number) of your Strava API app."),
        ("STRAVA_CLIENT_SECRET", bool(os.environ.get("STRAVA_CLIENT_SECRET")),
         "The Client Secret of your Strava API app."),
        ("DAWARICH_URL", bool(url) and PLACEHOLDER not in url,
         "Your Dawarich address, like http://192.168.1.20:6175."),
        ("DAWARICH_API_KEY", bool(os.environ.get("DAWARICH_API_KEY")),
         "The API key from Dawarich, Account settings."),
    ]


def authorize_url():
    return "https://www.strava.com/oauth/authorize?" + urlencode({
        "client_id": os.environ.get("STRAVA_CLIENT_ID", ""),
        "response_type": "code",
        "redirect_uri": "http://localhost/exchange_token",
        "approval_prompt": "force",
        "scope": SCOPE,
    })


def page(message=""):
    rows = settings()
    all_set = all(ok for _, ok, _ in rows)
    connected = tokens_file().is_file() and tokens_file().stat().st_size > 0
    out = ["<!doctype html><html lang='en'><head><meta charset='utf-8'>",
           "<meta name='viewport' content='width=device-width, initial-scale=1'>",
           "<title>Strava to Dawarich</title><style>", STYLE, "</style></head><body><main>",
           "<h1>Strava to Dawarich</h1>",
           "<p class='muted'>Imports your Strava activities into Dawarich.</p>"]
    if message:
        out.append(f"<div class='card'>{message}</div>")

    out.append("<div class='card'><h2>1. Settings</h2><ul class='check'>")
    for name, ok, what in rows:
        mark = "<span class='ok'>&#10003;</span>" if ok else "<span class='bad'>&#10007;</span>"
        out.append(f"<li>{mark} <code>{name}</code> <span class='muted'>{html.escape(what)}</span></li>")
    out.append("</ul>")
    if not all_set:
        out.append("<p>Fill in the missing ones in the ZimaOS app settings, save, and open this page again.</p>")
    out.append("</div>")

    out.append("<div class='card'><h2>2. Connect Strava</h2>")
    if connected:
        out.append("<p class='ok'>&#10003; Strava is connected.</p>"
                   "<p class='muted'>To connect again (for another account, or after you removed the app "
                   "in Strava), use the steps below once more.</p>")
    if not os.environ.get("STRAVA_CLIENT_ID") or not os.environ.get("STRAVA_CLIENT_SECRET"):
        out.append("<p>Set <code>STRAVA_CLIENT_ID</code> and <code>STRAVA_CLIENT_SECRET</code> first.</p>")
    else:
        out.append(
            "<ol>"
            f"<li><a class='button' href='{html.escape(authorize_url())}' target='_blank' rel='noopener'>"
            "Open Strava and click Authorize</a><br><span class='muted'>Leave every box ticked.</span></li>"
            "<li>Your browser then shows an error page at <code>http://localhost/exchange_token?...</code>. "
            "That is expected.</li>"
            "<li>Copy the whole address from the address bar and paste it here:"
            "<form method='post' action='connect'>"
            "<input type='text' name='address' placeholder='http://localhost/exchange_token?state=&amp;code=...' required>"
            "<button type='submit'>Connect</button></form></li>"
            "</ol>")
    out.append("</div>")

    out.append("<div class='card'><h2>3. Sync</h2>")
    state = load_json(state_file(), None)
    if not (all_set and connected):
        out.append("<p class='muted'>The sync starts after steps 1 and 2 are done.</p>")
    elif state is None:
        out.append("<p>The first sync is running or about to start. It imports your whole Strava history, "
                   "which can take hours because of Strava's limits. Follow it in the app logs.</p>")
    else:
        when = time.strftime("%Y-%m-%d %H:%M", time.localtime(state_file().stat().st_mtime))
        out.append(f"<p><b>{len(state.get('imported', []))}</b> activities imported, "
                   f"<b>{len(state.get('skipped', []))}</b> skipped (no GPS, virtual or not in SPORT_TYPES).</p>"
                   f"<p class='muted'>Last saved {when}. New activities are checked every "
                   f"{html.escape(os.environ.get('SYNC_INTERVAL_MINUTES') or '60')} minutes. "
                   "In Dawarich they show under Imports as <code>strava_&lt;id&gt;.gpx</code>.</p>")
    out.append("</div></main></body></html>")
    return "".join(out)


class Handler(BaseHTTPRequestHandler):
    def send(self, code, body, ctype="text/html; charset=utf-8"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/health":
            self.send(200, json.dumps({"status": "ok"}), "application/json")
        elif path in ("/", "/index.html"):
            self.send(200, page())
        else:
            self.send(404, "not found", "text/plain")

    def do_POST(self):
        if self.path.split("?", 1)[0] != "/connect":
            self.send(404, "not found", "text/plain")
            return
        length = min(int(self.headers.get("Content-Length") or 0), 8192)
        form = parse_qs(self.rfile.read(length).decode(errors="replace"))
        code, granted = parse_code(form.get("address", [""])[0])
        if not code:
            msg = "<p class='bad'>No <code>code=</code> found in that address. Copy the whole address and try again.</p>"
        elif granted and "activity:read_all" not in granted:
            msg = ("<p class='bad'>The box for private activities was unticked. "
                   "Open Strava again and leave every box ticked.</p>")
        else:
            try:
                exchange_token({"grant_type": "authorization_code", "code": code})
                msg = "<p class='ok'>&#10003; Strava is connected. The sync starts within a few seconds.</p>"
                print("[icestore] Strava connected from the setup page", flush=True)
            except SystemExit as e:  # upstream exits with a message on a failed request
                msg = (f"<p class='bad'>{html.escape(str(e))}</p>"
                       "<p>A code works only once and only for a few minutes. Open Strava again for a new one.</p>")
        self.send(200, page(msg))

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print(f"[icestore] setup page on port {PORT}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
