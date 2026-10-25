#!/usr/bin/env python3
"""Draw the top of README.md as SVGs that look like the website's home page.

    pip install -r site/requirements.txt pillow fonttools
    python .github/scripts/readme_svgs.py

GitHub shows README SVGs as plain images: animation works, but links, scripts, web
fonts and outside images inside them do not. So the site's fonts are turned into
outlines (downloaded once into ~/.cache/icestore-readme), icons are embedded, and each
clickable part (a store, an app) is its own SVG wrapped in a link in README.md.

Every piece is cut from one 1000-unit-wide page with black edges, so at their README
widths (100%, 33.33% or 25%) they stack into one picture:

  readme/hero.svg            pill, wordmark with icicles and sparkles, tagline
  readme/marquee.svg         two rows of app icons moving in opposite directions
  readme/stores.svg          "Add IceStore to your OS" title
  readme/store-<os>.svg      one card per OS, linked to its install steps on the site
  readme/apps.svg            "All apps" title, linked to the app list on the site
  readme/apps/<slug>.svg     one card per app, linked to its page on the site
  readme/help.svg            "Missing an app?" panel and footer, linked to a new issue

README.md is rewritten between the README-SVGS markers.
"""
import base64
import functools
import html
import io
import json
import math
import os
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "site"))
from build import DEFAULTS, HERE as SITE, ICONS, OSES, hue, load_app  # noqa: E402

OUT = ROOT / "readme"
README = ROOT / "README.md"
START, END = "<!-- README-SVGS:START -->", "<!-- README-SVGS:END -->"
CACHE = Path(os.environ.get("ICESTORE_CACHE", Path.home() / ".cache" / "icestore-readme"))
FONTS_REV = "e7db6ca603fd4862010383ff17ffd6cc4ffac1c0"  # google/fonts commit, so the outlines never change by surprise
FONTS = {  # name: (file in google/fonts/ofl, axis values); the site uses Unbounded 800 and Inter 400-700
    "display": ("unbounded/Unbounded[wght].ttf", {"wght": 800}),
    "regular": ("inter/Inter[opsz,wght].ttf", {"wght": 400, "opsz": 14}),
    "medium": ("inter/Inter[opsz,wght].ttf", {"wght": 500, "opsz": 32}),
    "semi": ("inter/Inter[opsz,wght].ttf", {"wght": 600, "opsz": 14}),
}
OS_NOTES = {"zimaos": "Reads the store listing directly.", "casaos": "Uses a zip archive of the store.",
            "homeio": "Uses the same zip as CasaOS."}

# colours from site/static/css/style.css
CARD, LINE, MUT, DIM = "rgba(255,255,255,.035)", "rgba(255,255,255,.09)", "rgba(255,255,255,.58)", "rgba(255,255,255,.35)"
AC, AC2, INK = "#4cc9f0", "#a5e8ff", "#031219"

W = 1000           # every piece is a slice of a page this wide
P, G = 30, 20      # side padding and gap between cards (G >= 2P/3 keeps each card inside its own slice)
R = 28             # corner radius of the whole picture
COLS = 4           # app cards per row
CARD_H = 96        # app card height
STYLE = "@media(prefers-reduced-motion:reduce){*{animation:none!important}}"


def e(s):
    return html.escape(str(s))


def num(v):
    return f"{v:.1f}".rstrip("0").rstrip(".")


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "IceStore-readme-svgs"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


# -- text as outlines ---------------------------------------------------------

class Face:
    def __init__(self, name):
        file, axes = FONTS[name]
        static = CACHE / f"{name}-{FONTS_REV[:7]}.ttf"
        if not static.exists():
            CACHE.mkdir(parents=True, exist_ok=True)
            src = CACHE / f"{FONTS_REV[:7]}-{Path(file).name}"
            if not src.exists():
                src.write_bytes(fetch(f"https://cdn.jsdelivr.net/gh/google/fonts@{FONTS_REV}/ofl/{urllib.parse.quote(file)}"))
            instancer.instantiateVariableFont(TTFont(src), axes).save(static)
        f = TTFont(static)
        self.cmap, self.glyphs, self.hmtx = f.getBestCmap(), f.getGlyphSet(), f["hmtx"]
        upm = f["head"].unitsPerEm
        self.upm, self.cap = upm, (getattr(f["OS/2"], "sCapHeight", 0) or upm * .7) / upm
        self.asc, self.desc = f["hhea"].ascent / upm, -f["hhea"].descent / upm

    def gid(self, ch):
        return self.cmap.get(ord(ch)) or self.cmap[ord("?")]

    def width(self, s, size, track=0):
        return sum(self.hmtx[self.gid(c)][0] for c in s) * size / self.upm + track * size * max(len(s) - 1, 0)

    def d(self, s, size, x, y, track=0):
        pen, k = SVGPathPen(self.glyphs, ntos=num), size / self.upm
        for c in s:
            g = self.gid(c)
            self.glyphs[g].draw(TransformPen(pen, (k, 0, 0, -k, x, y)))
            x += self.hmtx[g][0] * k + track * size
        return pen.getCommands()


@functools.cache
def face(name):
    return Face(name)


def text(font, s, size, x, y, fill="#fff", anchor="start", track=0):
    f = face(font)
    x -= {"start": 0, "middle": .5, "end": 1}[anchor] * f.width(s, size, track)
    return f'<path fill="{fill}" d="{f.d(s, size, x, y, track)}"/>'


def fit(font, s, size, max_w):
    """Shrink the size until the text fits."""
    return min(size, size * max_w / face(font).width(s, size))


def wrap(font, s, size, max_w, lines=2):
    """Break into at most `lines` lines; cut the last with … when it still does not fit."""
    f, words, out = face(font), s.split(), []
    while words and len(out) < lines:
        line = words.pop(0)
        while words and f.width(f"{line} {words[0]}", size) <= max_w:
            line += " " + words.pop(0)
        out.append(line)
    for i, line in enumerate(out):
        if f.width(line, size) > max_w or (i == len(out) - 1 and words):
            while line and f.width(line + "…", size) > max_w:
                line = line[:-1].rstrip()
            out[i] = line + "…"
    return out


# -- shapes ---------------------------------------------------------------------

def rect(x, y, w, h, rx=0, fill="none", stroke=None, extra=""):
    s = f' stroke="{stroke}"' if stroke else ""
    return f'<rect x="{num(x)}" y="{num(y)}" width="{num(w)}" height="{num(h)}" rx="{num(rx)}" fill="{fill}"{s}{extra}/>'


def icon(n, x, y, size, color):
    """One of the site's line icons (build.ICONS, 24x24, stroke 2)."""
    return (f'<g transform="translate({num(x)},{num(y)}) scale({size / 24:.4f})" fill="none" stroke="{color}" '
            f'stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{ICONS[n]}</g>')


def clip_round(w, h, rx_top, rx_bottom):
    """Path of a w x h box with its own corner radii (for rounding the picture's outer corners)."""
    t, b = rx_top, rx_bottom
    return (f'M0,{t} A{t},{t} 0 0 1 {t},0 H{num(w - t)} A{t},{t} 0 0 1 {num(w)},{t} V{num(h - b)} '
            f'A{b},{b} 0 0 1 {num(w - b)},{num(h)} H{b} A{b},{b} 0 0 1 0,{num(h - b)} Z')


def picture(data, px=128):
    """Square-cropped WebP data URI on the site's icon backdrop (#0d1317)."""
    im = Image.open(io.BytesIO(data)).convert("RGBA")
    s = min(im.size)
    l, t = (im.width - s) // 2, (im.height - s) // 2
    im = im.crop((l, t, l + s, t + s)).resize((px, px), Image.LANCZOS)
    bg = Image.new("RGBA", im.size, (13, 19, 23, 255))
    bg.alpha_composite(im)
    buf = io.BytesIO()
    bg.convert("RGB").save(buf, "WEBP", quality=85, method=6)
    return "data:image/webp;base64," + base64.b64encode(buf.getvalue()).decode()


def app_icon(name, uri, x, y, s, uid):
    """The icon, or the site's letter tile in the app's colour when there is none."""
    clip = f'<clipPath id="c{uid}"><rect x="{num(x)}" y="{num(y)}" width="{s}" height="{s}" rx="12"/></clipPath>'
    if uri:
        return (f'{clip}<image href="{uri}" x="{num(x)}" y="{num(y)}" width="{s}" height="{s}" '
                f'clip-path="url(#c{uid})"/>')
    h = hue(name)
    return (f'<linearGradient id="p{uid}" x2="1" y2="1"><stop stop-color="hsl({188 + h * .5:.1f},85%,44%)"/>'
            f'<stop offset="1" stop-color="hsl({212 + h * .4:.1f},80%,34%)"/></linearGradient>'
            + rect(x, y, s, s, 12, f"url(#p{uid})")
            + text("semi", name[:1].upper(), s * .42, x + s / 2, y + s / 2 + s * .42 * .36, anchor="middle"))


def svg(w, h, body, style="", defs="", clip=None):
    """A slice of the page: black background, optional rounded outline, own <style>."""
    inner = rect(0, 0, w, h, fill="#000") + body
    if clip:
        defs += f'<clipPath id="pg"><path d="{clip}"/></clipPath>'
        inner = f'<g clip-path="url(#pg)">{inner}</g>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{num(w)}" height="{num(h)}" viewBox="0 0 {num(w)} {num(h)}">'
            f'<style>{style}{STYLE}</style><defs>{defs}</defs>{inner}</svg>\n')


def cell(c, n):
    """Left edge of card c inside its own W/n-wide slice, and the card width."""
    cw = (W - 2 * P - (n - 1) * G) / n
    x = P + c * (cw + G) - c * W / n
    assert -.01 <= x and x + cw <= W / n + .01, "card crosses its slice; raise G"
    return x, cw


# -- the pieces -----------------------------------------------------------------

def hero(apps, cfg):
    d = face("display")
    # pill: "52 community apps, ready to install"
    n, label, py = str(len(apps)), "community apps, ready to install", 44
    bw = face("semi").width(n, 13) + 20
    pw = 6 + bw + 10 + face("regular").width(label, 14) + 14
    px = (W - pw) / 2
    pill = (rect(px, py, pw, 34, 17, CARD, LINE) + rect(px + 6, py + 6, bw, 22, 11, AC)
            + text("semi", n, 13, px + 6 + bw / 2, py + 21.7, INK, "middle")
            + text("regular", label, 14, px + 6 + bw + 10, py + 22, MUT))

    # the ice title, measured the way style.css lays it out (line-height .95, letter-spacing -.045em)
    word, track = cfg["site_name"], -.045
    size = 640 / d.width(word, 1, track)
    ww = d.width(word, size, track)
    wx = (W - ww) / 2
    top = py + 34 + 60
    base = top + ((.95 - d.asc - d.desc) / 2 + d.asc) * size
    bot = top + .95 * size
    k = size / 148  # the site's shadows are sized for a 148px title
    wd = d.d(word, size, wx, base, track)

    ix, iw, iy, ih = wx + .025 * ww, .95 * ww, bot + .4 * size - .56 * size, .56 * size
    pts = ("0,0 4,5 20,36 36,5 44,5 60,26 76,5 84,5 100,48 116,5 124,5 140,72 156,5 164,5 180,18 196,5 204,5 "
           "220,18 236,5 244,5 260,60 276,5 284,5 300,18 316,5 324,5 340,36 356,5 364,5 380,60 396,5 404,5 420,18 "
           "436,5 444,5 460,60 476,5 484,5 500,26 516,5 524,5 540,18 556,5 564,5 580,18 596,5 600,0")
    icicles = " ".join(f"{num(ix + float(a) / 600 * iw)},{num(iy + float(b) / 76 * ih)}"
                       for a, b in (p.split(",") for p in pts.split()))

    ss = .17 * size
    star = [(.5, 0), (.59, .41), (1, .5), (.59, .59), (.5, 1), (.41, .59), (0, .5), (.41, .41)]
    sparks = "".join(
        f'<polygon class="sp" style="animation-delay:{dl}s" fill="#fff" points="'
        + " ".join(f"{num(wx + l / 100 * ww + a * ss)},{num(top + t / 100 * .95 * size + b * ss)}" for a, b in star) + '"/>'
        for l, t, dl in ((-3, -12, 0), (23, -20, .9), (47, -24, 1.7), (72, -16, .4), (99, -10, 2.2), (60, 118, 1.3)))

    gw, gy, gh = .624 * ww, top - 20, .95 * size + 40  # the glint: a skewed light band that sweeps across
    lead_y = bot + .4 * size + 58
    h = lead_y + 72

    defs = (
        f'<radialGradient id="glow"><stop stop-color="{AC}" stop-opacity=".28"/><stop offset="1" stop-color="{AC}" stop-opacity="0"/></radialGradient>'
        f'<radialGradient id="cur"><stop stop-color="{AC}" stop-opacity=".2"/><stop offset=".65" stop-color="{AC}" stop-opacity="0"/></radialGradient>'
        '<radialGradient id="spot"><stop stop-color="#fff"/><stop offset="1" stop-color="#000"/></radialGradient>'
        '<pattern id="dots" width="30" height="30" patternUnits="userSpaceOnUse"><circle cx="15" cy="15" r="1" fill="#fff" fill-opacity=".4"/></pattern>'
        '<mask id="dm"><circle class="spot" cx="700" cy="110" r="300" fill="url(#spot)"/></mask>'
        f'<linearGradient id="fade" x2="0" y2="1"><stop offset="{(h - 90) / h:.3f}" stop-color="#fff"/><stop offset="1" stop-color="#000"/></linearGradient>'
        f'<mask id="bf"><rect width="{W}" height="{num(h)}" fill="url(#fade)"/></mask>'
        '<filter id="blur" filterUnits="userSpaceOnUse" x="-500" y="-500" width="2000" height="1500"><feGaussianBlur stdDeviation="90"/></filter>'
        f'<linearGradient id="ice" gradientUnits="userSpaceOnUse" x1="0" y1="{num(top)}" x2="0" y2="{num(bot)}">'
        '<stop stop-color="#fff"/><stop offset=".26" stop-color="#e4f8ff"/><stop offset=".58" stop-color="#8fdcf7"/><stop offset="1" stop-color="#3d9be0"/></linearGradient>'
        '<linearGradient id="ig" x2="0" y2="1"><stop stop-color="#fff" stop-opacity=".95"/><stop offset=".55" stop-color="#9fe3fa" stop-opacity=".75"/>'
        f'<stop offset="1" stop-color="{AC}" stop-opacity=".1"/></linearGradient>'
        '<linearGradient id="gl"><stop stop-color="#fff" stop-opacity="0"/><stop offset=".5" stop-color="#fff" stop-opacity=".95"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>'
        f'<clipPath id="wc"><path d="{wd}"/></clipPath>'
        '<filter id="frost" x="-20%" y="-60%" width="140%" height="220%" color-interpolation-filters="sRGB">'
        '<feGaussianBlur in="SourceAlpha" stdDeviation="1" result="a"/><feFlood flood-color="#fff" flood-opacity=".85"/><feComposite in2="a" operator="in" result="s1"/>'
        f'<feGaussianBlur in="SourceAlpha" stdDeviation="{30 * k:.1f}" result="b"/><feFlood flood-color="{AC}" flood-opacity=".5"/><feComposite in2="b" operator="in" result="s2"/>'
        f'<feOffset in="SourceAlpha" dy="{5 * k:.1f}" result="c"/><feFlood flood-color="#125696" flood-opacity=".4"/><feComposite in2="c" operator="in" result="s3"/>'
        '<feMerge><feMergeNode in="s3"/><feMergeNode in="s2"/><feMergeNode in="s1"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
        f'<filter id="drip" x="-10%" y="-60%" width="120%" height="220%"><feGaussianBlur in="SourceAlpha" stdDeviation="{10 * k:.1f}" result="b"/>'
        f'<feFlood flood-color="{AC}" flood-opacity=".45"/><feComposite in2="b" operator="in"/><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
    )
    style = (
        ".blob{transform-box:fill-box;transform-origin:center;animation:drift 22s ease-in-out infinite alternate}"
        ".blob+.blob{animation-duration:28s;animation-direction:alternate-reverse}"
        "@keyframes drift{to{transform:translate(180px,60px) scale(1.2)}}"
        ".spot{animation:spot 18s ease-in-out infinite alternate}@keyframes spot{to{transform:translate(-420px,40px)}}"
        f".gl{{animation:gl 6s ease-in-out infinite}}@keyframes gl{{0%,35%{{transform:translateX(0)}}70%,100%{{transform:translateX({2.72 * ww:.0f}px)}}}}"
        ".sp{transform-box:fill-box;transform-origin:center;opacity:0;animation:tw 3.2s ease-in-out infinite}"
        "@keyframes tw{0%,100%{opacity:0;transform:scale(.3) rotate(0)}50%{opacity:1;transform:scale(1) rotate(45deg)}}"
    )
    body = (
        '<g mask="url(#bf)">'
        f'<ellipse cx="500" cy="170" rx="500" ry="310" fill="url(#glow)"/>'
        f'<circle class="blob" cx="140" cy="140" r="260" fill="{AC}" fill-opacity=".1" filter="url(#blur)"/>'
        f'<circle class="blob" cx="900" cy="40" r="220" fill="{AC2}" fill-opacity=".08" filter="url(#blur)"/>'
        f'<circle class="spot" cx="700" cy="110" r="520" fill="url(#cur)"/>'
        f'<rect width="{W}" height="{num(h)}" fill="url(#dots)" mask="url(#dm)"/></g>'
        + pill
        + f'<g filter="url(#frost)"><path fill="url(#ice)" d="{wd}"/></g>'
        + f'<g clip-path="url(#wc)"><g class="gl"><g transform="translate({.268 * (gy + gh / 2):.1f},0) skewX(-15)">'
        + rect(wx - .78 * ww - gw / 2, gy, gw, gh, fill="url(#gl)") + '</g></g></g>'
        + f'<polygon points="{icicles}" fill="url(#ig)" filter="url(#drip)"/>'
        + sparks
        + text("regular", cfg["tagline"], fit("regular", cfg["tagline"], 20, W - 2 * P), W / 2, lead_y, MUT, "middle")
    )
    return svg(W, h, body, style, defs, clip_round(W, h, R, 0))


def marquee(apps, icons):
    """Two rows of tiles that loop forever, split like build.marquee()."""
    tile, pitch, top, gap = 96, 110, 20, 12
    half = math.ceil(len(apps) / 2)
    defs, body, style = "", "", ""
    for r, row in enumerate((apps[:half], apps[half:])):
        if not row:
            continue
        reps = max(1, math.ceil(W * 1.1 / (len(row) * pitch)))  # enough tiles to cover the width twice over
        tiles = "".join(
            rect(i * pitch + .5, .5, tile - 1, tile - 1, 24, CARD, LINE) + f'<use href="#i{a["slug"]}" x="{i * pitch + 10}" y="10"/>'
            for i, a in enumerate(row * reps))
        span = len(row) * reps * pitch
        defs += f'<g id="r{r}">{tiles}</g>'
        body += (f'<g transform="translate(0,{top + r * (tile + gap)})"><g class="m{r}">'
                 f'<use href="#r{r}"/><use href="#r{r}" x="{span}"/></g></g>')
        speed = 38 if r == 0 else 31  # px per second, about the site's 70s and 85s loops
        style += (f".m{r}{{animation:m{r} {span / speed:.0f}s linear infinite{' reverse' if r else ''}}}"
                  f"@keyframes m{r}{{to{{transform:translateX(-{span}px)}}}}")
    for a in apps:
        defs += f'<g id="i{a["slug"]}">{app_icon(a["name"], icons[a["slug"]], 0, 0, 76, "m" + a["slug"])}</g>'
    h = top + 2 * tile + gap + top
    defs += ('<linearGradient id="ef"><stop stop-color="#000"/><stop offset=".12" stop-color="#fff"/>'
             '<stop offset=".88" stop-color="#fff"/><stop offset="1" stop-color="#000"/></linearGradient>'
             f'<mask id="em"><rect width="{W}" height="{h}" fill="url(#ef)"/></mask>')
    return svg(W, h, f'<g mask="url(#em)">{body}</g>', style, defs)


def title(h2, sub, search=False):
    h = 150
    body = text("medium", h2, 40, P, 78, track=-.03) + text("regular", sub, 17, P, 112, MUT)
    if search:  # looks like the site's search box; the whole picture links to the app list
        sw, sx, sy = 320, W - P - 320, 64
        body += (rect(sx, sy, sw, 48, 24, CARD, LINE) + icon("search", sx + 18, sy + 15, 18, MUT)
                 + text("semi", "Search apps on the website", 15, sx + 48, sy + 29.5, DIM))
    return svg(W, h, body)


def store(j, os_id, name, logo, url):
    sw, h = W / 3, 263
    x, cw = cell(j, 3)
    y, pad = 0, 24
    note = wrap("regular", OS_NOTES[os_id], 14, cw - 2 * pad - 62)
    tx = x + pad + 62
    head = (app_icon(name, logo, x + pad, y + pad, 48, os_id)
            + text("semi", name, 21, tx, y + pad + 21)
            + "".join(text("regular", s, 14, tx, y + pad + 42 + i * 19, MUT) for i, s in enumerate(note)))
    uy = y + pad + 63 + 20
    box = (rect(x + pad, uy, cw - 2 * pad, 60, 16, "rgba(76,201,240,.07)", "rgba(76,201,240,.35)")
           + text("semi", "STORE URL", 11, x + pad + 16, uy + 23, AC, track=.07)
           + text("semi", url, fit("semi", url, 13.5, cw - 2 * pad - 32), x + pad + 16, uy + 44, AC2))
    by = uy + 60 + 16
    cta = f"Add to {name}"
    cw_t = face("semi").width(cta, 15) + 10 + 18
    cx = x + cw / 2 - cw_t / 2
    btn = (rect(x + pad, by, cw - 2 * pad, 46, 23, AC)
           + text("semi", cta, 15, cx, by + 28.5, INK) + icon("arrow-right", cx + cw_t - 18, by + 14, 18, INK))
    defs = ('<radialGradient id="t" cx="0" cy="0" r="1" gradientTransform="scale(1.2,.7)">'
            f'<stop stop-color="{AC}" stop-opacity=".12"/><stop offset=".6" stop-color="{AC}" stop-opacity="0"/></radialGradient>')
    card = rect(x + .5, y + .5, cw - 1, by + 46 + pad - 1, R, CARD, LINE) + rect(x + .5, y + .5, cw - 1, by + 46 + pad - 1, R, "url(#t)")
    return svg(sw, h, card + head + box + btn, defs=defs)


def app_card(i, a, uri):
    x, cw = cell(i % COLS, COLS)
    s, pad = 56, 18
    tx = x + pad + s + 14
    max_w = cw - (tx - x) - 14
    lines = [("semi", t, 17, "#fff") for t in wrap("semi", a["name"], 17, max_w)]
    if len(lines) == 1 and a.get("category"):
        cat = str(a["category"])
        cat = wrap("regular", cat[:1].upper() + cat[1:], 13.5, max_w, 1)[0]
        lines.append(("regular", cat, 13.5, MUT))
    total = sum(sz * 1.3 for _, _, sz, _ in lines)
    y = (CARD_H - total) / 2
    body = rect(x + .5, .5, cw - 1, CARD_H - 1, 22, CARD, LINE) + app_icon(a["name"], uri, x + pad, (CARD_H - s) / 2, s, "a")
    for font, t, sz, color in lines:
        body += text(font, t, sz, tx, y + sz * 1.02, color)
        y += sz * 1.3
    return svg(W / COLS, CARD_H + G, body)


def help_panel(cfg):
    bx, by, bw, bh = P, 40, W - 2 * P, 170
    btn = "Request an App"
    btw = face("semi").width(btn, 15) + 28 + 10 + 18 + 28
    btx, bty = bx + bw - 40 - btw, by + (bh - 50) / 2
    defs = ('<radialGradient id="t" cx="0" cy="0" r="1" gradientTransform="translate(0,1) scale(.6,1.4)">'
            f'<stop stop-color="{AC}" stop-opacity=".22"/><stop offset="1" stop-color="{AC}" stop-opacity="0"/></radialGradient>')
    heart = "M12 21s-7-4.35-9.5-8.5C.5 9 2.5 5 6.5 5c2 0 3.5 1.2 5.5 3.2C14 6.2 15.5 5 17.5 5c4 0 6 4 4 7.5C19 16.65 12 21 12 21z"
    a, b = "Made with ", f' by {cfg["author"]} in New Zealand'
    fy = by + bh + 70
    wa, wb = face("regular").width(a, 15), face("regular").width(b, 15)
    fx = W / 2 - (wa + 16 + wb) / 2
    h = fy + 26 + 48
    body = (
        rect(bx + .5, by + .5, bw - 1, bh - 1, R, CARD, "rgba(76,201,240,.35)") + rect(bx + .5, by + .5, bw - 1, bh - 1, R, "url(#t)")
        + text("medium", "Missing an app?", 40, bx + 40, by + 80, track=-.03)
        + text("regular", "Ask for it, report a bug, or browse the code.", 17, bx + 40, by + 114, MUT)
        + rect(btx, bty, btw, 50, 25, AC, extra=' style="filter:drop-shadow(0 0 15px rgba(76,201,240,.35))"')
        + icon("plus-circle", btx + 28, bty + 16, 18, INK) + text("semi", btn, 15, btx + 28 + 18 + 10, bty + 30.5, INK)
        + rect(0, fy - 40, W, 1, fill=LINE)
        + text("regular", a, 15, fx, fy, "rgba(255,255,255,.85)")
        + f'<path fill="{AC2}" transform="translate({fx + wa:.1f},{fy - 12:.1f}) scale(.62)" d="{heart}"/>'
        + text("regular", b, 15, fx + wa + 16, fy, "rgba(255,255,255,.85)")
        + text("regular", "A community project, not affiliated with Zima OS, Casa OS and Homeio.", 14, W / 2, fy + 26, MUT, "middle")
    )
    return svg(W, h, body, defs=defs, clip=clip_round(W, h, 0, R))


# -- README ---------------------------------------------------------------------

def readme_block(apps, cfg):
    base = cfg["base_url"]

    def img(src, width, alt):
        return f'<img src="readme/{src}" width="{width}" align="top" alt="{e(alt)}">'

    def link(href, inner):
        return f'<a href="{e(href)}">{inner}</a>'

    blanks = -len(apps) % COLS
    parts = [
        img("hero.svg", "100%", f'{cfg["site_name"]}: {cfg["tagline"]}'),
        img("marquee.svg", "100%", f'Icons of the {len(apps)} apps in {cfg["site_name"]}'),
        link(base + "#stores", img("stores.svg", "100%", f'Add {cfg["site_name"]} to your OS')),
        *[link(f"{base}#{i}", img(f"store-{i}.svg", "33.33%", f'Add {cfg["site_name"]} to {n}')) for i, n, _ in OSES],
        link(base + "#apps", img("apps.svg", "100%", f"All {len(apps)} apps")),
        *[link(f'{base}app/{a["slug"]}/', img(f'apps/{a["slug"]}.svg', "25%", a["name"])) for a in apps],
        *[img("apps/_blank.svg", "25%", "") for _ in range(blanks)],
        link(cfg["repo"] + "/issues/new", img("help.svg", "100%", "Missing an app? Request it on GitHub")),
    ]
    # one picture per line, each line break inside a tag: no space may get between the pictures
    return '<p align="center">' + "".join(p[:-1] + "\n" + p[-1] for p in parts) + "</p>"


def main():
    cfg = dict(DEFAULTS)
    if (SITE / "site.json").exists():
        cfg.update(json.loads((SITE / "site.json").read_text(encoding="utf-8")))
    cfg["base_url"] = cfg["base_url"].rstrip("/") + "/"
    urls = {"zimaos": cfg["base_url"] + "store.json", "casaos": cfg["base_url"] + "store.zip",
            "homeio": cfg["base_url"] + "store.zip"}

    apps = []
    for folder in sorted(p for p in (ROOT / "Apps").iterdir() if p.is_dir() and not p.name.startswith(".")):
        try:
            apps.append(load_app(folder))
        except Exception as ex:
            sys.exit(f"::error::Apps/{folder.name}: {ex}")
    apps.sort(key=lambda a: a["name"].lower())
    icons = {a["slug"]: picture(a["icon"].read_bytes()) if a["icon"] else "" for a in apps}

    (OUT / "apps").mkdir(parents=True, exist_ok=True)
    files = {
        "hero.svg": hero(apps, cfg),
        "marquee.svg": marquee(apps, icons),
        "stores.svg": title(f'Add {cfg["site_name"]} to your OS', "Pick your system, copy the link and add it as a community store."),
        "apps.svg": title("All apps", f"{len(apps)} apps and counting. Click one to see how to set it up.", search=True),
        "help.svg": help_panel(cfg),
    }
    for j, (i, n, logo) in enumerate(OSES):
        try:
            uri = picture(fetch(logo), 96)
        except Exception as ex:  # a letter tile is fine for a while
            print(f"::warning::{n} logo: {ex}")
            uri = ""
        files[f"store-{i}.svg"] = store(j, i, n, uri, urls[i])
    for k, a in enumerate(apps):
        files[f'apps/{a["slug"]}.svg'] = app_card(k, a, icons[a["slug"]])
    if len(apps) % COLS:
        files["apps/_blank.svg"] = svg(W / COLS, CARD_H + G, "")

    for f in (OUT / "apps").glob("*.svg"):
        if f"apps/{f.name}" not in files:
            f.unlink()
    for name, content in files.items():
        (OUT / name).write_text(content, encoding="utf-8", newline="\n")

    md = README.read_text(encoding="utf-8")
    if START not in md or END not in md:
        sys.exit(f"::error::README.md needs {START} and {END}")
    head, rest = md.split(START, 1)
    md = head + START + "\n" + readme_block(apps, cfg) + "\n" + END + rest.split(END, 1)[1]
    README.write_text(md, encoding="utf-8", newline="\n")
    size = sum(len(c) for c in files.values())
    print(f"Wrote {len(files)} SVGs ({size / 1024:.0f} KB) for {len(apps)} apps")


if __name__ == "__main__":
    main()
