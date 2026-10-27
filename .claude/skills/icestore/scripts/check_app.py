#!/usr/bin/env python3
"""Check one IceStore app before pushing.

    python3 check_app.py <repo root> <app folder name>
    python3 check_app.py ~/IceStore appflowy

Checks Apps/<app>/ (compose, README, images) and, for apps whose image is
ghcr.io/hsinghhira/<app>, also docker/<app>/ and the build workflow: the full
all-in-one layout, or a wrapper image (upstream image + an IceStore start
script, no aio-init.sh) as Pocket ID uses to make per-install secrets.
Prints ERROR / WARN lines. Exit code 1 when there is any ERROR.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("pyyaml is missing: pip install pyyaml --break-system-packages")

REPO = "HSinghHira/IceStore"
CDN = f"https://cdn.jsdelivr.net/gh/{REPO}@main/Apps/"
CATEGORIES = {"Media", "Productivity", "Home", "Networking", "AI", "Finance", "Social", "Developer", "Others"}
SITE_ICONS = {"github", "plus", "plus-circle", "issues", "grid", "copy", "check", "search", "info",
              "external-link", "code", "arrow-left", "arrow-right", "package", "tag", "plug", "monitor",
              "table", "file-code", "server", "mail", "globe"}
SECRET = re.compile(r"(?:pass(?:word)?|secret|token|api[_-]?key|private[_-]?key|encryption[_-]?key)", re.I)
PORT_LOW, PORT_HIGH = 6101, 6199
# Apps with many ports get a block of 30 here instead (Ente: 6600, 6630, 6660).
BLOCK_LOW, BLOCK_HIGH = 6600, 6699
AIO_FILES = ["Dockerfile", "aio-init.sh", "run-svc.sh", "capture-meta.sh", "supervisord.conf",
             "nginx.conf.tpl", ".gitignore"]
OLD_NAMES = re.compile(r"ZimaAppStore|hiraappstore", re.I)
# Written in an address that the person must change before the app works
# (COMPOSE.md 7): http://[ZIMAOS-IP-ADDRESS]:61xx.
IP_PLACEHOLDER = "[ZIMAOS-IP-ADDRESS]"
PLACEHOLDER = re.compile(r"(?<![A-Za-z0-9])__[A-Z][A-Z0-9_]*__(?![A-Za-z0-9])")

errors, warns = [], []


COMPOSE_ENV = set()
README_VARS = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warns.append(msg)


def text(v):
    if isinstance(v, dict):
        v = v.get("en_US") or next(iter(v.values()), "")
    return str(v or "")


def env_pairs(env):
    if isinstance(env, dict):
        return {str(k): "" if v is None else str(v) for k, v in env.items()}
    out = {}
    for e in env or []:
        k, _, v = str(e).partition("=")
        out[k] = v
    return out


def published(svc):
    out = []
    for p in svc.get("ports") or []:
        if isinstance(p, dict):
            out.append((str(p.get("published", "")), str(p.get("target", ""))))
        else:
            parts = str(p).split("/")[0].split(":")
            out.append((parts[-2] if len(parts) > 1 else "", parts[-1]))
    return out


def url_port(url):
    m = re.match(r"https?://[^/:]+:(\d+)", url or "")
    return m.group(1) if m else None


def other_apps_ports(root, slug):
    taken = {}
    for f in Path(root, "Apps").glob("*/docker-compose.y*ml"):
        if f.parent.name == slug:
            continue
        try:
            data = yaml.safe_load(f.read_text(encoding="utf-8-sig")) or {}
        except yaml.YAMLError:
            continue
        for svc in (data.get("services") or {}).values():
            for pub, _ in published(svc or {}):
                if pub:
                    taken[pub] = f.parent.name
        pm = (data.get("x-casaos") or {}).get("port_map")
        if pm not in (None, ""):  # host-network apps only show their port here (same as ports.py)
            taken[str(pm)] = f.parent.name
    return taken


def check_compose(root, slug, app_dir):
    cf = app_dir / "docker-compose.yml"
    if not cf.exists():
        err(f"Apps/{slug}/docker-compose.yml is missing")
        return None
    raw = cf.read_text(encoding="utf-8-sig")
    try:
        data = yaml.safe_load(raw) or {}
    except yaml.YAMLError as ex:
        err(f"docker-compose.yml is not valid YAML: {ex}")
        return None

    for n, line in enumerate(raw.splitlines(), 1):
        s = line.strip()
        if s.startswith("#") and not re.match(r"#\s*(thumbnail|screenshot_link)\b|#\s*-\s*https://", s):
            err(f"docker-compose.yml line {n}: explanatory # comment (put it in an x-casaos field)")
    if PLACEHOLDER.search(raw):
        err(f"docker-compose.yml still has template placeholders: {sorted(set(PLACEHOLDER.findall(raw)))}")
    if OLD_NAMES.search(raw):
        err("docker-compose.yml still mentions ZimaAppStore / hiraappstore; use IceStore")

    if data.get("name") != slug:
        err(f"top-level name is '{data.get('name')}', must be the folder name '{slug}'")
    services = data.get("services") or {}
    meta = data.get("x-casaos") or {}
    if not services:
        err("no services")
        return None
    main = meta.get("main")
    if main not in services:
        err(f"x-casaos.main '{main}' is not a service")
        return None

    want_id = f"com.icestore.{slug}"
    top_id = meta.get("id")
    if not top_id:
        err("x-casaos.id is missing (the build action fails without it)")
    elif top_id != want_id:
        warn(f"x-casaos.id is '{top_id}', new apps use '{want_id}' (keep an old id only if people already installed it)")
    for name, svc in services.items():
        svc = svc or {}
        sid = (svc.get("x-casaos") or {}).get("id")
        if svc.get("ports") and sid != top_id:
            err(f"service '{name}': x-casaos.id '{sid}' does not match top-level id '{top_id}'")
        if svc.get("container_name") != name:
            warn(f"service '{name}': container_name is '{svc.get('container_name')}'")
        if svc.get("restart") != "unless-stopped":
            warn(f"service '{name}': restart should be unless-stopped")
        res = (svc.get("deploy") or {}).get("resources") or {}
        if not (res.get("limits") and res.get("reservations")):
            err(f"service '{name}': deploy.resources limits and reservations are required")
        for v in svc.get("volumes") or []:
            src = v.get("source") if isinstance(v, dict) else str(v).split(":")[0]
            if src and src.startswith("/") and not src.startswith("/DATA/AppData/$AppID"):
                warn(f"service '{name}': volume source '{src}' is outside /DATA/AppData/$AppID")

    if meta.get("category") not in CATEGORIES:
        err(f"category '{meta.get('category')}' is not one of {sorted(CATEGORIES)}")
    for key in ("title", "tagline", "description", "icon", "index", "port_map", "scheme", "architectures", "author"):
        if not meta.get(key):
            err(f"x-casaos.{key} is missing")
    have = [k for k in ("version", "update_at", "release_notes") if meta.get(k)]
    if have and len(have) != 3:
        err(f"version, update_at and release_notes go together (only {have} present)")

    msvc = services[main] or {}
    ports = published(msvc)
    to_check = [(name, pub) for name, svc in services.items() for pub, _ in published(svc or {})]
    if not ports and msvc.get("network_mode") == "host" and meta.get("port_map"):
        # host networking publishes nothing; the app listens on port_map directly
        pm = str(meta["port_map"])
        ports = [(pm, pm)]
        to_check.append((main, pm))
    if not ports:
        err(f"main service '{main}' publishes no port")
    taken = other_apps_ports(root, slug)
    for name, pub in to_check:
        if not pub.isdigit():
            err(f"service '{name}': published port '{pub}' must be a fixed number")
            continue
        if not (PORT_LOW <= int(pub) <= PORT_HIGH or BLOCK_LOW <= int(pub) <= BLOCK_HIGH):
            err(f"service '{name}': port {pub} is outside {PORT_LOW}-{PORT_HIGH} and {BLOCK_LOW}-{BLOCK_HIGH}")
        if pub in taken:
            err(f"port {pub} is already used by Apps/{taken[pub]}")

    for name, svc in services.items():
        image = str((svc or {}).get("image") or "")
        if not image or image.lower().startswith("ghcr.io/hsinghhira/"):
            continue  # all-in-one images are tagged by their own workflow
        tag = image.rsplit(":", 1)[1] if ":" in image.rsplit("/", 1)[-1] else ""
        if "@sha256:" not in image and tag in ("", "latest"):
            warn(f"service '{name}': image {image} is not pinned to a version tag")
    if str(meta.get("version", "")).lower() == "latest":
        warn("x-casaos.version is 'latest'; use the real upstream version")
    if ports and str(meta.get("port_map")) != ports[0][0]:
        err(f"x-casaos.port_map {meta.get('port_map')} does not match the main published port {ports[0][0]}")

    env = env_pairs(msvc.get("environment"))
    COMPOSE_ENV.update(env)
    if "TZ" in env and env["TZ"] != "$TZ":
        err("TZ must be $TZ")
    for k, v in env.items():
        if url_port(v) and ports and url_port(v) != ports[0][0] and ("localhost" in v or IP_PLACEHOLDER in v):
            err(f"{k}={v} uses port {url_port(v)}, but the app is published on {ports[0][0]}")
        if SECRET.search(k) and v and not v.startswith("$"):
            warn(f"{k} has a fixed value in the compose file, so every install gets the same one; make it "
                 f"on first start instead (the app itself, aio-init.sh, or a wrapper image, COMPOSE.md 9)")
    descs, notes = {}, {}
    for name, svc in services.items():
        for e in ((svc or {}).get("x-casaos") or {}).get("envs") or []:
            descs[e.get("container")] = name
            notes[e.get("container")] = text(e.get("description"))
    for k in env:
        if k not in descs:
            warn(f"{k} has no x-casaos.envs description")

    # values ZimaOS fills in ($PUID, $PGID, ...) are not settings people choose
    optional = [k for k, v in env.items()
                if k not in ("TZ", "PUBLIC_URL") and not k.startswith("ADMIN_") and not str(v).startswith("$")]
    if len(optional) > 3:
        warn(f"the compose environment has {len(optional)} optional settings ({', '.join(optional)}); keep it short "
             f"and list optional settings in README.md front matter 'variables:' (COMPOSE.md 8)")
    for k, svc_name in descs.items():
        if svc_name == main and k not in env:
            err(f"{k} is described in x-casaos.envs but missing from environment: (users cannot set it)")

    icon_urls = [meta.get("icon"), (msvc.get("labels") or {}).get("icon")]
    shots = meta.get("screenshot_link") or []
    for u in [x for x in icon_urls + [meta.get("thumbnail")] + list(shots) if x]:
        if not str(u).startswith(CDN + slug + "/"):
            err(f"image URL must start with {CDN}{slug}/ : {u}")
        else:
            f = app_dir / str(u)[len(CDN + slug + "/"):]
            if not f.exists():
                err(f"image URL points at a file that is not in the repo: {f.relative_to(root)}")

    tips = text((meta.get("tips") or {}).get("before_install"))
    for k, v in env.items():
        if IP_PLACEHOLDER not in str(v):
            continue
        if IP_PLACEHOLDER not in tips:
            err(f"{k} starts as {v}, but tips.before_install never tells people to replace {IP_PLACEHOLDER}")
        if IP_PLACEHOLDER not in notes.get(k, ""):
            warn(f"{k}'s x-casaos.envs description should say to replace {IP_PLACEHOLDER} with the ZimaOS IP")
    for n in range(2, 40):
        if re.search(rf"(?<!\n){n}\. ", tips) and not re.search(rf"\n\s*{n}\. ", tips):
            err(f"tips.before_install step {n} runs into the previous one (leave a blank line between steps)")
            break
    return data


def check_readme(slug, app_dir):
    rd = app_dir / "README.md"
    if not rd.exists():
        warn(f"Apps/{slug}/README.md is missing; the site falls back to the x-casaos description")
        return
    raw = rd.read_text(encoding="utf-8-sig").replace("\r\n", "\n")
    if PLACEHOLDER.search(raw):
        err(f"README.md still has template placeholders: {sorted(set(PLACEHOLDER.findall(raw)))}")
    m = re.match(r"---[ \t]*\n(.*?)\n---[ \t]*(?:\n|$)", raw, re.S)
    if m:
        try:
            fm = yaml.safe_load(m.group(1)) or {}
        except yaml.YAMLError as ex:
            err(f"README.md front matter is not valid YAML: {ex}")
            return
        unknown = set(fm) - {"name", "tagline", "category", "site", "source", "services", "screenshots", "variables"}
        if unknown:
            warn(f"README.md front matter keys the site ignores: {sorted(unknown)}")
        for s in fm.get("services") or []:
            ic = s.get("icon", "globe") if isinstance(s, dict) else (s[2] if len(s) > 2 else "globe")
            path = s.get("path", "/") if isinstance(s, dict) else (s[1] if len(s) > 1 else "/")
            if ic not in SITE_ICONS:
                err(f"README.md service icon '{ic}' is not in site/build.py ICONS: {sorted(SITE_ICONS)}")
            if not str(path).startswith("/"):
                warn(f"README.md service path '{path}' should start with /")
        seen = set()
        for i, v in enumerate(fm.get("variables") or []):
            if not isinstance(v, dict) or not v.get("name"):
                err(f"README.md variables item {i + 1} has no name")
                continue
            n = str(v["name"])
            if n in seen:
                err(f"README.md variable {n} is listed twice")
            seen.add(n)
            if n in COMPOSE_ENV:
                err(f"README.md variable {n} is also in the compose environment; keep it in one place")
            if "default" not in v:
                err(f"README.md variable {n} has no default (use \"\" when there is none)")
            elif v["default"] is not None and len(str(v["default"]).split()) > 3 and str(v["default"])[:1].islower():
                warn(f"README.md variable {n} default looks like prose ({v['default']!r}); use the real value or \"\" "
                     f"and explain in the description")
            if not text(v.get("description")):
                err(f"README.md variable {n} has no description")
            if not v.get("group"):
                warn(f"README.md variable {n} has no group")
            README_VARS.append(n)
        caps = fm.get("screenshots") or []
        shots = [p for p in app_dir.glob("screenshot*") if p.suffix.lower() in {".png", ".webp", ".jpg", ".jpeg", ".gif", ".svg"}]
        if caps and len(caps) != len(shots):
            warn(f"README.md has {len(caps)} screenshot captions for {len(shots)} screenshot files")
    if not re.search(r"(?m)^#\s+\S", raw):
        warn("README.md has no '# Title' line (the site drops the first one, so keep it)")
    if not list(app_dir.glob("icon.*")):
        err(f"Apps/{slug}/icon.png is missing")
    if not list(app_dir.glob("screenshot*")):
        warn(f"Apps/{slug} has no screenshot-N.png files; the site hides the slider")


def find_bash():
    """A real bash. On Windows, a bare "bash" starts the WSL launcher in System32, which fails
    with no message when no Linux distro is installed, so use Git Bash or skip the check."""
    found = shutil.which("bash")
    if found and "system32" in found.lower():
        found = None
    if not found and sys.platform == "win32":
        for p in (r"C:\Program Files\Git\bin\bash.exe", r"C:\Program Files\Git\usr\bin\bash.exe"):
            if Path(p).exists():
                found = p
                break
    return found


BASH = find_bash()


def sh_ok(path):
    if not BASH:
        warn(f"{path.name}: shell syntax not checked (no bash found; on Windows install Git for Windows)")
        return
    r = subprocess.run([BASH, "-n", str(path)], capture_output=True, text=True)
    if r.returncode:
        err(f"{path.name} has a shell syntax error: {r.stderr.strip()}")


def check_workflow(root, slug, data, aio):
    wf = Path(root, ".github", "workflows", f"build-{slug}.yml")
    if not wf.exists():
        err(f".github/workflows/build-{slug}.yml is missing (nothing builds the image)")
        return
    w = wf.read_text(encoding="utf-8")
    if f"docker/{slug}" not in w:
        err(f"build-{slug}.yml does not build docker/{slug}")
    if not re.search(rf"/{slug}\b", w):
        err(f"build-{slug}.yml does not push ghcr.io/<owner>/{slug}")
    if aio and "capture-meta.sh" not in w:
        err(f"build-{slug}.yml must run capture-meta.sh before the build")
    if "linux/arm64" not in w and "arm64" in (data.get("x-casaos") or {}).get("architectures", []):
        err("x-casaos lists arm64 but the workflow does not build linux/arm64")
    if "workflow_dispatch" not in w:
        err(f"build-{slug}.yml needs 'workflow_dispatch:' (update-upstream.yml starts the build with it)")
    if not re.search(r'(?m)^\s*AIO_VERSION:\s*"\d+\.\d+\.\d+"', w):
        warn(f'build-{slug}.yml: AIO_VERSION is not in the form "x.y.z", so the weekly bumper cannot raise it')


def check_bumper_shapes(root, slug, data, tags):
    """The weekly bumper (.github/scripts/update_upstream.py) edits these in place."""
    for tag in tags:
        if tag != "latest" and not re.search(r"\d", tag):
            warn(f"FROM tag '{tag}' has no numbers, so the weekly bumper never updates it")
    version = str((data.get("x-casaos") or {}).get("version") or "")
    commit_short = len(version) >= 7 and any(
        re.fullmatch(r"[0-9a-f]{40}", t) and t.startswith(version) for t in tags)
    if tags and version not in tags and not commit_short:
        warn(f"x-casaos.version '{version}' is not the tag of any upstream FROM line, "
             f"so the weekly bumper cannot keep it in step (use the main image's tag exactly)")
    compose_text = Path(root, "Apps", slug, "docker-compose.yml").read_text(encoding="utf-8")
    if not re.search(r"(?m)^  release_notes:\n    en_US: \|-?\n", compose_text):
        warn("release_notes is not written as 'en_US: |-' with bullets, so the weekly bumper cannot add notes")


def check_wrapper(root, slug, data):
    """Upstream image + an IceStore start script (per-install secrets), no aio-init.sh."""
    d = Path(root, "docker", slug)
    dockerfile = (d / "Dockerfile").read_text(encoding="utf-8")
    for f in d.iterdir():
        if not f.is_file():
            continue
        body = f.read_text(encoding="utf-8", errors="ignore")
        if PLACEHOLDER.search(body):
            err(f"docker/{slug}/{f.name} still has template placeholders: {sorted(set(PLACEHOLDER.findall(body)))}")
        if OLD_NAMES.search(body):
            err(f"docker/{slug}/{f.name} still mentions ZimaAppStore; use IceStore")
        if (f.suffix == ".sh" or f.name == "Dockerfile") and "\r\n" in body:
            err(f"docker/{slug}/{f.name} has Windows (CRLF) line endings; it must be LF to run in the image")
        if f.suffix == ".sh":
            sh_ok(f)
    froms = re.findall(r"(?m)^FROM\s+(\S+)", dockerfile)
    if len(froms) != 1:
        err(f"a wrapper Dockerfile has exactly one FROM (the upstream image); found {len(froms)}")
    tags = []
    for image in froms:
        tag = image.rsplit(":", 1)[1] if ":" in image.split("/")[-1] else ""
        if not tag or tag == "latest":
            warn(f"FROM {image} is not pinned to a version tag")
        else:
            tags.append(tag)
    m = re.search(r'org\.opencontainers\.image\.source="([^"]+)"', dockerfile)
    if not m or m.group(1).rstrip("/") != f"https://github.com/{REPO}":
        err(f"Dockerfile LABEL org.opencontainers.image.source must be https://github.com/{REPO} (GHCR links the package with it)")
    if not re.search(r"(?m)^ENTRYPOINT\b", dockerfile):
        err("a wrapper Dockerfile must set ENTRYPOINT to its start script")
    check_workflow(root, slug, data, aio=False)
    check_bumper_shapes(root, slug, data, tags)


def check_aio(root, slug, data):
    d = Path(root, "docker", slug)
    if not d.is_dir():
        err(f"image is ghcr.io/hsinghhira/{slug} but docker/{slug}/ does not exist")
        return
    if (d / "Dockerfile").exists() and not (d / "aio-init.sh").exists():
        check_wrapper(root, slug, data)
        return
    for f in AIO_FILES:
        if not (d / f).exists():
            err(f"docker/{slug}/{f} is missing")
    if (d / "gitignore").exists():
        err(f"docker/{slug}/gitignore must be named .gitignore (with the dot) or git ignores it")
    if any(not (d / f).exists() for f in AIO_FILES[:6]):
        return
    for f in d.iterdir():
        if not f.is_file():
            continue
        body = f.read_text(encoding="utf-8", errors="ignore")
        if PLACEHOLDER.search(body):
            err(f"docker/{slug}/{f.name} still has template placeholders: {sorted(set(PLACEHOLDER.findall(body)))}")
        if OLD_NAMES.search(body):
            err(f"docker/{slug}/{f.name} still mentions ZimaAppStore; use IceStore")
        if f.name in ("aio-init.sh", "run-svc.sh", "capture-meta.sh", "Dockerfile", "supervisord.conf",
                      "nginx.conf.tpl") and "\r\n" in body:
            err(f"docker/{slug}/{f.name} has Windows (CRLF) line endings; it must be LF to run in the image")
    for f in ("aio-init.sh", "run-svc.sh", "capture-meta.sh"):
        sh_ok(d / f)

    dockerfile = (d / "Dockerfile").read_text(encoding="utf-8")
    init = (d / "aio-init.sh").read_text(encoding="utf-8")
    runsvc = (d / "run-svc.sh").read_text(encoding="utf-8")
    sup = (d / "supervisord.conf").read_text(encoding="utf-8")
    tpl = (d / "nginx.conf.tpl").read_text(encoding="utf-8")

    strict = re.findall(r"(?m)^FROM [^ ]+ AS img-([a-z0-9]+)$", dockerfile)
    loose = re.findall(r"(?m)^FROM .* AS img-", dockerfile)
    if len(strict) != len(loose):
        err("a 'FROM ... AS img-<name>' line is not in the exact form capture-meta.sh reads")
    for name in strict:
        if re.search(rf"(?m)^FROM [^ ]+:latest AS img-{name}$", dockerfile) or \
                re.search(rf"(?m)^FROM [^ :]+ AS img-{name}$", dockerfile):
            warn(f"img-{name} is not pinned to a version tag")
    m = re.search(r'org\.opencontainers\.image\.source="([^"]+)"', dockerfile)
    if not m or m.group(1).rstrip("/") != f"https://github.com/{REPO}":
        err(f"Dockerfile LABEL org.opencontainers.image.source must be https://github.com/{REPO} (GHCR links the package with it)")
    if "EXPOSE 8080" not in dockerfile:
        err("Dockerfile must EXPOSE 8080 (the gateway port)")
    if not re.search(r"(?m)^GATEWAY_PORT=8080$", init):
        err("aio-init.sh must set GATEWAY_PORT=8080")

    programs = re.findall(r"(?m)^\[program:([\w-]+)\]", sup)
    if "gateway" not in programs:
        err("supervisord.conf has no [program:gateway]")
    case_labels = set(re.findall(r"(?m)^\s+([\w-]+)\)", runsvc))
    for p in programs:
        if p not in strict and p not in case_labels:
            err(f"[program:{p}] is neither an img-{p} stage nor a built-in case in run-svc.sh")
    for name in strict:
        if name not in programs and re.search(rf"COPY --from=img-{name}\s+/\s+/opt/rootfs/{name}/", dockerfile):
            err(f"img-{name} is copied into /opt/rootfs but has no [program:{name}]")
        if name in programs and not re.search(rf"(?m)^write_env {name}\b", init):
            err(f"service '{name}' has no 'write_env {name}' in aio-init.sh (run-svc.sh needs /run/aio/{name}.env)")
        chroot = re.search(rf"COPY --from=img-{name}\s+/\s+/opt/rootfs/{name}/", dockerfile)
        is_native = re.search(rf'NATIVE="[^"]*\b{name}\b|\b{name}\b[\w|]*\)\s*native=1', runsvc)
        if name in programs and not chroot and not is_native and name not in case_labels:
            warn(f"img-{name}: not copied to /opt/rootfs/{name}/ and not listed as native in run-svc.sh")

    for token in ("@GATEWAY_PORT@", "@EXTRA_LISTEN@"):
        if token not in tpl:
            err(f"nginx.conf.tpl is missing {token}")
    for token in set(re.findall(r"@[A-Z_]+@", tpl)):
        if f"s/{token}/" not in init:
            err(f"nginx.conf.tpl uses {token} but aio-init.sh never replaces it")

    services = data.get("services") or {}
    main = services[(data.get("x-casaos") or {}).get("main")] or {}
    ports = published(main)

    # Settings: every compose variable must reach a service, and blanks must be skipped.
    for line in re.findall(r"(?m)^[^#\n]*env\s*\|\s*grep[^\n]*>>[^\n]*$", init):
        if not re.search(r"=\.|=\S\)|\$2", line):
            err("aio-init.sh forwards variables with a bare 'env | grep ... >>', which also forwards blank "
                "values and overrides the defaults; use pass_env (AIO.md 3.5)")
    patterns = re.findall(r"(?m)^\s*pass_env\s+[\w-]+\s+'([^']+)'", init)
    for k in list(env_pairs(main.get("environment"))) + README_VARS:
        if re.search(rf"\${{?{re.escape(k)}\b", init) or re.search(rf"(?m)^\s*set_json\s+{re.escape(k)}\b", init):
            continue
        if any(re.fullmatch(f"(?:{p})", k) for p in patterns):
            continue
        err(f"{k} is a setting (compose environment or README variables) but aio-init.sh never reads it "
            f"(setting it would do nothing); "
            f"use it in write_env, set_json or a pass_env pattern")
    if ports and ports[0][1] != "8080":
        err(f"all-in-one apps publish container port 8080 (found target {ports[0][1]})")
    if "/opt/rootfs/" in dockerfile and main.get("privileged") is not True:
        err("chroot services need privileged: true (aio-init.sh mounts /proc for them)")
    if any(IP_PLACEHOLDER in str(v) for v in env_pairs(main.get("environment")).values()) \
            and IP_PLACEHOLDER not in init:
        err(f"the compose file ships {IP_PLACEHOLDER} in an address, but aio-init.sh never handles it "
            f"(it would reach the app as is); see AIO.md 3.5")
    m = re.search(r"PUBLIC_URL:-(\S+?)\}", init)
    if m and ports and url_port(m.group(1)) != ports[0][0]:
        err(f"aio-init.sh default PUBLIC_URL {m.group(1)} does not use the published port {ports[0][0]}")

    hc = " ".join(map(str, (main.get("healthcheck") or {}).get("test") or []))
    m1 = re.search(r"127\.0\.0\.1:8080(\S*)", hc)
    m2 = re.search(r"127\.0\.0\.1:8080(\S*)", dockerfile)
    if not m1:
        warn("compose healthcheck does not call http://127.0.0.1:8080/...")
    elif m2 and m1.group(1).strip('"') != m2.group(1).strip('"'):
        err(f"compose healthcheck path {m1.group(1)} differs from the Dockerfile HEALTHCHECK {m2.group(1)}")

    check_workflow(root, slug, data, aio=True)
    tags = re.findall(r"(?m)^FROM [^ :]+:(\S+) AS img-[a-z0-9]+$", dockerfile)
    check_bumper_shapes(root, slug, data, tags)


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    root, slug = Path(sys.argv[1]).resolve(), sys.argv[2]
    app_dir = root / "Apps" / slug
    if not app_dir.is_dir():
        sys.exit(f"{app_dir} does not exist")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", slug):
        err(f"folder name '{slug}' must be lowercase letters, digits and dashes")

    data = check_compose(root, slug, app_dir)
    check_readme(slug, app_dir)
    if data:
        main_svc = (data.get("services") or {}).get((data.get("x-casaos") or {}).get("main")) or {}
        if str(main_svc.get("image", "")).lower().startswith(f"ghcr.io/hsinghhira/{slug}"):
            check_aio(root, slug, data)
        elif str(main_svc.get("image", "")).lower().startswith("ghcr.io/hsinghhira/"):
            err(f"image {main_svc.get('image')} should be named ghcr.io/hsinghhira/{slug}")

    for w in warns:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    print(f"\n{slug}: {len(errors)} error(s), {len(warns)} warning(s)")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
