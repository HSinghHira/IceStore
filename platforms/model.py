"""Read one IceStore app (the master source) into a plain object every adapter can use.

Nothing here knows about any platform. Adapters get an App and turn it into their
own files; they never read Apps/ themselves.
"""
import copy
import re
from dataclasses import dataclass, field
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
APPS = ROOT / "Apps"
OVERRIDES = ROOT / "platforms"
IMAGE_EXT = {".png", ".webp", ".jpg", ".jpeg", ".gif", ".svg"}


def text(v):
    """x-casaos strings are plain text or {en_US: text}."""
    if isinstance(v, dict):
        v = v.get("en_US") or next(iter(v.values()), "")
    return "" if v is None else str(v)


def front_matter(raw):
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n?", raw, re.S)
    if not m:
        return {}, raw
    return (yaml.safe_load(m.group(1)) or {}), raw[m.end():]


@dataclass
class App:
    slug: str
    dir: Path
    compose: dict
    meta: dict                     # top-level x-casaos
    readme: dict                   # README.md front matter
    readme_body: str
    overrides: dict = field(default_factory=dict)   # {platform: platforms/<platform>/overrides/<app>.yml}

    # ---- metadata, in one place so every adapter words things the same way
    @property
    def main(self):
        return self.meta.get("main") or next(iter(self.compose["services"]))

    @property
    def title(self):
        return self.readme.get("name") or text(self.meta.get("title")) or self.slug

    @property
    def tagline(self):
        return self.readme.get("tagline") or text(self.meta.get("tagline"))

    @property
    def description(self):
        return text(self.meta.get("description")).strip()

    @property
    def release_notes(self):
        return text(self.meta.get("release_notes")).strip()

    @property
    def version(self):
        return str(self.meta.get("version") or "")

    @property
    def category(self):
        return self.readme.get("category") or self.meta.get("category") or "Others"

    @property
    def architectures(self):
        return list(self.meta.get("architectures") or [])

    @property
    def port(self):
        p = self.meta.get("port_map")
        return str(p) if p not in (None, "") else ""

    @property
    def path(self):
        return self.meta.get("index") or "/"

    @property
    def scheme(self):
        return self.meta.get("scheme") or "http"

    @property
    def developer(self):
        return text(self.meta.get("developer"))

    @property
    def author(self):
        return text(self.meta.get("author"))

    @property
    def repo(self):
        return self.readme.get("source") or self.meta.get("repo") or ""

    @property
    def support(self):
        return self.meta.get("support") or ""

    @property
    def website(self):
        return self.readme.get("site") or self.meta.get("docs") or self.repo

    @property
    def icon(self):
        return self.meta.get("icon") or ""

    @property
    def screenshots(self):
        return list(self.meta.get("screenshot_link") or [])

    def site_page(self, site):
        return f"{site.rstrip('/')}/app/{self.slug}/"

    def override(self, platform):
        return copy.deepcopy(self.overrides.get(platform) or {})

    # ---- compose helpers
    def services(self):
        return self.compose.get("services") or {}

    def service_meta(self, name):
        """The service's own x-casaos block (env/port/volume descriptions)."""
        return self.services().get(name, {}).get("x-casaos") or {}

    def described(self, name, kind, key):
        """Description of an env var / port / volume from the service's x-casaos block."""
        for item in self.service_meta(name).get(kind) or []:
            if str(item.get("container")) == str(key):
                return text(item.get("description")).strip()
        return ""


def load_app(folder):
    folder = Path(folder)
    compose = yaml.safe_load((folder / "docker-compose.yml").read_text(encoding="utf-8")) or {}
    rd = folder / "README.md"
    fm, body = front_matter(rd.read_text(encoding="utf-8-sig")) if rd.exists() else ({}, "")
    ov = {}
    for f in sorted(OVERRIDES.glob(f"*/overrides/{folder.name}.yml")):
        ov[f.parent.parent.name] = yaml.safe_load(f.read_text(encoding="utf-8")) or {}
    return App(folder.name, folder, compose, compose.get("x-casaos") or {}, fm, body, ov or {})


def load_apps(names=None):
    folders = sorted(p for p in APPS.iterdir() if (p / "docker-compose.yml").exists())
    if names:
        wanted = set(names)
        missing = wanted - {p.name for p in folders}
        if missing:
            raise SystemExit(f"no such app: {', '.join(sorted(missing))}")
        folders = [p for p in folders if p.name in wanted]
    known = {p.name for p in APPS.iterdir() if p.is_dir()}
    for f in OVERRIDES.glob("*/overrides/*.yml"):
        if f.stem not in known:   # a typo or a renamed app would make the override do nothing
            raise SystemExit(f"{f.relative_to(ROOT)}: there is no Apps/{f.stem}/")
    return [load_app(p) for p in folders]


# ---------------------------------------------------------------- shared transforms

def walk(obj, fn):
    """Copy of obj with fn applied to every string (keys are left alone)."""
    if isinstance(obj, dict):
        return {k: walk(v, fn) for k, v in obj.items()}
    if isinstance(obj, list):
        return [walk(v, fn) for v in obj]
    if isinstance(obj, str):
        return fn(obj)
    return obj


def sub_var(s, name, value):
    """Replace $name and ${name} in a compose string, but not the escaped $$name."""
    pat = re.compile(r"(?<!\$)\$(?:\{" + re.escape(name) + r"\}|" + re.escape(name) + r"(?![A-Za-z0-9_]))")
    return pat.sub(lambda _m: value, s)


def map_paths(s, path_map):
    """Rewrite host paths: /DATA/AppData/$AppID/x -> <platform folder>/x. Longest key first."""
    s = re.sub(r"(?<!\$)\$\{AppID\}", "$AppID", s)
    for src in sorted(path_map, key=len, reverse=True):
        dst = path_map[src]
        s = re.sub(re.escape(src) + r"(?=/|$|[\s:\"'])", lambda _m: dst, s)
    return s


def fmt(template, app, **extra):
    """Fill {slug} (and any extra {name}) in a config value. Other braces, like ${TZ:-UTC}, stay."""
    s = str(template).replace("{slug}", app.slug)
    for k, v in extra.items():
        s = s.replace("{" + k + "}", str(v))
    return s


def deep_merge(base, extra):
    """Merge override dicts into generated ones; a null value deletes the key."""
    for k, v in (extra or {}).items():
        if v is None:
            base.pop(k, None)
        elif isinstance(v, dict) and isinstance(base.get(k), dict):
            deep_merge(base[k], v)
        else:
            base[k] = copy.deepcopy(v)
    return base


def parse_port(p):
    """Compose port (long or short form) -> dict(target, published, protocol)."""
    if isinstance(p, dict):
        return {"target": str(p.get("target", "")), "published": str(p.get("published", "") or ""),
                "protocol": p.get("protocol") or "tcp"}
    s = str(p)
    proto = "tcp"
    if "/" in s:
        s, proto = s.rsplit("/", 1)
    parts = s.split(":")
    return {"target": parts[-1], "published": parts[-2] if len(parts) > 1 else "", "protocol": proto}


def parse_volume(v):
    """Compose volume (long or short form) -> dict(type, source, target, read_only)."""
    if isinstance(v, dict):
        return {"type": v.get("type") or "volume", "source": str(v.get("source") or ""),
                "target": str(v.get("target") or ""), "read_only": bool(v.get("read_only"))}
    parts = str(v).split(":")
    ro = len(parts) > 2 and "ro" in parts[2].split(",")
    src = parts[0] if len(parts) > 1 else ""
    return {"type": "bind" if src.startswith(("/", ".", "$", "~")) else "volume",
            "source": src, "target": parts[1] if len(parts) > 1 else parts[0], "read_only": ro}


def env_list(env):
    """Compose environment (list or map) -> list of (key, value)."""
    if isinstance(env, dict):
        return [(str(k), "" if v is None else str(v)) for k, v in env.items()]
    out = []
    for item in env or []:
        k, _, v = str(item).partition("=")
        out.append((k, v))
    return out


# ---------------------------------------------------------------- YAML output

class _Dumper(yaml.SafeDumper):
    pass


def _str(dumper, s):
    style = "|" if "\n" in s else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", s, style=style)


_Dumper.add_representer(str, _str)


def dump_yaml(data):
    return yaml.dump(data, Dumper=_Dumper, sort_keys=False, allow_unicode=True, width=100,
                     default_flow_style=False)
