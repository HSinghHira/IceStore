#!/usr/bin/env python3
"""Build the IceStore website from the Apps/ folder.

    pip install -r site/requirements.txt
    python site/build.py            # writes ./_site
    python -m http.server -d _site  # preview at http://localhost:8000

    python site/build.py --out dist --no-clean   # add the site to an existing store bundle

Every folder in Apps/ becomes a page at app/<folder>/. What is read from it:

  docker-compose.yml  name, tagline, image, ports, variables, category (x-casaos block)
  README.md           the Introduction tab; optional front matter (see below)
  icon.*              the app icon
  screenshot-*.*      the screenshot slider, in number order

README front matter (all optional):

  name, tagline, category    override the values from x-casaos
  site, source               "Visit project site" and "View source" links
  services                   list of [name, path, icon], shown under App details
  screenshots                captions for the screenshots, in order, e.g. [home, editor]

Site files:

  site.json                  site name, tagline, home page title/description, links
  templates/layout.html      <head>, background, footer; shared by every page
  templates/index.html       the home page
  templates/app.html         an app page
  static/                    copied as-is: css/, js/, favicon.svg, img/

Templates use {{name}} (escaped), {{{name}}} (raw HTML) and {{icon:name}} (inline SVG icon).
Pages are full HTML, so they work without JavaScript and are indexed by search engines;
js/core.js only makes moving between them smoother.
"""
import argparse
import html
import json
import math
import re
import shutil
import struct
import sys
from pathlib import Path

import markdown
import yaml

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
TPL = HERE / "templates"
STATIC = HERE / "static"
IMG_EXT = {".png", ".webp", ".jpg", ".jpeg", ".gif", ".svg"}
SECRET = r"(?:pass(?:word)?|secret|token|api[_-]?key|private[_-]?key)"
DEFAULTS = {
    "site_name": "IceStore",
    "tagline": "3rd-Party Community AppStore for Zima OS, Casa OS and Homeio",
    "title": "IceStore – Community AppStore for ZimaOS, CasaOS & Homeio",
    "description": "Browse self-hosted apps and add the IceStore community app store to ZimaOS, CasaOS "
                   "or Homeio with one link. Free, open source and community maintained.",
    "repo": "https://github.com/HSinghHira/IceStore",
    "base_url": "https://git.hsinghhira.me/IceStore/",
    "author": "Harman Singh Hira",
    "author_url": "https://github.com/HSinghHira",
}
OSES = [  # id, name, logo
    ("zimaos", "ZimaOS", "https://www.zimaspace.com/apple-touch-icon.png"),
    ("casaos", "CasaOS", "https://casaos.zimaspace.com/favicon/apple-touch-icon.png"),
    ("homeio", "Homeio", "https://homeio.app/icon.webp"),
]
# x-casaos category -> schema.org applicationCategory (anything else: UtilitiesApplication)
APP_TYPES = {
    "productivity": "BusinessApplication", "documents": "BusinessApplication", "business": "BusinessApplication",
    "finance": "FinanceApplication", "media": "MultimediaApplication", "music": "MultimediaApplication",
    "video": "MultimediaApplication", "photos": "MultimediaApplication", "gallery": "MultimediaApplication",
    "developer": "DeveloperApplication", "development": "DeveloperApplication",
    "security": "SecurityApplication", "communication": "CommunicationApplication", "chat": "CommunicationApplication",
    "social": "SocialNetworkingApplication", "education": "EducationalApplication", "games": "GameApplication",
    "gaming": "GameApplication", "home automation": "HomeApplication", "smart home": "HomeApplication",
    "network": "UtilitiesApplication", "utilities": "UtilitiesApplication",
}
ICONS = {
    "github": '<path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.4 5.4 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4"/><path d="M9 18c-4.51 2-5-2-7-2"/>',
    "plus": '<path d="M5 12h14M12 5v14"/>',
    "plus-circle": '<circle cx="12" cy="12" r="10"/><path d="M8 12h8M12 8v8"/>',
    "issues": '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="1"/>',
    "grid": '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/>',
    "copy": '<rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
    "check": '<path d="M20 6 9 17l-5-5"/>',
    "search": '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
    "info": '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>',
    "external-link": '<path d="M15 3h6v6M10 14 21 3M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>',
    "code": '<path d="m16 18 6-6-6-6M8 6l-6 6 6 6"/>',
    "arrow-left": '<path d="M19 12H5M12 19l-7-7 7-7"/>',
    "arrow-right": '<path d="M5 12h14M12 5l7 7-7 7"/>',
    "package": '<path d="M11 21.73a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73zM12 22V12M3.3 7 12 12l8.7-5"/>',
    "tag": '<path d="M12.59 2.59A2 2 0 0 0 11.17 2H4a2 2 0 0 0-2 2v7.17a2 2 0 0 0 .59 1.41l8.7 8.7a2.43 2.43 0 0 0 3.42 0l6.58-6.58a2.43 2.43 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r=".5"/>',
    "plug": '<path d="M12 22v-5M9 8V2M15 8V2M18 8v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4V8z"/>',
    "monitor": '<rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>',
    "table": '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18"/>',
    "file-code": '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M10 13l-2 2 2 2M14 13l2 2-2 2"/>',
    "server": '<rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/><path d="M6 6h.01M6 18h.01"/>',
    "mail": '<rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-10 6L2 7"/>',
    "globe": '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20M2 12h20"/>',
}


def warn(msg):
    print(f"::warning::{msg}")  # shows as an annotation in GitHub Actions


# ---------------------------------------------------------------- reading apps

def text(v, keep_lines=False):
    """x-casaos strings are plain text or {en_US: text}."""
    if isinstance(v, dict):
        v = v.get("en_US") or next(iter(v.values()), "")
    v = str(v or "").strip()
    return v if keep_lines else re.sub(r"\s+", " ", v)


def front_matter(raw):
    raw = raw.replace("\r\n", "\n").lstrip("﻿")
    m = re.match(r"---[ \t]*\n(.*?)\n---[ \t]*(?:\n|$)", raw, re.S)
    if not m:
        return {}, raw
    return (yaml.safe_load(m.group(1)) or {}), raw[m.end():]


def split_image(image):
    name, tag = image, "latest"
    if ":" in image.rsplit("/", 1)[-1]:
        name, tag = image.rsplit(":", 1)
    return name, tag


def env_pairs(env):
    if isinstance(env, dict):
        return [(str(k), "" if v is None else str(v)) for k, v in env.items()]
    return [tuple((str(e).split("=", 1) + [""])[:2]) for e in env or []]


def published_ports(svc):
    out = []
    for p in svc.get("ports") or []:
        if isinstance(p, dict):
            port = p.get("published") or p.get("target")
        else:
            parts = str(p).split("/")[0].split(":")
            port = parts[-2] if len(parts) > 1 else parts[0]
        if port:
            out.append(str(port))
    return out


def redact(key, value):
    """Passwords and keys in compose files are placeholders; never print them on the site."""
    if value and not value.startswith("$") and re.search(SECRET, key, re.I):
        return "change-me"
    return value


def redact_text(src):
    pat = r"(?im)^(\s*(?:-\s*)?[\w.-]*" + SECRET + r"[\w.-]*\s*[=:]\s*)(?!\$|\s*$)(\S.*)$"
    return re.sub(pat, r"\1change-me", src)


def fix_lists(src):
    """Allow a list to start right after a line of text, as README authors often write it."""
    item, out = re.compile(r"^\s*(?:[-*+]|\d+\.)\s"), []
    for line in src.split("\n"):
        prev = out[-1] if out else ""
        if prev.strip() and item.match(line) and not item.match(prev) and not prev.startswith((" ", "\t")):
            out.append("")
        out.append(line)
    return "\n".join(out)


def render_md(src):
    return markdown.markdown(fix_lists(src), extensions=["fenced_code", "tables", "sane_lists"])


def natural(p):
    return [int(x) if x.isdigit() else x.lower() for x in re.split(r"(\d+)", p.name)]


def image_size(path):
    """(width, height) of a PNG, GIF, WebP or JPEG, or None. Lets <img> reserve its space."""
    try:
        b = path.read_bytes()
        if b[:8] == b"\x89PNG\r\n\x1a\n":
            return struct.unpack(">II", b[16:24])
        if b[:6] in (b"GIF87a", b"GIF89a"):
            return struct.unpack("<HH", b[6:10])
        if b[:4] == b"RIFF" and b[8:12] == b"WEBP":
            kind = b[12:16]
            if kind == b"VP8X":
                return 1 + int.from_bytes(b[24:27], "little"), 1 + int.from_bytes(b[27:30], "little")
            if kind == b"VP8 ":
                w, h = struct.unpack("<HH", b[26:30])
                return w & 0x3FFF, h & 0x3FFF
            if kind == b"VP8L":
                bits = int.from_bytes(b[21:25], "little")
                return (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1
        if b[:2] == b"\xff\xd8":
            i = 2
            while i + 9 < len(b):
                if b[i] != 0xFF:
                    i += 1
                    continue
                m = b[i + 1]
                if m == 0xFF:
                    i += 1
                    continue
                if m in (0xD8, 0x01) or 0xD0 <= m <= 0xD7:
                    i += 2
                    continue
                if 0xC0 <= m <= 0xCF and m not in (0xC4, 0xC8, 0xCC):
                    h, w = struct.unpack(">HH", b[i + 5:i + 9])
                    return w, h
                i += 2 + struct.unpack(">H", b[i + 2:i + 4])[0]
    except (OSError, struct.error):
        pass
    return None


def load_app(folder):
    slug = re.sub(r"[^a-z0-9._-]+", "-", folder.name.lower()).strip("-")
    cf = next((folder / n for n in ("docker-compose.yml", "docker-compose.yaml") if (folder / n).exists()), None)
    if not cf:
        raise ValueError("missing docker-compose.yml")
    raw = cf.read_text(encoding="utf-8-sig").replace("\r\n", "\n")
    data = yaml.safe_load(raw) or {}
    services = data.get("services") or {}
    if not services:
        raise ValueError("no services in docker-compose.yml")
    meta = data.get("x-casaos") or {}
    main_name = meta.get("main") if meta.get("main") in services else next(iter(services))
    main = services[main_name] or {}
    if not main.get("image"):
        raise ValueError(f"service '{main_name}' has no image")

    rd = folder / "README.md"
    fm, body = front_matter(rd.read_text(encoding="utf-8-sig")) if rd.exists() else ({}, "")
    body = re.sub(r"\A\s*#\s+.*\n", "", body, count=1)  # the page already shows the title

    name = str(fm.get("name") or text(meta.get("title")) or folder.name)
    tagline = str(fm.get("tagline") or text(meta.get("tagline")))
    desc_md = text(meta.get("description"), keep_lines=True)
    if body.strip():
        intro = render_md(body)
    else:
        warn(f"Apps/{folder.name}: no README.md, using the description from x-casaos")
        intro = render_md(desc_md) if desc_md else f"<p>{html.escape(tagline or name)}</p>"
    tagline = tagline or re.sub(r"\s+", " ", desc_md)[:160]

    image, version = split_image(str(main["image"]))
    ports = published_ports(main)
    if not ports:
        warn(f"Apps/{folder.name}: no ports found")

    # variable descriptions live in the service's own x-casaos block (the top-level one is also checked)
    svc_meta = main.get("x-casaos") or {}
    envs = list(svc_meta.get("envs") or []) + list(meta.get("envs") or [])
    notes = {e.get("container"): text(e.get("description")) for e in envs if isinstance(e, dict)}
    env = [(k, redact(k, v), notes.get(k, "")) for k, v in env_pairs(main.get("environment"))]

    path = str(meta.get("index") or "/")
    default_svcs = [["Web UI", path, "globe"]] if ports else []
    svcs = []
    for s in fm.get("services", default_svcs) or []:
        if isinstance(s, dict):
            s = [s.get("name"), s.get("path", "/"), s.get("icon", "globe")]
        p = str(s[1]) if len(s) > 1 else "/"
        ic = str(s[2]) if len(s) > 2 and s[2] else "globe"
        if ic not in ICONS:
            warn(f"Apps/{folder.name}: unknown service icon '{ic}', using globe")
            ic = "globe"
        svcs.append((str(s[0]), p if p.startswith("/") else "/" + p, ic))

    repo = str(fm.get("source") or meta.get("repo") or "")
    site = str(fm.get("site") or repo)
    icon = next((p for p in sorted(folder.glob("icon.*"), key=natural) if p.suffix.lower() in IMG_EXT), None)
    shots = [p for p in sorted(folder.glob("screenshot*"), key=natural) if p.suffix.lower() in IMG_EXT]
    captions = [str(c) for c in (fm.get("screenshots") or [])]
    if not icon:
        warn(f"Apps/{folder.name}: no icon.png, using a letter tile")
    if not shots:
        warn(f"Apps/{folder.name}: no screenshot-*.png, the slider is hidden")

    return {
        "slug": slug, "folder": folder, "icon": icon, "shots": shots,
        "name": name, "desc": tagline, "image": image, "version": version, "ports": ports,
        "category": str(fm.get("category") or text(meta.get("category"))),
        "site": site, "src": repo or site, "svcs": svcs, "env": env, "captions": captions,
        "compose": redact_text(raw).rstrip(), "intro": intro,
    }


# ---------------------------------------------------------------- rendering

def e(s):
    return html.escape(str(s))


def code_ticks(s):
    """Escape, then turn `x` into <code>x</code> (used for variable descriptions)."""
    return re.sub(r"`([^`]+)`", r"<code>\1</code>", e(s))


def icon(n):
    return f'<svg class="i" viewBox="0 0 24 24" aria-hidden="true">{ICONS[n]}</svg>'


def wbr(url):
    """Let a long URL wrap after each slash."""
    return e(url).replace("/", "/<wbr>").removesuffix("<wbr>")


def hue(name):
    return sum(ord(c) for c in name) % 40


def ph(name, src=""):
    """Letter tile in the app's colour, with the icon on top when there is one."""
    img = f'<img src="{e(src)}" alt="" loading="lazy" onerror="this.remove()">' if src else ""
    return f'<span class="ph" style="--h:{hue(name)}" aria-hidden="true">{e(name[:1].upper())}{img}</span>'


def js(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")


def fill(tpl, values):
    """{{{k}}} raw, {{k}} escaped, {{icon:n}} icon. Every token must be filled.
    One pass, so text inserted from an app (a compose file, a README) is never read as a token."""
    def sub(m):
        raw, k = m.group(1) is not None, m.group(1) or m.group(2)
        if not raw and k.startswith("icon:"):
            if k[5:] not in ICONS:
                raise ValueError(f"unknown icon in template: {k}")
            return icon(k[5:])
        if k not in values:
            raise ValueError(f"unfilled template token: {m.group(0)}")
        return str(values[k]) if raw else e(values[k])

    return re.sub(r"\{\{\{([\w:-]+)\}\}\}|\{\{([\w:-]+)\}\}", sub, tpl)


def page(layout, content, head):
    return fill(layout, {**head, "content": content})


def marquee(apps):
    half = math.ceil(len(apps) / 2)
    out = []
    for row, cls in ((apps[:half], "row"), (apps[half:], "row r")):
        if not row:
            continue
        reps = max(1, math.ceil(24 / len(row)))  # enough tiles to fill wide screens
        tiles = "".join(f'<div class="tile">{ph(a["name"], a["icon_url"])}</div>' for a in row) * reps
        out.append(f'  <div class="mq" aria-hidden="true"><div class="{cls}">{tiles * 2}</div></div>')
    return "\n".join(out)


def home_page(apps, cfg, tpl, layout):
    base = cfg["base_url"]
    cards = "".join(
        f'<a class="card" href="app/{a["slug"]}/" data-name="{e(a["name"].lower())}">{ph(a["name"], a["icon_url"])}<h3>{e(a["name"])}</h3></a>'
        for a in apps)
    tabs = "".join(
        f'<button class="tab" role="tab" type="button" id="{i}" data-hash="{i}" aria-controls="p-{i}" aria-selected="{str(j == 0).lower()}">'
        f'<img src="{logo}" alt="" width="24" height="24" loading="lazy">{n}</button>'
        for j, (i, n, logo) in enumerate(OSES))
    values = {
        **cfg, "app_count": len(apps), "marquee": marquee(apps), "cards": cards, "os_tabs": tabs,
        **{f"{i}_logo": logo for i, _, logo in OSES},
        **{f"{i}_url_wbr": wbr(cfg[f"{i}_url"]) for i, _, _ in OSES},
    }
    ld = {"@context": "https://schema.org", "@graph": [
        {"@type": "WebSite", "@id": base + "#website", "url": base, "name": cfg["site_name"],
         "description": cfg["tagline"], "inLanguage": "en", "publisher": {"@id": base + "#author"}},
        {"@type": "Person", "@id": base + "#author", "name": cfg["author"], "url": cfg["author_url"]},
    ]}
    head = {**cfg, "root": "", "url": base, "og_image": base + "img/og.png",
            "og_alt": f'{cfg["site_name"]} – {cfg["tagline"]}', "jsonld": js(ld)}
    return page(layout, fill(tpl, values), head)


def app_page(a, cfg, tpl, layout):
    base, name = cfg["base_url"], a["name"]
    url = f'{base}app/{a["slug"]}/'

    chips = [("package", f'{a["image"]}:{a["version"]}')] + [("plug", f"port {p}") for p in a["ports"]]
    if a["category"]:
        chips.append(("tag", a["category"]))
    links = []
    if a["site"]:
        links.append(f'<a class="btn p" href="{e(a["site"])}" rel="noopener">{icon("external-link")}Visit project site</a>')
    if a["src"]:
        links.append(f'<a class="btn" href="{e(a["src"])}" rel="noopener">{icon("code")}View source</a>')

    shots = ""
    if a["shots"]:
        imgs = []
        for n, f in enumerate(a["shots"], 1):
            cap = a["captions"][n - 1] if n <= len(a["captions"]) else ""
            alt = f"{name} screenshot {n}" + (f": {cap}" if cap else "")
            size = image_size(f)
            dims = f' width="{size[0]}" height="{size[1]}"' if size else ""
            lazy = ' loading="lazy"' if n > 1 else ""
            imgs.append(f'<img src="{e(f.name)}" alt="{e(alt)}"{dims}{lazy}>')
        shots = (
            f'      <div class="shot" role="region" aria-roledescription="carousel" aria-label="{e(name)} screenshots">\n'
            f'        <div class="chrome"><i></i><i></i><i></i><span class="cnt" aria-live="off"></span></div>\n'
            f'        <div class="slw"><div class="sl" tabindex="0">{"".join(imgs)}</div>\n'
            f'          <button class="nav prev" type="button" aria-label="Previous screenshot">{icon("arrow-left")}</button>'
            f'<button class="nav next" type="button" aria-label="Next screenshot">{icon("arrow-right")}</button></div>\n'
            f'        <div class="dots"></div>\n      </div>')

    details = ""
    if a["svcs"] and a["ports"]:
        host = f'http://localhost:{a["ports"][0]}'
        cards = "".join(
            f'<div class="sv"><div class="t"><h3>{e(k)}</h3><span class="pt">{e(p)}</span></div>'
            f'<div class="u"><span class="bd">{icon(ic)}</span><code>{e(host)}<wbr>{e(p)}</code>'
            f'<button class="ic" type="button" data-copy="{e(host + p)}" aria-label="Copy {e(k)} URL">{icon("copy")}</button></div></div>'
            for k, p, ic in a["svcs"])
        details = (
            '\n    <section class="sec" style="padding-left:0;padding-right:0" aria-labelledby="det-h">\n'
            '      <h2 id="det-h">App details</h2>\n'
            '      <p class="note">Replace localhost with your device’s IP address.</p>\n'
            f'      <div class="svs">{cards}</div>\n    </section>')

    tabs = [("intro", "info", "Introduction", f'<div class="md">{a["intro"]}</div>')]
    if a["env"]:
        rows = "".join(
            f'<tr><td><code>{e(k)}</code></td><td><code>{e(v) or "—"}</code></td><td>{code_ticks(d)}</td></tr>'
            for k, v, d in a["env"])
        tabs.append(("vars", "table", "Variables",
                     '<div class="tw"><table><thead><tr><th>Variable</th><th>Default value</th><th>Description</th></tr>'
                     f'</thead><tbody>{rows}</tbody></table></div>'))
    tabs.append(("compose", "file-code", "Docker Compose",
                 f'<div class="code"><div class="chrome"><i></i><i></i><i></i><span>docker-compose.yml</span>'
                 f'<button class="btn p s" type="button" data-copy-from="#yml" data-done="Copied">{icon("copy")}Copy</button></div>'
                 f'<pre id="yml"><code class="yml">{e(a["compose"])}</code></pre></div>'))
    tab_html = "".join(
        f'<button class="tab" role="tab" type="button" id="t-{i}" aria-controls="p-{i}" aria-selected="{str(j == 0).lower()}">{icon(ic)}{n}</button>'
        for j, (i, ic, n, _) in enumerate(tabs))
    panels = "\n".join(
        f'      <div class="panel" role="tabpanel" id="p-{i}" aria-labelledby="t-{i}">{body}</div>'
        for i, _, _, body in tabs)

    install = "".join(
        f'<a href="../../#{i}"><h3><img src="{logo}" alt="" width="32" height="32" loading="lazy">{n}</h3>'
        f'<p>Add the store link, then find {e(name)} in the App Store and install it.</p></a>'
        for i, n, logo in OSES)

    values = {
        **cfg, "app_name": name, "desc": a["desc"], "hero_class": "ahero" if a["shots"] else "ahero solo",
        "icon": ph(name, a["icon"].name if a["icon"] else ""),
        "chips": "".join(f"<li>{icon(i)}{e(x)}</li>" for i, x in chips),
        "links": f'<div class="cta" style="justify-content:flex-start">{"".join(links)}</div>' if links else "",
        "shots": shots, "details": details, "tabs": tab_html, "panels": panels, "install": install,
    }
    title = f'{name} – ZimaOS, CasaOS & Homeio app | {cfg["site_name"]}'
    desc = f'{a["desc"].rstrip(".")}. ' if a["desc"] else ""
    desc += f'Install it on ZimaOS, CasaOS or Homeio from the {cfg["site_name"]} community app store.'
    app_ld = {
        "@type": "SoftwareApplication", "name": name, "description": a["desc"] or desc, "url": url,
        "image": url + a["shots"][0].name if a["shots"] else base + "img/og.png",
        "applicationCategory": APP_TYPES.get(a["category"].lower(), "UtilitiesApplication"),
        "operatingSystem": "Linux (Docker)",
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "author": {"@type": "Person", "name": cfg["author"], "url": cfg["author_url"]},
        "isPartOf": {"@id": base + "#website"},
    }
    crumbs = {"@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": 1, "name": cfg["site_name"], "item": base},
        {"@type": "ListItem", "position": 2, "name": "Apps", "item": base + "#apps"},
        {"@type": "ListItem", "position": 3, "name": name, "item": url},
    ]}
    head = {**cfg, "root": "../../", "title": title, "description": desc, "url": url,
            "og_image": base + "img/og.png", "og_alt": f'{name} on {cfg["site_name"]}',
            "jsonld": js({"@context": "https://schema.org", "@graph": [app_ld, crumbs]})}
    return page(layout, fill(tpl, values), head)


def sitemap(apps, base):
    urls = [f"  <url><loc>{e(base)}</loc><changefreq>weekly</changefreq><priority>1.0</priority></url>"]
    urls += [f'  <url><loc>{e(base)}app/{a["slug"]}/</loc><changefreq>monthly</changefreq><priority>0.8</priority></url>'
             for a in apps]
    return ('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
            + "\n".join(urls) + "\n</urlset>\n")


def manifest(cfg):
    return json.dumps({
        "name": cfg["site_name"], "short_name": cfg["site_name"], "description": cfg["tagline"],
        "start_url": ".", "display": "standalone", "background_color": "#000000", "theme_color": "#000000",
        "icons": [
            {"src": "img/icon-192.png", "sizes": "192x192", "type": "image/png"},
            {"src": "img/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable"},
        ],
    }, indent=2, ensure_ascii=False) + "\n"


# ---------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "_site"))
    ap.add_argument("--no-clean", action="store_true", help="keep what is already in the output folder")
    args = ap.parse_args()
    out = Path(args.out)

    cfg = dict(DEFAULTS)
    if (HERE / "site.json").exists():
        cfg.update(json.loads((HERE / "site.json").read_text(encoding="utf-8")))
    cfg["base_url"] = cfg["base_url"].rstrip("/") + "/"
    # real files with real extensions, so GitHub Pages serves the right content type
    cfg["zimaos_url"] = cfg["base_url"] + "store.json"
    cfg["casaos_url"] = cfg["homeio_url"] = cfg["base_url"] + "store.zip"

    apps, errors = [], []
    for folder in sorted(p for p in (ROOT / "Apps").iterdir() if p.is_dir() and not p.name.startswith(".")):
        try:
            apps.append(load_app(folder))
        except Exception as ex:  # report every broken app at once
            errors.append(f"Apps/{folder.name}: {ex}")
    if errors:
        for msg in errors:
            print(f"::error::{msg}")
        sys.exit(1)
    apps.sort(key=lambda a: a["name"].lower())
    for a in apps:
        a["icon_url"] = f'app/{a["slug"]}/{a["icon"].name}' if a["icon"] else ""

    layout = (TPL / "layout.html").read_text(encoding="utf-8")
    tpl_index = (TPL / "index.html").read_text(encoding="utf-8")
    tpl_app = (TPL / "app.html").read_text(encoding="utf-8")

    if out.exists() and not args.no_clean:
        shutil.rmtree(out)
    out.mkdir(parents=True, exist_ok=True)
    if STATIC.exists():
        shutil.copytree(STATIC, out, dirs_exist_ok=True)
    (out / ".nojekyll").write_text("")

    for a in apps:
        dest = out / "app" / a["slug"]
        dest.mkdir(parents=True, exist_ok=True)
        for f in ([a["icon"]] if a["icon"] else []) + a["shots"]:
            shutil.copy(f, dest / f.name)
        (dest / "index.html").write_text(app_page(a, cfg, tpl_app, layout), encoding="utf-8")

    (out / "index.html").write_text(home_page(apps, cfg, tpl_index, layout), encoding="utf-8")
    (out / "sitemap.xml").write_text(sitemap(apps, cfg["base_url"]), encoding="utf-8")
    (out / "robots.txt").write_text(f'User-agent: *\nAllow: /\n\nSitemap: {cfg["base_url"]}sitemap.xml\n', encoding="utf-8")
    (out / "manifest.webmanifest").write_text(manifest(cfg), encoding="utf-8")
    print(f"Built {len(apps)} app page(s) into {out}")


if __name__ == "__main__":
    main()
