"""What every adapter shares: the result type, skipping, and text clean-up."""
import re
from dataclasses import dataclass, field
from pathlib import Path

from model import fmt, map_paths, sub_var, walk


class Skip(Exception):
    """Raise from build_app when an app cannot run on this platform. The message is the reason."""


@dataclass
class AppResult:
    slug: str
    status: str = "ok"            # ok | skipped | error
    reason: str = ""
    warnings: list = field(default_factory=list)
    errors: list = field(default_factory=list)
    port: object = None           # the port the app opens on, for the report
    format: str = ""              # adapter-specific layout note, for the report
    path: Path = None             # the main file or folder written for the app


class Adapter:
    name = ""
    native = False                # True: the platform reads Apps/ itself, nothing to write

    def __init__(self, cfg, store):
        self.cfg = cfg or {}
        self.store = store or {}

    # ---- the three steps the generator calls
    def build_app(self, app, out: Path, result: AppResult):
        """Write one app into out/. Raise Skip to leave it out."""
        raise NotImplementedError

    def build_store(self, apps, results, out: Path):
        """Write the store-level files (index, README, maintainer file)."""

    def check(self, out: Path, results):
        """Look over the written files; add to result.errors / result.warnings."""

    # ---- where the output lives in the IceStore repo (--write-repo)
    def owned(self, root: Path):
        """Paths in the repo root this adapter generated last time (deleted before writing)."""
        return []

    def outputs(self, out: Path):
        """Paths in out/ to copy to the repo root, at the same relative place."""
        return []

    # ---- helpers adapters use
    def enabled(self, app, result):
        ov = app.override(self.name)
        if ov.get("enabled") is False:
            raise Skip(ov.get("reason") or f"turned off in platforms/{self.name}/overrides/{app.slug}.yml")
        return ov

    def translate(self, obj, app, keep_vars=(), path_map=None, placeholders=None):
        """Master compose strings -> this platform: host paths, CasaOS variables, IP placeholders."""
        path_map = {k: fmt(v, app) for k, v in (path_map or self.cfg.get("path_map") or {}).items()}
        vars_ = {k: fmt(v, app) for k, v in (self.cfg.get("vars") or {}).items() if k not in keep_vars}
        holders = placeholders or self.cfg.get("placeholders") or {}

        literal = re.compile(r"/DATA/AppData/" + re.escape(app.slug) + r"(?=/|$|[\s:\"'])")

        def fn(s):
            s = literal.sub("/DATA/AppData/$AppID", s)   # paths in start-up messages name the app outright
            s = map_paths(s, path_map)
            for k, v in vars_.items():
                s = sub_var(s, k, v)
            for k, v in holders.items():
                s = s.replace(k, v)
            return s
        return walk(obj, fn)

    def words(self, s, app, **extra):
        """App Store copy (description, notes) with platform wording."""
        for a, b in self.cfg.get("text_replace") or []:
            s = s.replace(fmt(a, app, **extra), fmt(b, app, **extra))
        return s

    def category(self, app):
        return (self.cfg.get("categories") or {}).get(app.category) or app.category
