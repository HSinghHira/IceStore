#!/usr/bin/env python3
"""Build the IceStore website from the Apps/ folder.

    pip install -r site/requirements.txt
    python site/build.py            # writes ./_site
    python -m http.server -d _site  # preview at http://localhost:8000

    python site/build.py --out dist --no-clean   # add the site to an existing store bundle

Every folder in Apps/ becomes a page at app/<folder>/. What is read from it:

  docker-compose.yml  name, tagline, image, ports, variables, category (x-casaos block)
  README.md           the Introduction tab; optional front matter (see README)
  icon.*              the app icon
  screenshot-*.*      the screenshot slider, in number order
"""
import argparse
import html
import json
import re
import shutil
import sys
from pathlib import Path

import markdown
import yaml

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
IMG_EXT = {".png", ".webp", ".jpg", ".jpeg", ".gif", ".svg"}
SECRET = r"(?:pass(?:word)?|secret|token|api[_-]?key|private[_-]?key)"
DEFAULTS = {
    "site_name": "IceStore",
    "tagline": "3rd-Party Community AppStore for Zima OS, Casa OS and Homeio",
    "repo": "https://github.com/HSinghHira/IceStore",
    "base_url": "https://git.hsinghhira.me/IceStore/",
    "author": "Harman Singh Hira",
    "author_url": "https://github.com/HSinghHira",
}


def warn(msg):
    print(f"::warning::{msg}")  # shows as an annotation in GitHub Actions


def text(v, keep_lines=False):
    """x-casaos strings are plain text or {en_US: text}."""
    if isinstance(v, dict):
        v = v.get("en_US") or next(iter(v.values()), "")
    v = str(v or "").strip()
    return v if keep_lines else re.sub(r"\s+", " ", v)


def front_matter(raw):
    raw = raw.replace("\r\n", "\n").lstrip("\ufeff")
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


def esc(s):
    s = html.escape(str(s), quote=False)
    return re.sub(r"`([^`]+)`", r"<code>\1</code>", s)


def natural(p):
    return [int(x) if x.isdigit() else x.lower() for x in re.split(r"(\d+)", p.name)]


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

    name = fm.get("name") or text(meta.get("title")) or folder.name
    tagline = fm.get("tagline") or text(meta.get("tagline"))
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
    env = [[esc(k), esc(redact(k, v)), esc(notes.get(k, ""))] for k, v in env_pairs(main.get("environment"))]

    path = str(meta.get("index") or "/")
    default_svcs = [["Web UI", path, "globe"]] if ports else []
    svcs = []
    for s in fm.get("services", default_svcs):
        if isinstance(s, dict):
            s = [s.get("name"), s.get("path", "/"), s.get("icon", "globe")]
        svcs.append([str(s[0]), str(s[1]) if str(s[1]).startswith("/") else "/" + str(s[1]), s[2] if len(s) > 2 else "globe"])

    repo = fm.get("source") or meta.get("repo") or ""
    site = fm.get("site") or repo
    icon = next((p for p in sorted(folder.glob("icon.*"), key=natural) if p.suffix.lower() in IMG_EXT), None)
    shots = [p for p in sorted(folder.glob("screenshot*"), key=natural) if p.suffix.lower() in IMG_EXT]
    if not icon:
        warn(f"Apps/{folder.name}: no icon.png, using a letter tile")
    if not shots:
        warn(f"Apps/{folder.name}: no screenshot-*.png, the slider is hidden")

    return {
        "slug": slug, "folder": folder, "icon": icon, "shots": shots,
        "page": {
            "name": name, "desc": tagline, "icon": icon.name if icon else "",
            "shots": [s.name for s in shots], "image": image, "version": version,
            "ports": ports, "category": fm.get("category") or text(meta.get("category")),
            "site": site, "src": repo or site, "svcs": svcs, "env": env,
            "compose": redact_text(raw).rstrip(), "intro": intro,
        },
    }


def js(obj):
    return json.dumps(obj, ensure_ascii=False).replace("</", "<\\/")


def render(tpl, marker, data, tokens, js_tokens=()):
    s = tpl
    for k, v in tokens.items():
        s = s.replace("{{%s}}" % k, json.dumps(v)[1:-1] if k in js_tokens else html.escape(str(v)))
    s = s.replace(marker, js(data))
    left = set(re.findall(r"\{\{\w+\}\}", s))
    if left:
        raise ValueError(f"unfilled template tokens: {sorted(left)}")
    return s


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
    # one short link per OS; the workflow publishes the matching file under each name
    for key, name in (("zimaos_url", "ZimaOS"), ("casaos_url", "CasaOS"), ("homeio_url", "Homeio")):
        cfg[key] = cfg["base_url"] + name

    apps, errors = [], []
    for folder in sorted(p for p in (ROOT / "Apps").iterdir() if p.is_dir() and not p.name.startswith(".")):
        try:
            apps.append(load_app(folder))
        except Exception as e:  # report every broken app at once
            errors.append(f"Apps/{folder.name}: {e}")
    if errors:
        for e in errors:
            print(f"::error::{e}")
        sys.exit(1)
    apps.sort(key=lambda a: a["page"]["name"].lower())

    if out.exists() and not args.no_clean:
        shutil.rmtree(out)
    out.mkdir(parents=True, exist_ok=True)
    (out / ".nojekyll").write_text("")

    tpl_index = (HERE / "templates" / "index.html").read_text(encoding="utf-8")
    tpl_app = (HERE / "templates" / "app.html").read_text(encoding="utf-8")
    base = {k: cfg[k] for k in ("site_name", "tagline", "repo", "author", "author_url", "zimaos_url", "casaos_url", "homeio_url")}

    cards = []
    for a in apps:
        dest = out / "app" / a["slug"]
        dest.mkdir(parents=True, exist_ok=True)
        for f in ([a["icon"]] if a["icon"] else []) + a["shots"]:
            shutil.copy(f, dest / f.name)
        p = a["page"]
        page = render(tpl_app, "/*APP*/{}", p, {**base, "app_name": p["name"], "desc": p["desc"]})
        (dest / "index.html").write_text(page, encoding="utf-8")
        cards.append([p["name"], f"app/{a['slug']}/{p['icon']}" if p["icon"] else "", a["slug"]])

    (out / "index.html").write_text(
        render(tpl_index, "/*APPS*/[]", cards, base, js_tokens=("zimaos_url", "casaos_url", "homeio_url")), encoding="utf-8")
    print(f"Built {len(apps)} app page(s) into {out}")


if __name__ == "__main__":
    main()
