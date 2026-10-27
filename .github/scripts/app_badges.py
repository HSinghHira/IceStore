#!/usr/bin/env python3
"""Draw two "on IceStore" badges per app: <out>/app-badge/<slug>.svg (dark)
and <out>/app-badge/light/<slug>.svg (light, for light READMEs).

    pip install -r site/requirements.txt pillow fonttools
    python .github/scripts/app_badges.py              # into ./_site, next to the built site
    python .github/scripts/app_badges.py --out dist   # into the Pages bundle (release-store.yml)

Each badge looks like an app card on the site: the icon, the app name and "Get it on IceStore".
It is drawn the same way as the README pictures (readme_svgs.py): text as outlines and the icon
embedded, so it shows anywhere an image can, including a GitHub README:

    [![AFFiNE on IceStore](https://icestore.hsinghhira.me/app-badge/affine.svg)](https://icestore.hsinghhira.me/app/affine/)

The site's /app-badge/ page shows every badge with its Markdown and HTML to copy.
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from readme_svgs import (AC, CARD, LINE, MUT, ROOT, SITE, app_icon, clip_round, e, face,  # noqa: E402
                         picture, rect, svg, text)
from build import DEFAULTS, load_app  # noqa: E402  (readme_svgs put site/ on the path)

H = 80            # badge height
S = 48            # icon size
PAD = 16          # space around the icon
GAP = 14          # icon to text
R = 20            # corner radius
NAME = 18         # app name size
SMALL = 12.5      # "Get it on IceStore" size
MAX_NAME = 260    # longer names shrink to fit

# colours per theme: dark matches the site; light is the same card on white
THEMES = {
    "dark": {"bg": "#000", "card": CARD, "line": LINE, "name": "#fff", "mut": MUT, "glow": ".16",
             "brand": ("#fff", "#8fdcf7")},
    "light": {"bg": "#fff", "card": "rgba(76,201,240,.04)", "line": "rgba(3,18,25,.14)", "name": "#0b1418",
              "mut": "rgba(3,18,25,.6)", "glow": ".14", "brand": ("#031219", "#1a86ad")},
}


def badge(a, uri, site_name, theme="dark"):
    t = THEMES[theme]
    name_size = min(NAME, NAME * MAX_NAME / face("semi").width(a["name"], NAME))
    get = "Get it on "
    get_w = face("regular").width(get, SMALL)
    brand_w = face("display").width(site_name, SMALL, -.04)
    tx = PAD + S + GAP
    w = round(tx + max(face("semi").width(a["name"], name_size), get_w + brand_w) + PAD + 6)
    # two lines, centred as one block like the site's cards
    top = (H - (name_size * 1.25 + SMALL * 1.3)) / 2
    y1, y2 = top + name_size * 1.02, top + name_size * 1.25 + SMALL * 1.12
    b1, b2 = t["brand"]
    defs = (f'<linearGradient id="brand" x2="0" y2="1"><stop stop-color="{b1}"/><stop offset="1" stop-color="{b2}"/></linearGradient>'
            '<radialGradient id="glow" cx="0" cy="0" r="1" gradientTransform="scale(.7,1.6)">'
            f'<stop stop-color="{AC}" stop-opacity="{t["glow"]}"/><stop offset="1" stop-color="{AC}" stop-opacity="0"/></radialGradient>')
    body = (
        rect(.5, .5, w - 1, H - 1, R, "url(#glow)")
        + rect(.5, .5, w - 1, H - 1, R, t["card"], t["line"])
        + app_icon(a["name"], uri, PAD, (H - S) / 2, S, "i")
        + text("semi", a["name"], name_size, tx, y1, t["name"])
        + text("regular", get, SMALL, tx, y2, t["mut"])
        + text("display", site_name, SMALL, tx + get_w, y2, "url(#brand)", track=-.04)
    )
    out = svg(w, H, body, defs=defs, clip=clip_round(w, H, R, R), bg=t["bg"])
    label = e(f'{a["name"]} on {site_name}')
    return out.replace("<svg ", f'<svg role="img" aria-label="{label}" ', 1).replace("<style>", f"<title>{label}</title><style>", 1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "_site"))
    out = Path(ap.parse_args().out) / "app-badge"

    cfg = dict(DEFAULTS)
    if (SITE / "site.json").exists():
        cfg.update(json.loads((SITE / "site.json").read_text(encoding="utf-8")))

    (out / "light").mkdir(parents=True, exist_ok=True)
    n = size = 0
    for folder in sorted(p for p in (ROOT / "Apps").iterdir() if p.is_dir() and not p.name.startswith(".")):
        try:
            a = load_app(folder)
        except Exception as ex:
            sys.exit(f"::error::Apps/{folder.name}: {ex}")
        uri = picture(a["icon"].read_bytes(), 96) if a["icon"] else ""
        for theme, dest in (("dark", out), ("light", out / "light")):
            content = badge(a, uri, cfg["site_name"], theme)
            (dest / f'{a["slug"]}.svg').write_text(content, encoding="utf-8", newline="\n")
            n, size = n + 1, size + len(content)
    print(f"Wrote {n} badges ({size / 1024:.0f} KB) into {out}")


if __name__ == "__main__":
    main()
