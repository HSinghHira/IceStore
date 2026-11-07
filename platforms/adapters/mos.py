"""MOS Hub repository (MOS, the Devuan-based home server OS by ich777).

Layout (the root of its own repo, entered in Settings -> MOS Hub Settings):

    maintainer.json
    docker/<Name>.json              single-container template, shown as a form
    compose/<Name>/compose.yaml     stack template, for anything a form cannot hold
    compose/<Name>/.env             the settings people change before deploying
    compose/<Name>/template.json    how the stack shows in MOS Hub

An app becomes a docker/ template when it is one service whose settings all fit
the MOS form (image, network, ports, paths, variables, devices, privileged and
`docker run` flags). Anything else (several services, an entrypoint script, a
command, custom networks) becomes a compose/ stack that is the master compose
with x-casaos removed and host folders moved into .env. Force either with
`format: docker | compose` in platforms/mos/overrides/<app>.yml.
"""
import json
import re
import shlex

import yaml

from model import deep_merge, dump_yaml, env_list, parse_port, parse_volume, walk

from .base import Adapter, Skip

SECRET = re.compile(r"pass(?:word)?|secret|token|api[_-]?key|private[_-]?key|encryption", re.I)
# ZimaOS fills these in itself, so the master descriptions say so; MOS does not.
OWN_WORDS = {
    "TZ": "Your time zone, like Europe/London or America/New_York.",
    "PUID": "The user id that owns the app's files. 500 is the MOS default.",
    "PGID": "The group id that owns the app's files. 500 is the MOS default.",
}
# Service keys the docker/ form (plus extra_parameters) can carry. Anything else -> compose.
DOCKER_KEYS = {"image", "container_name", "restart", "stop_grace_period", "network_mode", "privileged",
               "environment", "ports", "volumes", "healthcheck", "deploy", "labels", "x-casaos", "init",
               "user", "cap_add", "cap_drop", "security_opt", "shm_size", "hostname", "devices", "tmpfs",
               "read_only", "pid", "extra_hosts", "logging"}


def safe_name(title):
    return re.sub(r"[^A-Za-z0-9]+", "-", title).strip("-") or "App"


def seconds(v):
    m = re.fullmatch(r"\s*(\d+)\s*(ms|s|m|h)?\s*", str(v))
    if not m:
        return None
    n, unit = int(m.group(1)), m.group(2) or "s"
    return {"ms": max(1, n // 1000), "s": n, "m": n * 60, "h": n * 3600}[unit]


def unescape(s):
    """Compose writes a literal $ as $$; docker run does not interpolate, so undo it."""
    return s.replace("$$", "$")


def registry_url(image):
    ref = re.split(r"[@:](?=[^/]*$)", image, 1)[0]
    if ref.startswith("ghcr.io/"):
        owner, _, name = ref[len("ghcr.io/"):].partition("/")
        return f"https://github.com/{owner}/{name.split('/')[0]}/pkgs/container/{name.split('/')[-1]}"
    if "." not in ref.split("/")[0] or ref.startswith("docker.io/"):
        ref = ref.removeprefix("docker.io/")
        return f"https://hub.docker.com/{'_/' + ref if '/' not in ref else 'r/' + ref}"
    return f"https://{ref}"


class MOS(Adapter):
    name = "mos"

    # ------------------------------------------------------------------ per app
    def build_app(self, app, out, result):
        ov = self.enabled(app, result)
        fmt_ = ov.get("format") or ("docker" if self.fits_form(app) else "compose")
        result.format = fmt_
        if "arm64" not in app.architectures:
            result.warnings.append("amd64 only")
        name = ov.get("name") or safe_name(app.title)
        if fmt_ == "docker":
            self.docker_template(app, name, out, ov, result)
        else:
            self.compose_template(app, name, out, ov, result)
        result.port = app.port

    def fits_form(self, app):
        svcs = app.services()
        if len(svcs) != 1 or app.compose.get("networks"):
            return False
        svc = next(iter(svcs.values()))
        return set(svc) <= DOCKER_KEYS and svc.get("network_mode", "bridge") in ("bridge", "host")

    def web_ui(self, app, form):
        """http://[IP]:[PORT:<container port>]/ in a form (MOS fills in the host port), a plain port in a stack."""
        path = app.path if app.path.startswith("/") else "/" + app.path
        svc = app.services().get(app.main, {})
        if form and svc.get("network_mode") != "host":
            for p in svc.get("ports") or []:
                pp = parse_port(p)
                if pp["published"] == app.port:
                    return f"{app.scheme}://[IP]:[PORT:{pp['target']}]{path}"
        return f"{app.scheme}://[IP]:{app.port}{path}" if app.port else ""

    def common(self, app):
        return {
            "icon": app.icon,
            "project": app.website,
            "support": app.support,
            "readme_url": app.site_page(self.store["site"]),
            "description": self.words(app.tagline, app),
            # MOS Hub hides templates whose list does not hold the machine's arch (amd64 / arm64)
            "architecture": app.architectures or None,
        }

    # ---- docker/<Name>.json
    def docker_template(self, app, name, out, ov, result):
        svc_name = app.main
        svc = self.translate(app.services()[svc_name], app)
        svc = walk(svc, unescape)
        self.not_carried(svc, result)
        extra = []

        if svc.get("restart"):
            extra.append(f"--restart={svc['restart']}")
        if svc.get("init"):
            extra.append("--init")
        if svc.get("stop_grace_period") and seconds(svc["stop_grace_period"]):
            extra.append(f"--stop-timeout={seconds(svc['stop_grace_period'])}")
        res = (svc.get("deploy") or {}).get("resources") or {}
        lim, rsv = res.get("limits") or {}, res.get("reservations") or {}
        if lim.get("memory"):
            extra.append(f"--memory={str(lim['memory']).lower()}")
        if lim.get("cpus"):
            extra.append(f"--cpus={lim['cpus']}")
        if rsv.get("memory"):
            extra.append(f"--memory-reservation={str(rsv['memory']).lower()}")
        for key, flag in (("user", "--user"), ("shm_size", "--shm-size"), ("hostname", "--hostname"),
                          ("pid", "--pid")):
            if svc.get(key):
                extra.append(f"{flag}={shlex.quote(str(svc[key]))}")
        for key, flag in (("cap_add", "--cap-add"), ("cap_drop", "--cap-drop"), ("security_opt", "--security-opt")):
            for v in svc.get(key) or []:
                extra.append(f"{flag}={shlex.quote(str(v))}")
        if svc.get("read_only"):
            extra.append("--read-only")
        tmpfs = svc.get("tmpfs") or []
        for t in [tmpfs] if isinstance(tmpfs, str) else tmpfs:
            extra.append(f"--tmpfs {shlex.quote(str(t))}")
        hosts = svc.get("extra_hosts") or []
        if isinstance(hosts, dict):
            hosts = [f"{k}:{v}" for k, v in hosts.items()]
        for h in hosts:
            extra.append(f"--add-host={str(h).replace('=', ':')}")
        extra += self.health(svc.get("healthcheck"), result)

        paths = []
        for v in svc.get("volumes") or []:
            vv = parse_volume(v)
            host = vv["source"]
            if vv["type"] == "volume":
                host = f"{self.cfg['path_map'].get('/DATA/AppData/$AppID', '/mnt/cache/appdata/{slug}')}"\
                    .replace("{slug}", app.slug) + f"/{host or vv['target'].strip('/').replace('/', '-')}"
                result.warnings.append(f"named volume {vv['source']} -> {host}")
            desc = self.words(app.described(svc_name, "volumes", vv["target"]), app)
            paths.append({
                "name": "AppData" if host.rstrip("/").endswith("/" + app.slug) else
                        vv["target"].rstrip("/").rsplit("/", 1)[-1].replace("-", " ").title() or "Path",
                "host": host, "container": vv["target"], "mode": "ro" if vv["read_only"] else "rw",
                "description": desc or None,
            })
        ports = []
        for p in svc.get("ports") or []:
            pp = parse_port(p)
            ports.append({
                "name": "Web UI" if pp["published"] == app.port else f"Port {pp['target']}",
                "protocol": pp["protocol"], "host": pp["published"] or pp["target"],
                "container": pp["target"],
                "description": self.words(app.described(svc_name, "ports", pp["target"]), app) or None,
            })
        variables = []
        for k, v in env_list(svc.get("environment")):
            if re.search(r"(?<!\$)\$\{?[A-Za-z_]", v):
                result.warnings.append(f"{k} still refers to a variable: {v}")
            desc = OWN_WORDS.get(k) or self.words(app.described(svc_name, "envs", k), app)
            variables.append({"name": k, "key": k, "value": v, "mask": bool(SECRET.search(k)),
                              "description": desc or None})
        devices = []
        for i, dv in enumerate(svc.get("devices") or [], 1):
            parts = str(dv).split(":")
            devices.append({"name": f"Device {i}", "host": parts[0],
                            "container": parts[1] if len(parts) > 1 else parts[0], "description": None})

        t = {
            "name": name,
            "repo": svc["image"],
            "category": [self.category(app)],
            "registry": registry_url(svc["image"]),
            "network": "host" if svc.get("network_mode") == "host" else "bridge",
            "custom_ip": None,
            "default_shell": "sh",
            "privileged": bool(svc.get("privileged")),
            "extra_parameters": " ".join(extra) or None,
            "post_parameters": None,
            "cpu_set": None,
            "web_ui_url": self.web_ui(app, form=True),
            **self.common(app),
            "paths": paths,
            "ports": ports,
            "variables": variables,
            "devices": devices,
            "labels": [],
            "gpus": [],
        }
        deep_merge(t, ov.get("template"))
        d = out / "docker"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{name}.json").write_text(json.dumps(t, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
        result.path = d / f"{name}.json"

    def not_carried(self, svc, result):
        """Warn about every compose setting the docker/ form has no place for (never drop one silently)."""
        lost = []
        if svc.get("logging"):
            lost.append("logging")
        labels = svc.get("labels") or {}
        extra_labels = [k for k in labels if k != "icon"] if isinstance(labels, dict) else list(labels)
        if extra_labels:
            lost.append("labels " + ", ".join(map(str, extra_labels)))
        deploy = svc.get("deploy") or {}
        lost += [f"deploy.{k}" for k in deploy if k != "resources"]
        res = deploy.get("resources") or {}
        lost += [f"deploy.resources.{k}" for k in res if k not in ("limits", "reservations")]
        lost += [f"deploy.resources.limits.{k}" for k in res.get("limits") or {} if k not in ("memory", "cpus")]
        rsv = res.get("reservations") or {}
        lost += [f"deploy.resources.reservations.{k}" for k in rsv if k not in ("memory", "cpus")]
        try:
            if float(rsv.get("cpus") or 0) > 0:
                lost.append("deploy.resources.reservations.cpus")
        except ValueError:
            lost.append("deploy.resources.reservations.cpus")
        if svc.get("stop_grace_period") and not seconds(svc["stop_grace_period"]):
            lost.append("stop_grace_period")
        if lost:
            result.warnings.append("not carried into the MOS form: " + "; ".join(lost))

    def health(self, hc, result):
        if not hc:
            return []
        if hc.get("disable"):
            return ["--no-healthcheck"]
        test = hc.get("test")
        if isinstance(test, list):
            kind, args = test[0], test[1:]
            if kind == "NONE":
                return ["--no-healthcheck"]
            cmd = args[0] if kind == "CMD-SHELL" else shlex.join(args)
        else:
            cmd = str(test or "")
        if not cmd or '"' in cmd or "\\" in cmd:
            result.warnings.append("health check left out (too complex for a docker run flag)")
            return []
        out = [f'--health-cmd="{cmd}"']
        for key, flag in (("interval", "--health-interval"), ("timeout", "--health-timeout"),
                          ("start_period", "--health-start-period")):
            if hc.get(key):
                out.append(f"{flag}={hc[key]}")
        if hc.get("retries"):
            out.append(f"--health-retries={hc['retries']}")
        return out

    # ---- compose/<Name>/
    def compose_template(self, app, name, out, ov, result):
        # Host folders and the IP placeholder become .env settings, so people change them in one place.
        env, pm = {}, {}
        for src, dst in (self.cfg.get("path_map") or {}).items():
            var = "APPDATA" if src.endswith("$AppID") else src.rstrip("/").rsplit("/", 1)[-1].upper() + "_PATH"
            pm[src] = "${" + var + "}"
            env[var] = dst.replace("{slug}", app.slug)
        holders = {k: "${SERVER_IP}" for k in self.cfg.get("placeholders") or {}}
        env["SERVER_IP"] = next(iter((self.cfg.get("placeholders") or {}).values()), "YOUR-SERVER-IP")
        c = self.translate(app.compose, app, keep_vars=("TZ", "PUID", "PGID"), path_map=pm, placeholders=holders)
        c.pop("x-casaos", None)
        for svc in c["services"].values():
            svc.pop("x-casaos", None)
            labels = svc.get("labels")
            if isinstance(labels, dict):
                labels.pop("icon", None)
                if not labels:
                    svc.pop("labels")
        deep_merge(c, ov.get("compose"))
        body = dump_yaml(c)

        defaults = {k: v.replace("{slug}", app.slug) for k, v in (self.cfg.get("vars") or {}).items()
                    if k in ("TZ", "PUID", "PGID")}
        env = {**defaults, **env, **(ov.get("env") or {})}
        used = [k for k in env if re.search(r"(?<!\$)\$\{?" + k + r"\b", body)]
        env_lines = [f"# {app.title} for MOS. Change these before you deploy.", ""]
        env_lines += [f"{k}={env[k]}" for k in used]

        t = {"name": app.title, "category": [self.category(app)],
             "web_ui_url": self.web_ui(app, form=False),
             "website": app.website, **self.common(app)}
        deep_merge(t, ov.get("template"))

        d = out / "compose" / name
        d.mkdir(parents=True, exist_ok=True)
        (d / "compose.yaml").write_text(
            f"# Generated from Apps/{app.slug}/docker-compose.yml by platforms/generate.py.\n"
            f"# Do not edit here; change the master file or platforms/mos/overrides/{app.slug}.yml.\n" + body,
            encoding="utf-8", newline="\n")
        (d / ".env").write_text("\n".join(env_lines) + "\n", encoding="utf-8", newline="\n")
        (d / "template.json").write_text(json.dumps(t, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
        result.path = d

    # ------------------------------------------------------------------ store
    def build_store(self, apps, results, out):
        (out / "maintainer.json").write_text(
            json.dumps({"maintainer": self.store.get("maintainer"), "donation": self.store.get("donation")},
                       indent=2) + "\n", encoding="utf-8", newline="\n")

    # MOS reads docker/*.json (files only) and compose/*/ from the repo root. IceStore's own
    # docker/<app>/ build folders sit beside the templates and MOS skips them.
    def owned(self, root):
        return [*sorted((root / "docker").glob("*.json")), root / "compose", root / "maintainer.json"]

    def outputs(self, out):
        return [*sorted((out / "docker").glob("*.json")), out / "compose", out / "maintainer.json"]

    # ------------------------------------------------------------------ checks
    def check(self, out, results):
        names = {}
        for slug, r in results.items():
            if r.status != "ok":
                continue
            if r.path.is_dir():                                   # compose/<Name>/
                t = json.loads((r.path / "template.json").read_text(encoding="utf-8"))
                need = ("name", "description", "icon", "category")
                compose = (r.path / "compose.yaml").read_text(encoding="utf-8")
                body = compose + (r.path / ".env").read_text(encoding="utf-8")
                c = yaml.safe_load(compose)
                if not c.get("services"):
                    r.errors.append("compose.yaml has no services")
            else:                                                 # docker/<Name>.json
                t = json.loads(r.path.read_text(encoding="utf-8"))
                need = ("name", "repo", "network", "icon", "paths", "ports", "variables")
                body = json.dumps(t)
            for k in need:
                if t.get(k) in (None, "") and not (k in ("paths", "ports", "variables") and t.get(k) == []):
                    r.errors.append(f"template has no {k}")
            for bad in ("/DATA/", "$AppID", "${AppID}", "[ZIMAOS-IP-ADDRESS]", "x-casaos"):
                if bad in body:
                    r.errors.append(f"output still has {bad}")
            key = r.path.name.lower()
            if key in names:
                r.errors.append(f"same template name as {names[key]}")
            names[key] = slug
