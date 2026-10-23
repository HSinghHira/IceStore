# AIO.md — all-in-one images (docker/<app>/)

One image, one port (8080 inside, 61xx outside), one `/data` folder, many
upstream services. `examples/appflowy/docker/appflowy/` is the working reference;
`templates/aio/` is the skeleton with `__PLACEHOLDERS__` and `APP-SPECIFIC` markers.

## 1. How it runs

```
docker start
 └─ aio-init  (ENTRYPOINT, runs as root, once per start)
     1. PUBLIC_URL check, defaults (default port = the app's 61xx port)
     2. /data/state/secrets.env: make missing secrets with openssl, read them back
     3. /etc/hosts: upstream service names → 127.0.0.1
     4. every /opt/rootfs/<svc>/: hosts, resolv.conf, /proc, /sys, /dev/shm, /dev nodes,
        stdout/stderr fifos
     5. nginx.conf.tpl → /etc/nginx/aio.conf (@GATEWAY_PORT@, @EXTRA_LISTEN@, ...)
     6. /run/aio/<svc>.env for every service, then container env pass-through,
        then /data/state/overrides/<svc>.env
     7. first start only: initdb
     8. exec supervisord
         └─ one [program:<svc>] each → run-svc <svc>
             a. wait for its dependencies (pg, tcp:<port>, http://... health)
             b. start it as one of three kinds (below)
         └─ [program:gateway] → nginx on 8080 (+ the PUBLIC_URL port)
```

Logs: every line is prefixed `[<svc>]` by run-svc, `[init]` by aio-init.
`AIO_DRY_RUN=1` stops aio-init after step 6 (config files a setting is written
into, like AFFiNE's `config.json`, are already written by then, so check them too). Every path can be moved with
`AIO_DATA`, `AIO_ROOTFS`, `AIO_META`, `AIO_RUN`, `AIO_HOSTS`, `AIO_NGINX_TPL`,
`AIO_NGINX_OUT`, which is how it is tested outside Docker (§6).

## 2. Three kinds of service

| Kind | What it is | Use for | AppFlowy |
|---|---|---|---|
| built-in | installed with apt in the base image, started by an explicit `case` in run-svc.sh | Postgres, Redis, nginx gateway, any single static binary you extract (MinIO/Silo) | postgres, redis, silo, gateway |
| native | binary copied out of its image into the base image; started with its image's entrypoint/cmd/env/workdir from meta, without chroot | glibc or static servers that need a real `/proc` or misbehave in a chroot | cloud, worker, search (Rust) |
| chroot | the whole upstream filesystem at `/opt/rootfs/<svc>`, started with `chroot --userspec` and its image's entrypoint/cmd/env/workdir/user | everything else: Alpine/musl images, Node, Python, Go apps with assets | gotrue, admin, web, mailpit |

Choose **chroot** by default — it runs the image exactly as upstream ships it.
Choose **native** only for a binary that runs on Debian trixie (glibc ≥ the one it
was built against, or static) and has a reason to avoid the chroot. Choose
**built-in** for data stores, so the Postgres/Redis version is under your control.

Base image is `debian:trixie-slim`. Postgres comes from the PGDG apt repo.

## 3. Porting a new app, step by step

### 3.1 Make the service table first

From upstream's `docker-compose.yml`, `.env` example and docs, list each
service before writing code:

| svc | image:tag | kind | listens on | waits for | health URL | data path | env vars |
|---|---|---|---|---|---|---|---|

Rules for the table:
- **Pin tags.** Check the registry for the current release; don't use `latest`.
- **Check arm64.** If any image lacks arm64, remove `linux/arm64` from the
  workflow and `arm64` from `x-casaos.architectures`, and tell the user.
- **Unique ports.** All services share 127.0.0.1. `8080` is the gateway's. If two
  services want the same port, move one with its env var (AppFlowy's admin
  frontend: `PORT=3100`). If an image's port can't be changed, the others move.
- **Postgres major version** = what upstream's compose uses (and any extension:
  `postgresql-16-pgvector`). Once users have data, changing the major version
  needs a dump/restore, so pick it carefully.
- Drop optional extras (AI services, pgAdmin) and say so in `release_notes`.

### 3.2 Dockerfile

- One line per upstream image, exactly `FROM <image>:<tag> AS img-<svc>`.
  capture-meta.sh reads this pattern; `<svc>` is lowercase and equals the
  supervisord program name and `/opt/meta/<svc>.json`.
- Pin a tag with numbers in it, in the form upstream releases use (`0.19.2`,
  `v1.31.4`, `2026.8.4`). The weekly bumper (`REPO.md`, update-upstream.yml)
  only moves a tag to a newer one of the same shape. To keep it from moving,
  put `# auto-update: hold` on the line above, with the reason.
- Built-ins: add apt packages. Extracting a binary (Silo):
  a small `debian:bookworm-slim` stage that `find`s it and `install -D`s it to
  `/out/...`, then `COPY --from=` that stage.
- Native: a stage that copies the image's `/` to `/r/<svc>` and installs only the
  binary (plus its `/app` data folder, if any) — see AppFlowy's `rust-bins` stage.
- Chroot: `COPY --from=img-<svc> / /opt/rootfs/<svc>/`.
- Keep `COPY meta/ /opt/meta/`, the four script/config copies, `EXPOSE 8080`,
  the `HEALTHCHECK`, `ENTRYPOINT ["/usr/local/bin/aio-init"]`, and the LABEL
  `org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"`.

### 3.3 supervisord.conf

One `[program:<svc>]` per service, all with
`command=/usr/local/bin/run-svc %(program_name)s`. Priorities: 10 data stores,
20 storage/mail, 30 auth, 40 main API, 50 workers/frontends, 60 gateway.
Postgres gets `stopsignal=INT` and `stopwaitsecs=60`. Priority only orders the
starts; real ordering comes from the waits in run-svc.sh.

### 3.4 run-svc.sh

Copy the template. Edit only the marked blocks:
- `NATIVE="..."` — native service names (AppFlowy writes this as
  `case $svc in cloud|worker|search) native=1`; either form works).
- the wait `case` — each service waits for what it connects to at startup.
  Specs: `pg`, `tcp:<port>`, `http://127.0.0.1:<port>/<health>`. The gateway
  waits for the main API, so the container health only goes green when the app
  is up. Waits give up after 15 minutes and supervisord restarts the service.
- the built-in `case` — exact commands for postgres, redis, nginx, and any
  extracted binary (load its env with `load_env "$RUN/<svc>.env"` first).

The generic part below needs no changes.

### 3.5 aio-init.sh

- `PUBLIC_URL` default: `http://localhost:<61xx>`.
- `mkdir -p` one folder per stateful service under `$DATA`.
- `ensure_secret NAME BYTES` for every secret (DB password, JWT secret, S3 keys,
  admin password...). Secrets that two services share are one secret used in both
  env files — that's the main benefit over the multi-container compose.
- `/etc/hosts` line: every service name from upstream's compose
  (`appflowy_postgres`, `appflowy-minio`...). Then upstream defaults like
  `http://appflowy_gotrue:9999` keep working unchanged.
- `INTERNAL_PORTS`: every port any service listens on. The gateway also listens
  on the PUBLIC_URL port unless it collides with one of these. This exists
  because some services call `PUBLIC_URL` from inside the container (server-side
  rendering, OAuth callbacks); inside the container `localhost:6101` must reach
  the gateway too.
- `write_env <svc> ...` for **every** native and chroot service, even if it only
  gets `TZ` — run-svc.sh reads `/run/aio/<svc>.env` and fails without it.
  Copy upstream's env block. Browser-facing URLs use `$PUBLIC_URL` plus the path
  the gateway serves (`$PUBLIC_URL/gotrue`, `$PUBLIC_URL/minio-api`, `ws://.../ws/v2`).
  Service-to-service URLs use the hosts names or 127.0.0.1. Point every data
  directory into `$DATA`.
- **Wire up every setting** — the compose `environment:` and every README
  `variables:` entry (`COMPOSE.md` §8). People add README ones in the ZimaOS
  app settings, so they arrive as ordinary container variables. Each one
  reaches its service in one of three ways, and a missing or blank value must
  always mean "use the default":
  1. **The service reads it by its own name** (`GOTRUE_DISABLE_SIGNUP`,
     `MAILER_HOST`): forward it with `pass_env <svc> '<regex>'`, which copies
     matching container variables into `/run/aio/<svc>.env` and **skips blank
     ones**. Never use a bare `env | grep '^PREFIX_' >> ...`: it forwards
     `NAME=` too, and an empty value written after the default replaces it
     (env files are read top to bottom, last one wins). The checker rejects it.
  2. **AIO needs a default or a derived value** (SMTP that falls back to the
     built-in mail viewer, an OAuth redirect URI built from `PUBLIC_URL`): use
     `"NAME=${NAME:-default}"` inside `write_env`. `:-` treats blank as unset.
  3. **Upstream has no variable for it** (a key in its config file, or a value
     several services share): read the variable in aio-init and write it where
     it belongs — e.g. with `jq` into the app's `config.json` — on **every**
     start, so changing it in ZimaOS later works. When it is blank, leave the
     file alone — unless aio-init wrote that key on an earlier start; then
     take it out again, so blank really means "default" and a value someone
     set by hand is never wiped. AFFiNE's `set_json` does exactly this (it keeps
     the names it wrote in `/data/state/settings-applied`); copy it from
     `IceStore/docker/affine/aio-init.sh`. The checker counts a variable named
     as the first argument of `set_json` as read.
  Watch for apps that copy env vars into a config file or database once and
  ignore them afterwards (AFFiNE does this with `config.json`). For those,
  route the variable through way 3, or a change after install silently does
  nothing.
- Keep the overrides loop (`/data/state/overrides/<svc>.env`) and the
  `AIO_DRY_RUN` exit.
- First-start database: `initdb` as in the template. If the app needs extra
  databases, roles or extensions that it doesn't create itself, do it once with a
  temporary server, right after initdb:

  ```bash
  pgbin=/usr/lib/postgresql/16/bin
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/pg_ctl -D "$DATA/postgres" -o "-c listen_addresses=''" -w start >/dev/null
  setpriv --reuid=postgres --regid=postgres --init-groups \
    psql -h /run/postgresql -U postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE app2;"
  setpriv --reuid=postgres --regid=postgres --init-groups \
    $pgbin/pg_ctl -D "$DATA/postgres" -w stop >/dev/null
  ```

  Guard it so it only runs on first start (inside the `PG_VERSION` check), or
  make each statement idempotent.

### 3.6 Data inside a chroot

A chroot service sees only `/opt/rootfs/<svc>`. Anything it writes there is
**lost on update**, because the image is replaced. If a chroot service keeps
data, bind-mount a `/data` folder into it in aio-init's rootfs loop, after the
`/proc` mount, and give it to the service's user:

```bash
# APP-SPECIFIC: persistent folder for the chroot service "app" at /app/data
if [ "$(basename "$d")" = app ]; then
  mkdir -p "$DATA/app" "$d/app/data"
  mountpoint -q "$d/app/data" || mount --bind "$DATA/app" "$d/app/data"
  uid=$(awk -F: '$1=="node"{print $3":"$4}' "$d/etc/passwd")
  [ -n "$uid" ] && chown -R "$uid" "$DATA/app"
fi
```

AppFlowy needs none of this: its chroot services are stateless and its native
services write to `$DATA` directly.

### 3.7 nginx.conf.tpl

Copy the `location` blocks from upstream's own nginx config or reverse-proxy
docs and point each at `127.0.0.1:<port>`. Keep `listen @GATEWAY_PORT@;` and
`@EXTRA_LISTEN@`. Any other `@TOKEN@` must have a matching `sed -e "s/@TOKEN@/..."`
in aio-init (AppFlowy uses `@WEB_PORT@`, read from the web image's
`ExposedPorts`). Long requests (imports, websockets, streaming) need their own
timeouts and buffering settings — copy them from upstream. Set
`client_max_body_size` to what uploads need.

### 3.8 capture-meta.sh, .gitignore, workflow

capture-meta.sh is generic; copy it. The ignore file must be named `.gitignore`
(with the dot) and contain `meta/`. The workflow comes from
`templates/build-workflow.yml` with `__APP__` replaced; start `AIO_VERSION` at
`1.0.0`. Keep `workflow_dispatch:` and the `AIO_VERSION: "x.y.z"` form; the
weekly bumper needs both.

### 3.9 Compose file

`templates/docker-compose.aio.yml`: container port 8080, published 61xx,
`privileged: true` if there is any chroot service, `/data` volume, healthcheck
path = the Dockerfile HEALTHCHECK path, memory limit sized for all services
together (AppFlowy: 3072M limit, 512M reservation).

## 4. Updating an AIO app

`update-upstream.yml` does steps 1, 3 and 4 every Monday on its own
(`REPO.md`). Do them by hand only for a held tag, a shape change (`pg16` →
`pg17`, a new major scheme) or when the user asks; step 2 is always by hand.
After an automatic bump, if upstream added env vars, ports or services, step 2
still has to happen.

1. Check every upstream image's releases. Change the `FROM` tags.
2. Read upstream's changelog and compose diff for new env vars, ports, services
   or migrations, and mirror them in aio-init.sh / run-svc.sh / nginx.conf.tpl.
3. Bump `AIO_VERSION` in `build-<app>.yml`.
4. Update `x-casaos.version`, `update_at`, `release_notes` (new tags) in the compose.
5. Run the checker and the dry run.

## 5. Known traps

- `FROM` line not in the exact form → capture-meta skips it → run-svc fails with
  "missing /opt/meta/<svc>.json". capture-meta now fails the build instead.
- A service without `write_env` → run-svc exits at `mapfile < $RUN/<svc>.env`.
- No `privileged: true` → `/proc` isn't mounted in chroots; many runtimes fail
  in odd ways. aio-init logs "procfs is NOT mounted".
- Hardcoded port drift: the 61xx port appears in compose (published, port_map,
  PUBLIC_URL, descriptions, tips) and aio-init's default. The checker compares
  the machine-readable ones; read the text ones yourself.
- Blank variables: ZimaOS passes a variable someone left empty (or added
  without a value) as an empty string. Anything that forwards them as-is
  overrides the default with nothing (gotrue reads `GOTRUE_DISABLE_SIGNUP=`
  as invalid). Use `pass_env` or `${NAME:-default}`.
- A setting that is in the compose file or the README list but never read by
  aio-init.sh does nothing. The checker flags every such name that aio-init.sh
  neither mentions nor matches with a `pass_env` pattern or `set_json`.
- Pass-through prefixes overlap (`APPFLOWY_` also matches `APPFLOWY_WORKER_`).
  Harmless, but put service-specific prefixes on the service that owns them.
- S3 storage: AppFlowy uses Silo (`pgsty/silo`), the community fork of MinIO,
  extracted as one binary and started as a built-in. Reuse that stage and run-svc
  case for any app that needs S3 instead of picking a new S3 server.
- First start is slow (initdb, migrations, every service waiting in turn). Set
  the healthcheck `start_period` and the "wait about N minutes" tip to match.

## 6. Testing without Docker

The dry run checks secrets, env files and the nginx config with no root and no
Docker (from the repo root):

```bash
D=$(mktemp -d); mkdir -p $D/data $D/rootfs $D/run $D/meta; cp /etc/hosts $D/hosts
AIO_DATA=$D/data AIO_ROOTFS=$D/rootfs AIO_META=$D/meta AIO_RUN=$D/run AIO_HOSTS=$D/hosts \
AIO_NGINX_TPL=docker/<app>/nginx.conf.tpl AIO_NGINX_OUT=$D/nginx.conf AIO_DRY_RUN=1 \
bash docker/<app>/aio-init.sh
cat $D/nginx.conf; head $D/run/*.env
```

Run it a second time with a few README variables set and one left blank
(`MAILER_HOST=smtp.example.com MAILER_PORT= ...`): the set one must appear in
the right env file or config file, the blank one must not appear at all.

Look for: every service has an env file, `listen 8080;` plus `listen <61xx>;`,
no `@TOKEN@` left in nginx.conf, URLs built from the right PUBLIC_URL. If nginx
is installed, `nginx -t -c $D/nginx.conf`.

With Docker available, the full test is:

```bash
cd docker/<app> && bash capture-meta.sh && docker build -t <app>-test .
docker run --rm --privileged -p 61xx:8080 -v "$PWD/test-data:/data" <app>-test
```
