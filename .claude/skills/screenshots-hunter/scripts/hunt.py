"""Screenshots Hunter helper for IceStore. Run from the repo root.

    python .claude/skills/screenshots-hunter/scripts/hunt.py list [--all] [--json]
    python .claude/skills/screenshots-hunter/scripts/hunt.py find <app> [--max 25]
    python .claude/skills/screenshots-hunter/scripts/hunt.py add <app> <image> [<image> ...]
                                                [--captions "Home|Editor"] [--replace]
    python .claude/skills/screenshots-hunter/scripts/hunt.py skip <app> "reason"

list   Apps with no screenshot-* file, with their source repo and site. Apps
       already skipped in .task/screenshots-missing.md are left out (--all
       shows them too, with the reason).
find   Downloads candidate images for one app into .task/shots/<app>/ (git
       ignored): images in upstream's README, screenshot-like files in the
       repo tree, and og:image / <img> on the project site. Badges, logos,
       icons and SVGs are dropped. Prints one line per candidate with its size.
       Look at every candidate before using it: this script can't tell a UI
       screenshot from a diagram.
add    Turns the chosen images into Apps/<app>/screenshot-N.png (PNG, at most
       1920 px wide, first frame of a GIF, recompressed under ~1.5 MB), then
       writes x-casaos screenshot_link + thumbnail in docker-compose.yml and
       the captions in README.md front matter (screenshots: [...]). New files
       are numbered after the existing ones; --replace removes those first.
skip   Records that an app has no usable screenshots, with the reason, so the
       next list leaves it out.
"""
import argparse, hashlib, html, io, json, os, re, subprocess, sys, urllib.parse, urllib.request

try:
    import yaml
    from PIL import Image
except ImportError:
    sys.exit("needs pyyaml and pillow: pip install pyyaml pillow")

ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip()
APPS = os.path.join(ROOT, "Apps")
TASK = os.path.join(ROOT, ".task")
SKIPS = os.path.join(TASK, "screenshots-missing.md")
CDN = "https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/"
IMG_EXT = (".png", ".jpg", ".jpeg", ".webp", ".gif")
SHOT_GLOB_EXT = IMG_EXT + (".svg",)
UA = {"User-Agent": "IceStore-screenshots-hunter"}
# URL or path parts that are never app screenshots.
JUNK = re.compile(
    r"shields\.io|badge|badgen|codecov|coveralls|travis-ci|circleci|github\.com/[^/]+/[^/]+/(actions|workflows)|"
    r"buymeacoffee|ko-fi|liberapay|opencollective|patreon|paypal|sponsor|star-history|starchart|contrib\.rocks|"
    r"contributors-img|repobeats|api\.star|hits\.|visitor|counter|translate\.|weblate|crowdin|"
    r"(^|[/_.-])(logo|logos|icon|icons|favicon|avatar|banner|brand|emoji|flag|qr)([/_.-]|$)|"
    r"docker-?hub|discord|reddit|twitter|mastodon|telegram|matrix\.to|apple-touch|android-chrome",
    re.I)
SHOTISH = re.compile(r"screen|shot|scrot|preview|demo|dashboard|overview|ui[_/-]|showcase|gallery|images?/|docs?/|assets?/|media/", re.I)


# ---------- reading an app ----------

def front_matter(app):
    p = os.path.join(APPS, app, "README.md")
    if not os.path.exists(p):
        return {}, ""
    text = open(p, encoding="utf-8").read()
    m = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n", text, re.S)
    return (yaml.safe_load(m.group(1)) or {}) if m else {}, text


def compose_meta(app):
    p = os.path.join(APPS, app, "docker-compose.yml")
    try:
        return (yaml.safe_load(open(p, encoding="utf-8")) or {}).get("x-casaos") or {}
    except Exception:
        return {}


def shots_of(app):
    d = os.path.join(APPS, app)
    return sorted((f for f in os.listdir(d) if f.lower().startswith("screenshot") and f.lower().endswith(SHOT_GLOB_EXT)),
                  key=lambda f: [int(x) if x.isdigit() else x for x in re.split(r"(\d+)", f)])


def gh_repo(url):
    m = re.match(r"https?://(?:www\.)?github\.com/([^/\s]+)/([^/\s#?]+)", str(url or ""))
    return f"{m.group(1)}/{m.group(2).removesuffix('.git')}" if m else None


def sources(app):
    fm, _ = front_matter(app)
    meta = compose_meta(app)
    src = fm.get("source") or meta.get("repo")
    site = fm.get("site") or meta.get("docs")
    return src, site


def skipped():
    out = {}
    if os.path.exists(SKIPS):
        for line in open(SKIPS, encoding="utf-8"):
            m = re.match(r"-\s*(\S+)\s*[:—-]+\s*(.*)", line.strip())
            if m:
                out[m.group(1)] = m.group(2)
    return out


# ---------- fetching ----------

def fetch(url, limit=25 * 1024 * 1024):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        data = r.read(limit + 1)
        if len(data) > limit:
            raise ValueError("too big")
        return data, r.headers.get("Content-Type", ""), r.geturl()


def gh(*args):
    r = subprocess.run(["gh", "api", *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


def repo_images(repo):
    """Image URLs from the README and screenshot-like files in the tree."""
    found = []
    info = gh(f"repos/{repo}", "-q", ".default_branch")
    branch = (info or "main").strip() or "main"
    readme_path = (gh(f"repos/{repo}/readme", "-q", ".path") or "README.md").strip()
    raw_base = f"https://raw.githubusercontent.com/{repo}/{branch}/"
    readme_dir = raw_base + (os.path.dirname(readme_path) + "/" if "/" in readme_path else "")
    try:
        text = fetch(raw_base + readme_path)[0].decode("utf-8", "replace")
    except Exception:
        text = ""
    refs = re.findall(r"!\[[^\]]*\]\(\s*<?([^)\s>]+)", text)
    refs += re.findall(r"<img[^>]+src=[\"']([^\"']+)", text, re.I)
    refs += re.findall(r"<source[^>]+srcset=[\"']([^\"'\s]+)", text, re.I)
    refs += re.findall(r"^\[[^\]]+\]:\s*(\S+\.(?:png|jpe?g|webp|gif))", text, re.I | re.M)
    for ref in refs:
        ref = html.unescape(ref)
        if ref.startswith("//"):
            ref = "https:" + ref
        if not re.match(r"https?://", ref):
            ref = urllib.parse.urljoin(readme_dir, ref.lstrip("./") if ref.startswith("./") else ref)
        ref = re.sub(r"https://github\.com/([^/]+/[^/]+)/(?:blob|raw)/", r"https://raw.githubusercontent.com/\1/", ref)
        found.append(("readme", ref))
    tree = gh(f"repos/{repo}/git/trees/{branch}?recursive=1", "-q", ".tree[].path") or ""
    for path in tree.splitlines():
        low = path.lower()
        if not low.endswith(IMG_EXT) or re.search(r"node_modules|/test|fixtures|/vendor/|/locales?/|/flags?/", low):
            continue
        if SHOTISH.search(path) and not JUNK.search(path):
            found.append(("repo", raw_base + urllib.parse.quote(path)))
    return found


def site_images(site):
    found = []
    try:
        data, ctype, final = fetch(site, limit=4 * 1024 * 1024)
    except Exception:
        return found
    if "html" not in ctype:
        return found
    page = data.decode("utf-8", "replace")
    for pat in (r"<meta[^>]+(?:property|name)=[\"'](?:og:image|twitter:image)[\"'][^>]+content=[\"']([^\"']+)",
                r"<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+(?:property|name)=[\"'](?:og:image|twitter:image)",
                r"<img[^>]+src=[\"']([^\"']+)"):
        for ref in re.findall(pat, page, re.I):
            found.append(("site", urllib.parse.urljoin(final, html.unescape(ref))))
    return found


# ---------- commands ----------

def cmd_list(a):
    skips = skipped()
    rows = []
    for app in sorted(os.listdir(APPS)):
        if not os.path.isdir(os.path.join(APPS, app)) or shots_of(app):
            continue
        if app in skips and not a.all:
            continue
        src, site = sources(app)
        rows.append({"app": app, "source": src, "site": site, "skipped": skips.get(app)})
    if a.json:
        print(json.dumps(rows, indent=1))
        return
    total = sum(1 for x in os.listdir(APPS) if os.path.isdir(os.path.join(APPS, x)))
    print(f"{len(rows)} of {total} apps have no screenshots" + ("" if a.all else f" ({len(skips)} more skipped earlier)"))
    for r in rows:
        tail = f"  [skipped: {r['skipped']}]" if r["skipped"] else ""
        print(f"  {r['app']:<28} {r['source'] or '-'}  {r['site'] if r['site'] != r['source'] else ''}{tail}")


def cmd_find(a):
    app = a.app
    if not os.path.isdir(os.path.join(APPS, app)):
        sys.exit(f"no Apps/{app}")
    src, site = sources(app)
    cands = []
    repo = gh_repo(src) or gh_repo(site)
    if repo:
        cands += repo_images(repo)
    for s in {site, src}:
        if s and not gh_repo(s):
            cands += site_images(s)
    out = os.path.join(TASK, "shots", app)
    os.makedirs(out, exist_ok=True)
    for f in os.listdir(out):
        os.remove(os.path.join(out, f))
    seen, rows, n = set(), [], 0
    for origin, url in cands:
        if url in seen or JUNK.search(url) or url.lower().split("?")[0].endswith(".svg"):
            continue
        seen.add(url)
        if n >= a.max:
            break
        try:
            data, ctype, _ = fetch(url)
            im = Image.open(io.BytesIO(data))
            w, h = im.size
        except Exception:
            continue
        if w < 500 or h < 300:          # icons, avatars, tiny thumbnails
            continue
        digest = hashlib.sha1(data).hexdigest()
        if digest in seen:              # same file under another URL
            continue
        seen.add(digest)
        n += 1
        ext = (im.format or "png").lower().replace("jpeg", "jpg")
        name = f"cand-{n:02d}.{ext}"
        open(os.path.join(out, name), "wb").write(data)
        flags = []
        if h > w:
            flags.append("portrait")
        if getattr(im, "is_animated", False):
            flags.append("animated")
        if w < 1000:
            flags.append("small")
        rows.append({"file": os.path.relpath(os.path.join(out, name), ROOT).replace("\\", "/"), "w": w, "h": h,
                     "kb": len(data) // 1024, "from": origin, "url": url, "flags": flags})
    json.dump(rows, open(os.path.join(out, "candidates.json"), "w", encoding="utf-8"), indent=1)
    print(f"{app}: source {src or '-'}, site {site or '-'}")
    if not rows:
        print("  no candidates found: try the project's docs/demo pages by hand, or skip it")
    for r in rows:
        print(f"  {r['file']}  {r['w']}x{r['h']}  {r['kb']} KB  [{r['from']}] {' '.join(r['flags'])}\n      {r['url']}")


def to_png(src, dst):
    im = Image.open(src)
    if getattr(im, "is_animated", False):
        im.seek(0)
    im = im.convert("RGBA") if im.mode in ("RGBA", "LA", "P") else im.convert("RGB")
    if im.mode == "RGBA" and im.getextrema()[3][0] == 255:
        im = im.convert("RGB")
    for width in (1920, 1600, 1280, 1024):
        out = im
        if im.width > width:
            out = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
        buf = io.BytesIO()
        out.save(buf, "PNG", optimize=True)
        if buf.tell() <= 1_500_000:
            break
    open(dst, "wb").write(buf.getvalue())
    return out.size, buf.tell() // 1024


def set_compose_links(app, names):
    p = os.path.join(APPS, app, "docker-compose.yml")
    text = open(p, encoding="utf-8").read()
    # drop any old screenshot_link list, thumbnail line and their commented forms (top-level x-casaos only)
    text = re.sub(r"^  #?\s*screenshot_link:.*\n(?:  #?\s*- .*\n)*", "", text, flags=re.M)
    text = re.sub(r"^  #?\s*thumbnail:.*\n", "", text, flags=re.M)
    block = "  screenshot_link:\n" + "".join(f"    - {CDN}{app}/{n}\n" for n in names) + f"  thumbnail: {CDN}{app}/{names[0]}\n"
    # after the top-level x-casaos icon line (two-space indent)
    m = re.search(r"^x-casaos:\n(?:.*\n)*?^  icon: .*\n", text, re.M)
    if not m:
        sys.exit("could not find the top-level x-casaos icon line; add screenshot_link by hand")
    text = text[:m.end()] + block + text[m.end():]
    open(p, "w", encoding="utf-8", newline="\n").write(text)


def set_captions(app, captions):
    p = os.path.join(APPS, app, "README.md")
    text = open(p, encoding="utf-8").read()
    m = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n", text, re.S)
    if not m:
        return
    fm = m.group(1)
    line = "screenshots: [" + ", ".join(captions) + "]"
    if re.search(r"^screenshots:.*$", fm, re.M):
        fm = re.sub(r"^screenshots:.*$", line, fm, flags=re.M)
    elif re.search(r"^source:.*$", fm, re.M):
        fm = re.sub(r"^(source:.*)$", r"\1\n" + line.replace("\\", "\\\\"), fm, count=1, flags=re.M)
    else:
        fm = line + "\n" + fm
    open(p, "w", encoding="utf-8", newline="\n").write("---\n" + fm + "\n---\n" + text[m.end():])


def cmd_add(a):
    app, d = a.app, os.path.join(APPS, a.app)
    if not os.path.isdir(d):
        sys.exit(f"no Apps/{app}")
    if a.replace:
        for f in shots_of(app):
            os.remove(os.path.join(d, f))
    existing = shots_of(app)
    n = len(existing)
    names = list(existing)
    for img in a.images:
        n += 1
        name = f"screenshot-{n}.png"
        size, kb = to_png(img, os.path.join(d, name))
        names.append(name)
        print(f"  {name}: {size[0]}x{size[1]}, {kb} KB  <- {img}")
    set_compose_links(app, names)
    fm, _ = front_matter(app)
    caps = [str(c) for c in (fm.get("screenshots") or [])] if not a.replace else []
    new = [c.strip() for c in a.captions.split("|")] if a.captions else []
    if new or caps:
        caps = (caps + new)[:len(names)]
        set_captions(app, caps)
    chk = subprocess.run([sys.executable, os.path.join(ROOT, ".claude", "skills", "icestore", "scripts", "check_app.py"), ROOT, app],
                         capture_output=True, text=True)
    print("\n".join(l for l in chk.stdout.splitlines() if l.startswith(("ERROR", "WARN")) or "error(s)" in l))


def cmd_skip(a):
    os.makedirs(TASK, exist_ok=True)
    lines = open(SKIPS, encoding="utf-8").read().splitlines() if os.path.exists(SKIPS) else \
        ["# Apps with no usable screenshots (Screenshots Hunter). One line each: - app: reason", ""]
    lines = [l for l in lines if not re.match(rf"-\s*{re.escape(a.app)}\s*:", l)]
    lines.append(f"- {a.app}: {a.reason}")
    open(SKIPS, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print(f"skipped {a.app}: {a.reason}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("list"); p.add_argument("--all", action="store_true"); p.add_argument("--json", action="store_true")
    p = sub.add_parser("find"); p.add_argument("app"); p.add_argument("--max", type=int, default=25)
    p = sub.add_parser("add"); p.add_argument("app"); p.add_argument("images", nargs="+")
    p.add_argument("--captions", default=""); p.add_argument("--replace", action="store_true")
    p = sub.add_parser("skip"); p.add_argument("app"); p.add_argument("reason")
    a = ap.parse_args()
    {"list": cmd_list, "find": cmd_find, "add": cmd_add, "skip": cmd_skip}[a.cmd](a)


if __name__ == "__main__":
    main()
