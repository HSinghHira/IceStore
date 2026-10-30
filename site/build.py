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
  services                   list of [name, path, icon] or {name, path, icon, port}, shown
                             under App details; port picks another published port (default: the first)
  screenshots                captions for the screenshots, in order, e.g. [home, editor]

Site files:

  site.json                  site name, tagline, home page title/description, links
  templates/layout.html      <head>, background, footer; shared by every page
  templates/index.html       the home page
  templates/app.html         an app page
  app-badge/                 badge picker page (built here); the badge SVGs come from
                             .github/scripts/app_badges.py, run after this script
  static/                    copied as-is: css/, js/, favicon/, img/

Templates use {{name}} (escaped), {{{name}}} (raw HTML) and {{icon:name}} (inline SVG icon).
Pages are full HTML, so they work without JavaScript and are indexed by search engines;
js/core.js only makes moving between them smoother.
"""
import argparse
import datetime
import html
import json
import math
import os
import re
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
import shutil
import struct
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlencode

import markdown
import yaml

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
TPL = HERE / "templates"
STATIC = HERE / "static"
IMG_EXT = {".png", ".webp", ".jpg", ".jpeg", ".gif", ".svg"}
SECRET = r"(?:pass(?:word)?|secret|token|api[_-]?key|private[_-]?key|encryption[_-]?key)"
DEFAULTS = {
    "site_name": "IceStore",
    "tagline": "3rd-Party Community AppStore for Zima OS, Casa OS and Homeio",
    "title": "IceStore – Community AppStore for ZimaOS, CasaOS & Homeio",
    "description": "Browse self-hosted apps and add the IceStore community app store to ZimaOS, CasaOS "
                   "or Homeio with one link. Free, open source and community maintained.",
    "repo": "https://github.com/HSinghHira/IceStore",
    "base_url": "https://icestore.hsinghhira.me/",
    "author": "Harman Singh Hira",
    "author_url": "https://github.com/HSinghHira",
}
OSES = [  # id, name, logo
    ("zimaos", "ZimaOS", "https://www.zimaspace.com/apple-touch-icon.png"),
    ("casaos", "CasaOS", "https://casaos.zimaspace.com/favicon/apple-touch-icon.png"),
    ("homeio", "Homeio", "https://homeio.app/icon.webp"),
]
# x-casaos architectures -> plain names for the chip's tooltip
ARCH_NAMES = {"amd64": "Intel/AMD 64-bit", "arm64": "ARM 64-bit", "arm": "ARM 32-bit", "arm/v7": "ARM 32-bit",
              "386": "Intel/AMD 32-bit", "riscv64": "RISC-V 64-bit"}
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
    "cpu": '<rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6" rx="1"/><path d="M15 2v2M15 20v2M2 15h2M2 9h2M20 15h2M20 9h2M9 2v2M9 20v2"/>',
    "star": '<path d="M11.5 2.3a.6.6 0 0 1 1 0l2.6 5.4 5.9.8a.6.6 0 0 1 .3 1l-4.3 4.2 1 5.9a.6.6 0 0 1-.8.6L12 17.4l-5.3 2.8a.6.6 0 0 1-.8-.6l1-5.9-4.3-4.2a.6.6 0 0 1 .3-1l5.9-.8z"/>',
    "calendar": '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
    "commit": '<circle cx="12" cy="12" r="3"/><path d="M3 12h6M15 12h6"/>',
    "rss": '<path d="M4 11a9 9 0 0 1 9 9M4 4a16 16 0 0 1 16 16"/><circle cx="5" cy="19" r="1"/>',
    "download": '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>',
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
    # [ \t]*, not \s*: a blank value must not let the match run on into the next line
    pat = r"(?im)^([ \t]*(?:-[ \t]*)?[\w.-]*" + SECRET + r"[\w.-]*[ \t]*[=:][ \t]*)(?!\$|[ \t]*$)(\S.*)$"
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


def git_dates():
    """{folder: (added, updated)} as Unix times, from git history (empty without git).
    added = first commit that touched Apps/<folder>; updated = last commit that changed an
    `image:` line there (a version bump), else added. Needs the full history (fetch-depth: 0)."""
    def log(*args):
        r = subprocess.run(["git", "-C", str(ROOT), "log", "--format=@%ct", "--name-only", *args, "--", "Apps"],
                           capture_output=True, text=True, encoding="utf-8")
        if r.returncode:
            return {}
        seen, t = {}, 0
        for line in r.stdout.splitlines():  # newest first
            if line.startswith("@"):
                t = int(line[1:])
            elif line.count("/") >= 2:
                seen.setdefault(line.split("/")[1], []).append(t)
        return seen

    try:
        touched, bumped = log(), log(r"-G^\s*image:")
    except OSError:
        return {}
    return {f: (min(ts), max(bumped.get(f) or [min(ts)])) for f, ts in touched.items()}


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

    # more settings: README front matter `variables:` (not in the compose file, so
    # people add them in the app settings themselves). Grouped by `group`.
    in_compose = {k for k, _, _ in env}
    more = []
    for i, x in enumerate(fm.get("variables") or []):
        if not isinstance(x, dict) or not x.get("name"):
            warn(f"Apps/{folder.name}: README variables item {i + 1} has no name")
            continue
        k = str(x["name"]).strip()
        if k in in_compose:
            warn(f"Apps/{folder.name}: README variable {k} is also in docker-compose.yml; shown once")
            continue
        dv = x.get("default", "")
        dv = "" if dv is None else (str(dv).lower() if isinstance(dv, bool) else str(dv))
        more.append((str(x.get("group") or "More settings"), k, dv, text(x.get("description"))))  # defaults, not secrets

    path = str(meta.get("index") or "/")
    default_svcs = [["Web UI", path, "globe"]] if ports else []
    svcs = []
    for s in fm.get("services", default_svcs) or []:
        if isinstance(s, dict):
            s = [s.get("name"), s.get("path", "/"), s.get("icon", "globe"), s.get("port")]
        p = str(s[1]) if len(s) > 1 else "/"
        ic = str(s[2]) if len(s) > 2 and s[2] else "globe"
        if ic not in ICONS:
            warn(f"Apps/{folder.name}: unknown service icon '{ic}', using globe")
            ic = "globe"
        port = str(s[3]) if len(s) > 3 and s[3] else (ports[0] if ports else "")
        if ports and port not in ports:
            warn(f"Apps/{folder.name}: service '{s[0]}' port {port} is not published, using {ports[0]}")
            port = ports[0]
        svcs.append((str(s[0]), p if p.startswith("/") else "/" + p, ic, port))

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
        "arch": [str(x) for x in (meta.get("architectures") or [])],
        # the app's own version and release date from x-casaos (the image tag is often just "latest")
        "app_version": str(meta.get("version") or "").strip(), "update_at": str(meta.get("update_at") or "").strip(),
        "site": site, "src": repo or site, "svcs": svcs, "env": env, "more": more, "captions": captions,
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


def ph(name, src="", fallback=""):
    """Letter tile in the app's colour, with the icon on top when there is one.
    If src fails, fallback is tried (the original file when src is the wsrv.nl copy), then the letter shows."""
    f = f' data-f="{e(fallback)}"' if fallback and fallback != src else ""
    onerror = "if(this.dataset.f){this.src=this.dataset.f;this.removeAttribute('data-f')}else this.remove()"
    img = f'<img src="{e(src)}"{f} alt="" loading="lazy" decoding="async" onerror="{onerror}">' if src else ""
    return f'<span class="ph" style="--h:{hue(name)}" aria-hidden="true">{e(name[:1].upper())}{img}</span>'


def wsrv(url, **opts):
    """Resized, recompressed copy of a public image via the wsrv.nl image CDN.
    GIFs (animation) and SVGs (vectors) are left as they are."""
    if url.lower().endswith((".gif", ".svg")):
        return url
    return "https://wsrv.nl/?" + urlencode({"url": url, **opts})


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
        tiles = "".join(f'<div class="tile">{ph(a["name"], a["icon_cdn"], a["icon_url"])}</div>' for a in row) * reps
        out.append(f'  <div class="mq" aria-hidden="true"><div class="{cls}">{tiles * 2}</div></div>')
    return "\n".join(out)


def card(a, root=""):
    """App card with category, name and tagline. root leads back to the site root ("../../" on app pages).
    data-q is what the home search matches: name, tagline and category."""
    q = " ".join((a["name"], a["desc"], a["category"])).lower()
    k = f'<span class="k">{e(a["category"])}</span>' if a["category"] else ""
    p = f'<p>{e(a["desc"])}</p>' if a["desc"] else ""
    fallback = root + a["icon_url"] if a["icon_url"] else ""
    return (f'<a class="card" href="{root}app/{a["slug"]}/" data-name="{e(a["name"].lower())}" data-cat="{e(a["category"])}" '
            f'data-q="{e(q)}" data-added="{a["added"]}" data-updated="{a["updated"]}" '
            f'data-stars="{a.get("stars") or 0}" data-forks="{a.get("forks") or 0}">{ph(a["name"], a["icon_cdn"], fallback)}'
            f'<div class="ct">{k}<h3>{e(a["name"])}</h3>{p}</div></a>')


def related(a, apps, n=3):
    """Up to n other apps in the same category: the ones after this app A-Z, wrapping round,
    so each page shows different neighbours."""
    same = [x for x in apps if x["category"] and x["category"] == a["category"]]
    if len(same) < 2:
        return []
    i = same.index(a)
    return (same[i + 1:] + same[:i])[:n]


def related_html(a, apps):
    more = related(a, apps)
    if not more:
        return ""
    cat = a["category"]
    return (
        '\n    <section class="sec rel" style="padding-left:0;padding-right:0" aria-labelledby="rel-h">\n'
        f'      <div class="rh"><h2 id="rel-h">More {e(cat)} apps</h2>'
        f'<a class="btn" href="../../?{e(urlencode({"cat": cat}))}#apps">{icon("grid")}See all</a></div>\n'
        f'      <div class="grid">{"".join(card(x, "../../") for x in more)}</div>\n    </section>')


def home_page(apps, cfg, tpl, layout):
    base = cfg["base_url"]
    cards = "".join(card(a) for a in apps)
    # category filter: biggest first, "Others" last
    counts = {}
    for a in apps:
        if a["category"]:
            counts[a["category"]] = counts.get(a["category"], 0) + 1
    order = sorted(counts, key=lambda c: (c.lower() in ("other", "others"), -counts[c], c.lower()))
    cats = f'<button class="cat" type="button" data-cat="" aria-pressed="true">All<b>{len(apps)}</b></button>' + "".join(
        f'<button class="cat" type="button" data-cat="{e(c)}" aria-pressed="false">{e(c)}<b>{counts[c]}</b></button>'
        for c in order)
    tabs = "".join(
        f'<button class="tab" role="tab" type="button" id="{i}" data-hash="{i}" aria-controls="p-{i}" aria-selected="{str(j == 0).lower()}">'
        f'<img src="{logo}" alt="" width="24" height="24" loading="lazy">{n}</button>'
        for j, (i, n, logo) in enumerate(OSES))
    values = {
        **cfg, "app_count": len(apps), "marquee": marquee(apps), "cards": cards, "cats": cats, "os_tabs": tabs,
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


def github_repo(url):
    """"owner/repo" for a github.com link, else ""."""
    m = re.match(r"https?://github\.com/([\w.-]+)/([\w.-]+)", url or "")
    return f"{m.group(1)}/{m.group(2).removesuffix('.git')}" if m else ""


def github_stats(apps):
    """{owner/repo: {"stars": n, "forks": n}} for the apps' upstream projects. Cached in .cache/ for
    12 hours so local rebuilds do not hit the API rate limit; uses $GITHUB_TOKEN when set (as in
    GitHub Actions). Set ICESTORE_NO_STARS=1 to skip. Any failure just leaves the star chip out."""
    if os.environ.get("ICESTORE_NO_STARS"):
        return {}
    cache_file = ROOT / ".cache" / "github-stats.json"
    try:
        cache = json.loads(cache_file.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        cache = {}
    stats = cache.get("repos", {})
    repos = sorted({r for r in (github_repo(a["src"]) for a in apps) if r})
    if time.time() - cache.get("time", 0) < 12 * 3600 and all(r in stats for r in repos):
        return stats

    headers = {"Accept": "application/vnd.github+json", "User-Agent": "IceStore-site-build"}
    if os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = "Bearer " + os.environ["GITHUB_TOKEN"]

    def get(repo):
        try:
            req = urllib.request.Request(f"https://api.github.com/repos/{repo}", headers=headers)
            with urllib.request.urlopen(req, timeout=8) as r:
                d = json.load(r)
                return repo, {"stars": int(d["stargazers_count"]), "forks": int(d["forks_count"])}
        except Exception:
            return repo, None

    with ThreadPoolExecutor(8) as pool:
        got = {r: n for r, n in pool.map(get, repos) if n is not None}
    if not got:
        warn("could not fetch GitHub stars (offline or rate limited); using the cached numbers")
        return stats
    stats.update(got)
    try:
        cache_file.parent.mkdir(exist_ok=True)
        cache_file.write_text(json.dumps({"time": time.time(), "repos": stats}), encoding="utf-8")
    except OSError:
        pass
    return stats


def short_num(n):
    """52300 -> 52.3k"""
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}".rstrip("0").rstrip(".") + "M"
    if n >= 1000:
        return f"{n / 1000:.1f}".rstrip("0").rstrip(".") + "k"
    return str(n)


def parse_day(s):
    try:
        return datetime.date.fromisoformat(str(s)[:10])
    except ValueError:
        return None


def issue_url(cfg, template, **fields):
    """New-issue link that opens one of the forms in .github/ISSUE_TEMPLATE, with fields filled in."""
    return f'{cfg["repo"]}/issues/new?' + urlencode({"template": template, **fields})


def pager_html(a, apps):
    """Previous / next app, A-Z, wrapping round."""
    if len(apps) < 2:
        return ""
    i = apps.index(a)
    prev, nxt = apps[i - 1], apps[(i + 1) % len(apps)]
    return (
        '\n    <nav class="pager" aria-label="Previous and next app">'
        f'<a class="pg" href="../../app/{prev["slug"]}/" rel="prev"><span>{icon("arrow-left")}Previous app</span><b>{e(prev["name"])}</b></a>'
        f'<a class="pg nx" href="../../app/{nxt["slug"]}/" rel="next"><span>Next app{icon("arrow-right")}</span><b>{e(nxt["name"])}</b></a>'
        '</nav>')


def app_time(a):
    """When the app last changed: git (version bump) first, then x-casaos update_at, as a UTC datetime."""
    if a.get("updated"):
        return datetime.datetime.fromtimestamp(a["updated"], datetime.timezone.utc)
    d = parse_day(a["update_at"])
    return datetime.datetime(d.year, d.month, d.day, tzinfo=datetime.timezone.utc) if d else None


def feed(apps, cfg, n=30):
    """feed.xml: an Atom feed of the n most recently added or updated apps. Each version is its
    own entry, so feed readers show an app again when it gets a new version."""
    base = cfg["base_url"]
    dated = sorted(((app_time(a), a) for a in apps if app_time(a)), key=lambda x: x[0], reverse=True)[:n]
    now = datetime.datetime.now(datetime.timezone.utc)
    iso = lambda t: t.replace(microsecond=0).isoformat().replace("+00:00", "Z")
    entries = []
    for t, a in dated:
        url = f'{base}app/{a["slug"]}/'
        v = a["app_version"]
        title = f'{a["name"]} {v}' if v else a["name"]
        cat = f'<category term="{e(a["category"])}"/>' if a["category"] else ""
        entries.append(
            f'  <entry>\n    <title>{e(title)}</title>\n    <link href="{e(url)}"/>\n'
            f'    <id>{e(url)}#v{e(v or iso(t))}</id>\n    <updated>{iso(t)}</updated>\n'
            f'    <summary>{e(a["desc"])}</summary>\n    {cat}\n  </entry>')
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n<feed xmlns="http://www.w3.org/2005/Atom">\n'
        f'  <title>{e(cfg["site_name"])} – new and updated apps</title>\n'
        f'  <subtitle>{e(cfg["tagline"])}</subtitle>\n'
        f'  <link href="{e(base)}feed.xml" rel="self"/>\n  <link href="{e(base)}"/>\n'
        f'  <id>{e(base)}</id>\n  <updated>{iso(dated[0][0] if dated else now)}</updated>\n'
        f'  <author><name>{e(cfg["author"])}</name><uri>{e(cfg["author_url"])}</uri></author>\n'
        + "\n".join(entries) + "\n</feed>\n")


def service_worker(version):
    """sw.js: lets the site open offline. Network first (so nothing is ever stale online),
    with the last copy from the cache when the network fails."""
    return f"""/* IceStore offline support, built {version}. Network first; the cache is only a fallback. */
const V='ice-{version}',PRE=['./','css/style.css','js/icons.js','js/core.js','js/home.js','js/app.js','js/badge.js',
  'favicon/favicon.svg','manifest.webmanifest','favicon/web-app-manifest-192x192.png'];
self.addEventListener('install',e=>e.waitUntil(caches.open(V).then(c=>c.addAll(PRE)).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys()
  .then(ks=>Promise.all(ks.filter(k=>k!==V).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{{
  const r=e.request,u=new URL(r.url);
  if(r.method!=='GET'||u.origin!==location.origin||/\\.zip$/.test(u.pathname))return;
  const page=r.mode==='navigate'||(r.headers.get('accept')||'').includes('text/html');
  e.respondWith(fetch(r).then(res=>{{
    if(res.ok&&res.type==='basic'){{const c=res.clone();caches.open(V).then(x=>x.put(r,c))}}
    return res;
  }}).catch(()=>caches.match(r).then(m=>m||(page?caches.match('./'):undefined)).then(m=>m||Response.error())));
}});
"""


def app_page(a, apps, cfg, tpl, layout):
    base, name = cfg["base_url"], a["name"]
    url = f'{base}app/{a["slug"]}/'

    chips = [("package", f'{a["image"]}:{a["version"]}')]
    if a["app_version"]:
        v = a["app_version"]
        chips.append(("commit", v if v[:1] in "vV" or not v[:1].isdigit() else "v" + v, "App version"))
    day = parse_day(a["update_at"])
    if day:
        chips.append(("calendar", f'Updated {day.day} {day:%b %Y}', f"Last updated on {day:%d %B %Y}"))
    chips += [("plug", f"port {p}") for p in a["ports"]]
    if a["arch"]:  # which CPUs it runs on, e.g. "amd64 · arm64"
        chips.append(("cpu", " · ".join(a["arch"]),
                      "Runs on " + ", ".join(ARCH_NAMES.get(x, x) for x in a["arch"])))
    if a["category"]:
        chips.append(("tag", a["category"]))
    stars = a.get("stars")
    if stars is not None:
        chips.append(("star", f"{short_num(stars)} stars", f"{stars:,} GitHub stars for the upstream project"))
    links = []
    if a["site"]:
        links.append(f'<a class="btn p" href="{e(a["site"])}" rel="noopener">{icon("external-link")}Visit project site</a>')
    if a["src"]:
        links.append(f'<a class="btn" href="{e(a["src"])}" rel="noopener">{icon("code")}View source</a>')
    links.append(f'<a class="btn" href="../../app-badge/?={e(a["slug"])}">{icon("tag")}Get badge</a>')

    # screenshots: a row of thumbnails (3 in view) under the app details; a click opens the full image.
    # Thumbnails and the popup image come from wsrv.nl (resized WebP); the <a> links the original,
    # and onerror falls back to it (e.g. a new screenshot that is not deployed yet).
    shots = ""
    if a["shots"]:
        thumbs = []
        for n, f in enumerate(a["shots"], 1):
            cap = a["captions"][n - 1] if n <= len(a["captions"]) else ""
            alt = f"{name} screenshot {n}" + (f": {cap}" if cap else "")
            size = image_size(f)
            dims = f' width="{size[0]}" height="{size[1]}"' if size else ""
            lazy = ' loading="lazy"' if n > 3 else ""
            pub = url + f.name
            thumb = wsrv(pub, w=720, output="webp", q=80, we=1)
            full = wsrv(pub, w=1920, output="webp", q=85, we=1)
            thumbs.append(
                f'<a class="gt" href="{e(f.name)}" id="shot-{n}" data-full="{e(full)}" data-cap="{e(cap)}">'
                f'<img src="{e(thumb)}" alt="{e(alt)}"{dims}{lazy} decoding="async" '
                f'onerror="this.onerror=null;this.src=\'{e(f.name)}\'"></a>')
        navs = ""
        if len(a["shots"]) > 3:
            navs = (f'<button class="nav prev" type="button" aria-label="Previous screenshots">{icon("arrow-left")}</button>'
                    f'<button class="nav next" type="button" aria-label="Next screenshots">{icon("arrow-right")}</button>')
        shots = (
            f'\n    <section class="sec gs" style="padding-left:0;padding-right:0" aria-labelledby="shots-h">\n'
            '      <h2 id="shots-h" class="sr">Screenshots</h2>\n'
            f'      <div class="gw"><div class="gal" tabindex="0">{"".join(thumbs)}</div>{navs}</div>\n'
            '    </section>')

    details = ""
    if a["svcs"] and a["ports"]:
        # one compact row per service; js/app.js swaps "localhost" for the address the visitor saved
        cards = "".join(
            f'<div class="sv" data-port="{e(port)}" data-path="{e(p)}"><span class="bd">{icon(ic)}</span>'
            f'<div class="t"><h3>{e(k)}</h3><code>{e(f"http://localhost:{port}{p}")}</code></div>'
            f'<a class="ic" href="{e(f"http://localhost:{port}{p}")}" target="_blank" rel="noopener" aria-label="Open {e(k)}">{icon("external-link")}</a>'
            f'<button class="ic" type="button" data-copy="{e(f"http://localhost:{port}{p}")}" aria-label="Copy {e(k)} URL">{icon("copy")}</button></div>'
            for k, p, ic, port in a["svcs"])
        details = (
            '\n    <section class="sec dt" style="padding-left:0;padding-right:0" aria-labelledby="det-h">\n'
            '      <h2 id="det-h" class="sr">Open the app</h2>\n'
            f'      <label class="host">{icon("server")}<span>Server address</span>'
            '<input id="host" type="text" placeholder="localhost" autocomplete="off" spellcheck="false" inputmode="url" '
            'aria-describedby="host-n"><small id="host-n">IP of your ZimaOS, CasaOS or Homeio device. Saved for every app.</small></label>\n'
            f'      <div class="svs">{cards}</div>\n    </section>')

    tabs = [("intro", "info", "Introduction", f'<div class="md">{a["intro"]}</div>')]
    if a["env"] or a["more"]:
        def row(k, v, d):
            name = e(k).replace("_", "_<wbr>")  # break long names at underscores, not mid-word
            return f'<tr><td><code>{name}</code></td><td><code>{e(v) or "—"}</code></td><td>{code_ticks(d)}</td></tr>'

        def table(title, items):
            """One table per group; the same column widths keep the tables lined up."""
            h = f'<h3 class="vgh">{e(title)}</h3>' if title else ""
            return (f'<div class="vg">{h}<div class="tw"><table>'
                    '<colgroup><col class="c1"><col class="c2"><col class="c3"></colgroup>'
                    '<thead><tr><th>Variable</th><th>Default value</th><th>Description</th></tr></thead>'
                    f'<tbody>{"".join(row(k, v, d) for k, v, d in items)}</tbody></table></div></div>')

        groups = {}
        if a["env"]:
            groups["In the app settings" if a["more"] else ""] = list(a["env"])
        for g, k, v, d in a["more"]:
            groups.setdefault(g, []).append((k, v, d))
        note = ""
        if a["more"]:
            note = ('<p class="vnote">The settings in the first table are already in the app settings. To use any other one, '
                    'open the app settings, add the variable with your value, save, and the app restarts with it. '
                    'A setting you leave out uses its default.</p>')
        tabs.append(("vars", "table", "Variables",
                     f'{note}<div class="vgs">{"".join(table(g, items) for g, items in groups.items())}</div>'))
    tabs.append(("compose", "file-code", "Docker Compose",
                 f'<div class="code"><div class="chrome"><i></i><i></i><i></i><span>docker-compose.yml</span>'
                 f'<a class="ic" href="docker-compose.yml" download="{e(a["slug"])}-docker-compose.yml" '
                 f'aria-label="Download docker-compose.yml" title="Download">{icon("download")}</a>'
                 f'<button class="ic" type="button" data-copy-from="#yml" aria-label="Copy docker-compose.yml" title="Copy">{icon("copy")}</button></div>'
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
        **cfg, "app_name": name, "desc": a["desc"],
        "icon": ph(name, a["icon_cdn"], a["icon"].name if a["icon"] else ""),
        "chips": "".join(f'<li{f" title={chr(34)}{e(c[2])}{chr(34)}" if len(c) > 2 else ""}>{icon(c[0])}{e(c[1])}</li>' for c in chips),
        "links": f'<div class="cta" style="justify-content:flex-start">{"".join(links)}</div>' if links else "",
        "shots": shots, "details": details, "tabs": tab_html, "panels": panels, "install": install,
        "related": related_html(a, apps), "pager": pager_html(a, apps),
        "problem_url": issue_url(cfg, "app-problem.yml", title=f"[{name}] ", app=name, version=a["app_version"]),
    }
    title = f'{name} – ZimaOS, CasaOS & Homeio app | {cfg["site_name"]}'
    desc = f'{a["desc"].rstrip(".")}. ' if a["desc"] else ""
    desc += f'Install it on ZimaOS, CasaOS or Homeio from the {cfg["site_name"]} community app store.'
    app_ld = {
        "@type": "SoftwareApplication", "name": name, "description": a["desc"] or desc, "url": url,
        "image": url + a["shots"][0].name if a["shots"] else base + "img/og.png",
        "applicationCategory": APP_TYPES.get(a["category"].lower(), "UtilitiesApplication"),
        "operatingSystem": "Linux (Docker)",
        **({"processorRequirement": ", ".join(a["arch"])} if a["arch"] else {}),
        **({"softwareVersion": a["app_version"]} if a["app_version"] else {}),
        **({"dateModified": str(day)} if day else {}),
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "author": {"@type": "Person", "name": cfg["author"], "url": cfg["author_url"]},
        "isPartOf": {"@id": base + "#website"},
    }
    crumbs = {"@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": 1, "name": cfg["site_name"], "item": base},
        {"@type": "ListItem", "position": 2, "name": "Apps", "item": base + "#apps"},
        {"@type": "ListItem", "position": 3, "name": name, "item": url},
    ]}
    # link previews: the first screenshot cropped to 1200x630 (the size layout.html declares)
    og = base + "img/og.png"
    if a["shots"] and a["shots"][0].suffix.lower() not in (".gif", ".svg"):
        og = wsrv(url + a["shots"][0].name, w=1200, h=630, fit="cover", a="top", output="jpg", q=85)
    head = {**cfg, "root": "../../", "title": title, "description": desc, "url": url,
            "og_image": og, "og_alt": f'{name} on {cfg["site_name"]}',
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
            {"src": "favicon/web-app-manifest-192x192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable"},
            {"src": "favicon/web-app-manifest-512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"},
        ],
    }, indent=2, ensure_ascii=False) + "\n"


def not_found_page(apps, cfg, layout):
    """404.html. GitHub Pages serves it for any missing path, so every link is absolute."""
    base = cfg["base_url"]
    cards = "".join(
        f'<a class="card" href="{base}app/{a["slug"]}/" data-name="{e(a["name"].lower())}">'
        f'{ph(a["name"], a["icon_cdn"], base + a["icon_url"] if a["icon_url"] else "")}<h3>{e(a["name"])}</h3></a>'
        for a in apps)
    content = (
        '<div class="wrap">\n'
        f'  <div class="top"><a class="logo" href="{base}">{e(cfg["site_name"])}</a>'
        f'<a class="back" href="{base}#apps">{icon("arrow-left")}All apps</a></div>\n'
        '  <main id="main" tabindex="-1" data-page="404">\n'
        '    <section class="sec nf" aria-labelledby="nf-h">\n'
        '      <p class="nf-code" aria-hidden="true">404</p>\n'
        '      <h1 id="nf-h">Page not found</h1>\n'
        '      <p class="lead">This page does not exist, or it moved. Try one of the apps below, or go back to the start.</p>\n'
        f'      <p class="nf-links"><a class="btn p" href="{base}">{icon("arrow-left")}Go to the homepage</a>'
        f'<a class="btn" href="{base}#apps">{icon("grid")}Browse all apps</a></p>\n'
        '    </section>\n'
        + (f'    <section class="sec" aria-label="Apps"><div class="grid">{cards}</div></section>\n' if cards else "")
        + '  </main>\n</div>')
    ld = {"@context": "https://schema.org", "@type": "WebPage", "name": "Page not found", "url": base + "404.html"}
    head = {**cfg, "root": base, "url": base, "og_image": base + "img/og.png",
            "title": f'Page not found – {cfg["site_name"]}', "description": "This page does not exist.",
            "og_alt": cfg["site_name"], "jsonld": js(ld)}
    html_out = page(layout, content, head)
    return html_out.replace('<meta name="robots" content="index,follow,max-image-preview:large,max-snippet:-1,max-video-preview:-1">',
                            '<meta name="robots" content="noindex">')


def badge_page(apps, cfg, layout):
    """app-badge/: pick an app, see its badge and copy the Markdown or HTML.
    The badges themselves (app-badge/<slug>.svg) are drawn by .github/scripts/app_badges.py.
    The chosen app comes from the query (?=affine), so js/badge.js fills in the details."""
    base = cfg["base_url"]
    url = base + "app-badge/"
    cards = "".join(
        f'<a class="card" href="?={e(a["slug"])}" data-name="{e(a["name"].lower())}">'
        f'{ph(a["name"], a["icon_cdn"], "../" + a["icon_url"] if a["icon_url"] else "")}<h3>{e(a["name"])}</h3></a>'
        for a in apps)
    data = {"base": base, "site": cfg["site_name"], "apps": {a["slug"]: a["name"] for a in apps}}

    def snippet(id_, title):
        return (f'<div class="code bsn"><div class="chrome"><i></i><i></i><i></i><span>{title}</span>'
                f'<button class="ic" type="button" data-copy-from="#{id_}" aria-label="Copy {title}">{icon("copy")}</button></div>'
                f'<pre id="{id_}"><code></code></pre></div>')

    content = (
        '<div class="wrap">\n'
        f'  <div class="top"><a class="logo" href="../">{e(cfg["site_name"])}</a>'
        f'<a class="back" href="../#apps">{icon("arrow-left")}All apps</a></div>\n'
        '  <main id="main" tabindex="-1" data-page="badge">\n'
        '    <section class="bhero" aria-labelledby="b-h">\n'
        '      <div class="btop">\n'
        '        <div><h1 id="b-h">App badges</h1>\n'
        f'        <p class="lead">Show that an app can be installed from {e(cfg["site_name"])}. Pick an app, copy the Markdown '
        'and paste it into a README. The badge links to the app page.</p></div>\n'
        '        <div class="bprev" id="bprev" data-theme="dark" hidden>\n'
        '          <a class="bstage" id="bimg" href="#"><img class="bs-d" alt="" height="80">'
        '<img class="bs-l" alt="" height="80"></a>\n'
        '          <div class="bthm" role="radiogroup" aria-label="Badge theme">'
        '<button type="button" role="radio" data-t="dark" aria-checked="true">Dark</button>'
        '<button type="button" role="radio" data-t="light" aria-checked="false">Light</button>'
        '<button type="button" role="radio" data-t="auto" aria-checked="false">Auto</button></div>\n'
        '          <p class="bnote" id="bnote"></p>\n'
        '        </div>\n'
        '      </div>\n'
        '      <div class="bsel" id="bsel" hidden>\n'
        f'        {snippet("b-md", "Markdown")}\n'
        f'        {snippet("b-html", "HTML")}\n'
        f'        {snippet("b-url", "Image URL")}\n'
        '      </div>\n'
        '      <p class="none" id="bnone" hidden></p>\n'
        '    </section>\n'
        '    <section class="sec" style="padding-left:0;padding-right:0" aria-labelledby="ba-h">\n'
        '      <div class="srch"><div><h2 id="ba-h">Choose an app</h2></div>'
        f'<label class="sf">{icon("search")}<span class="sr">Search apps</span>'
        '<input id="q" type="search" placeholder="Search apps" autocomplete="off"><kbd class="kb" aria-hidden="true">/</kbd></label></div>\n'
        f'      <div class="grid">{cards}</div>\n'
        '      <p class="none" id="none" hidden>No app matches that search.</p>\n'
        '    </section>\n'
        f'    <script type="application/json" id="bdata">{js(data)}</script>\n'
        '  </main>\n</div>')
    ld = {"@context": "https://schema.org", "@type": "WebPage", "name": "App badges", "url": url,
          "isPartOf": {"@id": base + "#website"}}
    head = {**cfg, "root": "../", "url": url, "og_image": base + "img/og.png",
            "title": f'App badges – {cfg["site_name"]}',
            "description": f'Get a badge for any app in {cfg["site_name"]} to show in your README.',
            "og_alt": cfg["site_name"], "jsonld": js(ld)}
    return page(layout, content, head)


def redirect_page(target, base):
    """A tiny page that sends the visitor on, for folders that have no page of their own."""
    t = e(target)
    return ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            f'<title>Redirecting…</title>\n<meta name="robots" content="noindex">\n'
            f'<link rel="canonical" href="{e(base)}">\n<meta http-equiv="refresh" content="0; url={t}">\n'
            f'<script>location.replace("{t}")</script>\n</head>\n'
            f'<body><p><a href="{t}">Go to the homepage</a></p></body>\n</html>\n')


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
    cfg["request_url"] = issue_url(cfg, "app-request.yml", title="[App request] ")

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
    dates = git_dates()
    if not dates:
        warn("no git history: the Newest and Recently updated sorts fall back to A-Z")
    for a in apps:
        a["added"], a["updated"] = dates.get(a["folder"].name, (0, 0))
    stats = github_stats(apps)
    for a in apps:
        st = stats.get(github_repo(a["src"])) or {}
        a["stars"], a["forks"] = st.get("stars"), st.get("forks")
    for a in apps:
        a["icon_url"] = f'app/{a["slug"]}/{a["icon"].name}' if a["icon"] else ""
        # one 192px WebP per icon (sharp at the largest 96px size), the same URL on every page so it caches
        a["icon_cdn"] = wsrv(cfg["base_url"] + a["icon_url"], w=192, h=192, output="webp", q=85) if a["icon"] else ""

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
        # the compose file as shown on the page (passwords already replaced), for the download button
        (dest / "docker-compose.yml").write_text(a["compose"] + "\n", encoding="utf-8", newline="\n")
        (dest / "index.html").write_text(app_page(a, apps, cfg, tpl_app, layout), encoding="utf-8")

    (out / "index.html").write_text(home_page(apps, cfg, tpl_index, layout), encoding="utf-8")
    (out / "404.html").write_text(not_found_page(apps, cfg, layout), encoding="utf-8")
    (out / "app-badge").mkdir(parents=True, exist_ok=True)
    (out / "app-badge" / "index.html").write_text(badge_page(apps, cfg, layout), encoding="utf-8")
    # /app/ has no page of its own: send people to the homepage
    (out / "app").mkdir(parents=True, exist_ok=True)
    (out / "app" / "index.html").write_text(redirect_page("../", cfg["base_url"]), encoding="utf-8")
    # custom domain: keep it with the site (GitHub Pages reads it from the repo settings too)
    host = re.match(r"https?://([^/]+)/$", cfg["base_url"])
    if host and not host.group(1).endswith("github.io"):
        (out / "CNAME").write_text(host.group(1) + "\n", encoding="utf-8")
    (out / "sitemap.xml").write_text(sitemap(apps, cfg["base_url"]), encoding="utf-8")
    (out / "robots.txt").write_text(f'User-agent: *\nAllow: /\n\nSitemap: {cfg["base_url"]}sitemap.xml\n', encoding="utf-8")
    (out / "manifest.webmanifest").write_text(manifest(cfg), encoding="utf-8")
    # browsers ask for /favicon.ico on their own, so keep a copy at the root too
    shutil.copyfile(STATIC / "favicon" / "favicon.ico", out / "favicon.ico")
    (out / "feed.xml").write_text(feed(apps, cfg), encoding="utf-8")
    (out / "sw.js").write_text(service_worker(time.strftime("%Y%m%d%H%M%S")), encoding="utf-8")
    print(f"Built {len(apps)} app page(s) into {out}")


if __name__ == "__main__":
    main()
