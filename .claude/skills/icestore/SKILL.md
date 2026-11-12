---
name: advanced-zimaos-app-creator
description: Use when adding or updating an app in IceStore (the HSinghHira/IceStore GitHub repo), the community app store for ZimaOS, CasaOS, ReCasaOS, Homeio and MOS (MOS Hub templates generated from the same Apps/ folder), especially an all-in-one app that bundles several upstream images (database, auth, API, web, workers) into one container built by GitHub Actions. Produces the Apps/ folder (docker-compose.yml with x-casaos, README.md with site front matter), the docker/ build folder (Dockerfile, aio-init.sh, run-svc.sh, supervisord.conf, nginx.conf.tpl, on the shared docker/_common helpers with a CREDENTIALS banner) and the build workflow, claims a 61xx port, runs the checker and previews the generated MOS template. Trigger on requests like add an app to IceStore, make an all-in-one or single-container version of an app, port an app to the AppFlowy pattern, bump an app in IceStore, or any edit under Apps/, docker/, platforms/ or build-*.yml in that repo, including making an app work on MOS.
---

# Adding or updating an app in IceStore

IceStore is a GitHub repo (`HSinghHira/IceStore`) that is three things at once:

1. **An app store.** `release-store.yml` runs `IceWhaleTech/build-appstore-action`
   over `Apps/*/docker-compose.yml` and publishes `store.json` (ZimaOS) and
   `store.zip` (CasaOS, ReCasaOS, Homeio) to GitHub Pages at `https://icestore.hsinghhira.me/`.
2. **A website.** The same workflow runs `site/build.py`, which makes one page per
   `Apps/<app>/` folder from its compose file, `README.md`, `icon.png` and
   `screenshot-N.png`.
3. **A MOS Hub repository.** `platforms/generate.py` turns every `Apps/<app>/`
   into a MOS template in the repo root (`docker/<Name>.json` install forms,
   `compose/<Name>/` stacks, `maintainer.json`). MOS users add
   `https://github.com/HSinghHira/IceStore` under MOS Hub Settings.

Every app is written once, for ZimaOS, in `Apps/`. CasaOS, ReCasaOS and Homeio
read the same store, and MOS gets a generated copy, so one app serves all five.

Some apps are **all-in-one (AIO)**: a multi-container upstream (AppFlowy: Postgres,
Redis, MinIO, GoTrue, API, worker, search, web, admin, mail) is rebuilt as one
image with one port and one `/data` folder, pushed to `ghcr.io/hsinghhira/<app>`
by `.github/workflows/build-<app>.yml`. AppFlowy is the reference example.

## Which kind of app?

- **Simple** — upstream is one image that just needs env vars, a port and a
  volume. Only `Apps/<app>/` is needed. Use `templates/docker-compose.simple.yml`.
- **Wrapper** — a simple app that needs a secret unique to each install (an
  encryption key, a session or JWT secret) and doesn't make one itself. The
  image is upstream's plus one start script that makes the secret on first
  start and keeps it in the data folder. Needs `Apps/<app>/`, `docker/<app>/`
  (`Dockerfile`, a start script) and `build-<app>.yml`. Read
  `references/WRAPPER.md`. Pocket ID is the example.
- **All-in-one** — upstream needs two or more containers to work, or the user
  asks for a single-container version. Needs `Apps/<app>/`, `docker/<app>/` and
  `build-<app>.yml`. Read `references/AIO.md` before writing anything.

If unsure, ask the user. Do not turn a simple app into an AIO build.

## Order of operations

1. **Claim a port.** Ports are `6101`–`6199`; AppFlowy has `6101`. An app with
   many ports (more than about 4) gets a block of 30 in `6600`–`6699` instead
   (`ports.py --block`; Ente Garage 6600, Ente MinIO 6630, Ente SeaweedFS 6660). Run
   `scripts/ports.py --repo <checkout>` (or with no `--repo` to download the repo
   from GitHub). It reads every `Apps/*/docker-compose.yml`, so there is no ledger
   file. If it cannot reach the repo, ask the user which ports are taken. Never
   guess. Older apps outside 61xx only show as warnings; leave their ports alone.
   **6101–6199 is full (Nov 2026).** New apps take the next free numbers in
   6690–6799 (Reelsaw 6690, Lemmary 6691, Fluxer 6692–6694, KyIdentity
   6695, ...); `ports.py` falls through to that range by itself and the
   checker accepts it. A port a protocol fixes (DNS on 53, KyDNS) is
   published as itself; it is in `FIXED_PORTS` in both scripts.
2. **Gather upstream facts first**: every image and pinned tag, ports, env vars
   (the full list of settings people can change, from upstream's `.env`
   example, config reference and docs — not just what its compose file sets;
   it becomes the README `variables:` list),
   health endpoints, the upstream `docker-compose.yml` and nginx/reverse-proxy
   config, data paths, whether images are amd64+arm64. Look things up; do not
   recall tags from memory. The repo's own bumper finds the newest tag the
   way the weekly job will (`import update_upstream as u; u.newest(image,
   tag)`, `u.list_tags(image)` from `.github/scripts/`), and the registry API
   gives each image's architectures and `Entrypoint`/`Cmd`/`WorkingDir`/`User`
   without Docker. Also decide here whether the app works with
   `PUBLIC_URL` on localhost (`references/COMPOSE.md` §7): OIDC/OAuth servers
   don't, and need the `[ZIMAOS-IP-ADDRESS]` placeholder.
3. **AIO only: write `docker/<app>/`** from `templates/aio/`, following
   `references/AIO.md`. Copy logic from `examples/appflowy/docker/appflowy/` when
   the templates don't cover something (MinIO/Silo, mail, native binaries, a web
   image with a non-80 port).
4. **AIO only: write `.github/workflows/build-<app>.yml`** from
   `templates/build-workflow.yml`.
5. **Write `Apps/<app>/docker-compose.yml`** per `references/COMPOSE.md`.
6. **Write `Apps/<app>/README.md`** per `references/APP_README.md`, and list the
   images the user must add (`icon.png`, `screenshot-1.png`, ...).
6a. **Update the root `README.md`** (always, for a new app, a renamed app or a
   new icon): from the repo root run
   `python .github/scripts/readme_svgs.py` (needs `pyyaml markdown pillow
   fonttools`). It rewrites the block between the `README-SVGS` markers (app
   count, the "All N apps" list) and redraws `readme/*.svg`. Never edit that
   block by hand. Check `git diff README.md` shows the new app in the list and
   the new count (`references/REPO.md`). A "no ports found" warning is normal
   for host-network apps.
6b. **Roadmap.** `site/roadmap.json` lists planned apps for the site's
   `/roadmap/` page; the page also lists every app in `Apps/` on its own,
   faded and labelled "Live", so never add live apps there. When a planned app
   is added, its entry drops out of the planned list by itself once the
   app's source link (README `source:`, else x-casaos `repo:`) is the same
   GitHub repo as the entry's `url` (case does not matter). If
   the entry's `url` is not that repo (a Docker Hub page, a GitHub org), add
   `"slug": "<Apps folder slug>"` to the entry instead.
6c. **MOS.** Run `just platforms-preview --app <app>` from the repo root and
   read `_platforms/report.md`. Fix anything listed as an error or "not
   carried into the MOS form" that matters. If the app needs something
   different on MOS (a different format, a setting removed, left out with a
   reason), put only that in `platforms/mos/overrides/<app>.yml`
   (`references/REPO.md` § platforms.yml). Never edit the generated
   `compose/`, `docker/*.json` or `maintainer.json`; `just deploy` and the
   `platforms.yml` workflow rewrite them.
7. **Run the checker**: `python3 scripts/check_app.py <repo root> <app>`. Fix every
   ERROR. Read each WARN and fix it or tell the user why it stays. Then go through
   `references/CHECKLIST.md` for what the script cannot see.
8. **Deliver** the files in the repo's own layout (`Apps/<app>/...`,
   `docker/<app>/...`, `.github/workflows/build-<app>.yml`). If the repo is attached
   or on the user's computer, write them there; otherwise zip them in that layout.
   Tell the user which port you used, which images to add, what the MOS report
   said, and what to verify on first install (below).

### Porting an app from the old ZimaAppStore

The user sometimes copies app folders from the old store into `Apps/` (often
untracked, with names like `StoatChat` or `ZimaBrainCE`). Treat each as a new
app built from the old manifest, not as an edit:

- Rename the folder to the app id (lowercase, dashes). On Windows a case-only
  rename needs two steps (`mv X X.tmp; mv X.tmp x`; `git mv` for tracked ones).
- Rename `thumbnail.*`, `thumbnail-1.*`, ... to `screenshot-1.*`,
  `screenshot-2.*`, ... in that order; every image URL changes to IceStore's
  jsdelivr path.
- New id `com.icestore.<app>` (the old store's installs are a different store
  anyway), a new 61xx port, `TZ=$TZ`, `PUID=$PUID`/`PGID=$PGID`.
- Throw away every fixed secret and `CHANGEME` password in the old file; make
  them per install (wrapper, aio-init, or the app's own first-run setup).
- Re-check the old manifest against upstream's current setup. The Stoat one
  had wrong internal ports and a WebRTC port range mapped to other numbers;
  the old ZimaBrain one claimed arm64 for an amd64-only image.
- A multi-container manifest becomes an AIO app; a single image with a
  secret becomes a wrapper (`references/WRAPPER.md`). Never an inline
  shell `entrypoint:`/`command:` script in the compose file (see below).
- Mention every old port and id in `release_notes`.

The folder name is the app's id everywhere: lowercase letters, digits and dashes
(`appflowy`, `immich`, `paperless-ngx`). It is the `Apps/` folder, the `docker/`
folder, the compose `name:`, the main service name, the image name
`ghcr.io/hsinghhira/<app>`, the workflow `build-<app>.yml` and the site URL
`app/<app>/`.

## Non-negotiable rules

- **IceStore names only.** Repo `HSinghHira/IceStore`; images via
  `https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/<app>/<file>`;
  `x-casaos.id: com.icestore.<app>`; Dockerfile
  `org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"`.
  Never write `ZimaAppStore` or `com.hiraappstore` in a new app. An existing app
  keeps its old `x-casaos.id` if people have already installed it — changing the
  id makes the store treat it as a different app.
- **No shell scripts or shell variables in `docker-compose.yml`.** ZimaOS
  replaces `$` in the compose file twice, so `$$f` reaches the shell as an
  empty string (Disk Monitor's first version failed with
  `can't create .tmp: Read-only file system` / `cannot write ` this way).
  Only ZimaOS's own `$TZ`, `$PUID`, `$PGID` and `$AppID` may appear. Any
  start-up logic (secrets, passwords, a changed port) goes in a wrapper image
  (`references/WRAPPER.md`). Older apps with inline `entrypoint:` scripts
  (vscode, vscodium, ntfy, claudecode, omniroute, opengym) are suspect.
- **No `#` comments in `docker-compose.yml`.** Explanations go in x-casaos fields
  (`references/COMPOSE.md`). Shell, Dockerfile, nginx and supervisord files may
  and should have comments.
- **Every variable in `x-casaos.envs` must also be in `environment:`.** ZimaOS
  only shows the variables in `environment:`; a described-but-missing variable
  can't be set. (This bug was in the first AppFlowy manifest.)
- **Short compose, full list in the README.** `environment:` holds only what
  is needed to start (`TZ`, `PUBLIC_URL`, admin email/password). Every other
  setting a person might change — sign-up, email/SMTP, sign-in providers,
  feature switches, API keys, log level — goes in the README front matter
  `variables:` list, which the site shows in the Variables tab. People add
  those in the ZimaOS app settings. `aio-init.sh` must read every one, with
  missing or blank meaning "use the default" (`references/COMPOSE.md` §8,
  `references/APP_README.md`, `references/AIO.md` §3.5).
- **Every install gets its own secrets.** A secret in the compose file is the
  same for everyone who installs the app, so no compose file ships one. AIO
  apps make them in `aio-init.sh` (`/data/state/secrets.env`); a simple app
  whose secret must be unique and that doesn't make one itself becomes a
  wrapper image (`references/WRAPPER.md`). Only an app that makes the secret
  itself when it's missing may leave it out entirely.
- **One number, four places.** The app's 61xx port is the published port,
  `x-casaos.port_map`, the port in the `PUBLIC_URL` default in the compose file,
  and the port in the `PUBLIC_URL` default in `aio-init.sh`. The container port of
  an AIO app is always `8080`.
- **Addresses people must type use one placeholder:** `http://[ZIMAOS-IP-ADDRESS]:<port>`,
  in the compose default (only when the app can't work on localhost), the
  envs descriptions, the tips, the description and the README
  (`references/COMPOSE.md` §5 and §7). When it is required, the tips and the
  README's "Before you install" say so first and plainly, and aio-init shows
  a "set PUBLIC_URL to ..." page instead of redirecting browsers to localhost
  (`references/AIO.md` §3.5). Prefer making the app follow the browser's
  address when it can (`references/AIO.md` §3.7).
- **Apps upstream says need a domain and HTTPS** (Fluxer, Stoat: Caddy edge
  with Let's Encrypt, `FLUXER_DOMAIN`): don't bundle a TLS server. Replace the
  edge with the nginx gateway, ship `PUBLIC_URL=http://[ZIMAOS-IP-ADDRESS]:<port>`
  with the guard page, derive every scheme/host/port/origin variable from
  PUBLIC_URL in aio-init, and tell people plainly (tips, README, envs, logs)
  what works over plain http and that for the rest they point a reverse proxy
  or tunnel with their domain at the port and set `PUBLIC_URL=https://chat.example.com`.
  Fluxer (`docker/fluxer`) is the example. Apps that cannot run at all
  without it, or need Docker itself (Openship), stay on the roadmap.
- **Upstream pins images by digest only** (Fluxer's release compose): find the
  version tag with the same digest (registry API, `update_upstream.digest`)
  and pin that tag, so the bumper can follow it.
- **More patterns (Nov 2026 batch; copy the named app):**
  - *No published image*: build from the release tarball in a wrapper-kind
    image (one `FROM`, `ADD .../archive/refs/tags/<tag>.tar.gz`, supervisord
    for several processes, a DB from apt). Select, Kith, Kestello, Root
    Cellar. `x-casaos.version` = the release tag; the checker's "not the tag
    of any FROM" warning is expected there.
  - *Upstream image has no shell* (distroless, chiseled): add
    `COPY --from=busybox:<x.y.z>-musl /bin/busybox /bin/busybox` and
    `RUN ["/bin/busybox","--install","-s",...]` (byagent, Trackhop); a COPY
    is not a second FROM, so the wrapper check still passes.
  - *App forces the Secure cookie flag*: when PUBLIC_URL is http, aio-init
    puts `proxy_cookie_flags ~ nosecure;` in the nginx location (AsoBeast).
  - *First admin*: put the setup token / bootstrap secret / a signup key in
    the CREDENTIALS banner (Fluxer, Gami.Fied, Inkling inserts a hashed
    signup key once its tables exist, Kith runs `setup db` with a made
    password). Apps that write the first password to a file: tell people the
    Files app path (KyIdentity, KyRecovery).
  - *Bind-mount ownership*: images running as a fixed non-root user can't
    write the root-owned folder ZimaOS makes; use `user: "0:0"` unless the
    image's entrypoint chowns it (KyRecovery does).
  - *Alpine base*: BusyBox has no `sed -u` (run-svc log prefixes) and
    `exec` can't run a shell function (`exec as_x ...` exits 127): `apk add
    sed setpriv` and `exec setpriv ...` directly (OpenSignup).
  - *A fixed image after a broken first release*: ZimaOS keeps the old
    `:latest` after uninstall and reinstalls from it. Pin the compose image
    to the AIO_VERSION (`ghcr.io/hsinghhira/<app>:1.0.1`); the weekly
    bumper moves that pin with AIO_VERSION (OpenSignup).
  - *NEXT_PUBLIC_* baked at build*: build with placeholder words, fill them
    in on start from a pristine copy of `.next` (OpenSignup's fill-public.mjs).
  - PHP 8.5 images have opcache built in: never `docker-php-ext-install opcache`.
  - SVG-only icons: render with headless Edge on Windows
    (`msedge --headless=new --default-background-color=00000000
    --window-size=512,512 --screenshot=icon.png page.html`).
  - The tips checker reads "…:6710. " or "…1.20. " as a step number: don't
    end a sentence with a port or an IP in `tips.before_install`.
- **One source for every OS.** Write the app only in `Apps/` (and `docker/<app>/`
  for builds). The MOS generator relies on `x-casaos.main` and `port_map` naming
  the web port, data under `/DATA/AppData/$AppID`, `$TZ`/`$PUID`/`$PGID`, and
  `[ZIMAOS-IP-ADDRESS]` for the server address; it maps each to MOS. Breaking
  those conventions breaks the MOS template too. MOS-only differences go in
  `platforms/mos/overrides/<app>.yml`, never in `Apps/`.
- **Pin every upstream tag** in the Dockerfile `FROM ... AS img-<name>` lines.
- **AIO apps are kept current by `update-upstream.yml`** every Monday: it bumps
  the FROM tags, `AIO_VERSION`, `version`, `update_at` and `release_notes`, then
  starts the build. Write a new AIO app in the shapes it reads (`REPO.md`
  § update-upstream.yml) and don't tell the user to bump versions by hand. A
  new app needs no change to the workflow.
- **Write `tips.before_install` for a 4th grader**: short steps, everyday words,
  a blank line between steps.
- **Validate before calling it done**: the checker, plus `bash -n` on shell files
  (the checker does this), plus a dry run of `aio-init.sh` (`references/AIO.md`
  shows how).

## Tell the user to verify on first install

- The GitHub Action `Build <app>` finished and the package
  `ghcr.io/hsinghhira/<app>` is **public**. A new GHCR package can start out
  private, and ZimaOS can't pull a private image. Check it once in the package's
  settings on GitHub.
- The store release ran after the image existed. Both workflows run on the same
  push, so a brand-new app may appear in the store a few minutes before its
  image is pullable.
- MOS: after the push, the `platforms.yml` run is green and the app shows in
  MOS Hub after **Refresh** (amd64-only apps are hidden on ARM machines).
- The log shows every service started and the healthcheck turns healthy within
  `start_period`.

## Files in this skill

- `references/REPO.md` — the IceStore tree, the workflows, what the site reads,
  and the MOS generator (`platforms/README.md` in the repo has the full rules).
- `references/COMPOSE.md` — compose and x-casaos rules, variables, secrets, tips.
- `references/AIO.md` — how the all-in-one image works and how to port a new app.
- `references/WRAPPER.md` — upstream image + a start script for per-install secrets.
- `references/APP_README.md` — per-app README front matter, sections and images.
- `references/CHECKLIST.md` — the final human check.
- `templates/` — compose (simple and AIO), README, workflow, and `aio/` skeletons.
  Placeholders look like `__NAME__`; the checker fails while any are left.
- `examples/appflowy/` — the complete, working AppFlowy app in repo layout.
- `scripts/ports.py`, `scripts/check_app.py` — need Python 3 and `pyyaml`
  (`pip install pyyaml --break-system-packages`).
