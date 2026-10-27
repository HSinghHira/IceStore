---
name: advanced-zimaos-app-creator
description: Use when adding or updating an app in IceStore (the HSinghHira/IceStore GitHub repo), the community app store for ZimaOS, CasaOS and Homeio, especially an all-in-one app that bundles several upstream images (database, auth, API, web, workers) into one container built by GitHub Actions. Produces the Apps/ folder (docker-compose.yml with x-casaos, README.md with site front matter), the docker/ build folder (Dockerfile, aio-init.sh, run-svc.sh, capture-meta.sh, supervisord.conf, nginx.conf.tpl) and the build workflow, claims a 61xx port, and runs the checker. Trigger on requests like add an app to IceStore, make an all-in-one or single-container version of an app, port an app to the AppFlowy pattern, bump an app in IceStore, or any edit under Apps/, docker/ or build-*.yml in that repo.
---

# Adding or updating an app in IceStore

IceStore is a GitHub repo (`HSinghHira/IceStore`) that is two things at once:

1. **An app store.** `release-store.yml` runs `IceWhaleTech/build-appstore-action`
   over `Apps/*/docker-compose.yml` and publishes `store.json` (ZimaOS) and
   `store.zip` (CasaOS, Homeio) to GitHub Pages at `https://icestore.hsinghhira.me/`.
2. **A website.** The same workflow runs `site/build.py`, which makes one page per
   `Apps/<app>/` folder from its compose file, `README.md`, `icon.png` and
   `screenshot-N.png`.

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

1. **Claim a port.** Ports are `6101`–`6199`; AppFlowy has `6101`. Run
   `scripts/ports.py --repo <checkout>` (or with no `--repo` to download the repo
   from GitHub). It reads every `Apps/*/docker-compose.yml`, so there is no ledger
   file. If it cannot reach the repo, ask the user which ports are taken. Never
   guess. Older apps outside 61xx only show as warnings; leave their ports alone.
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
7. **Run the checker**: `python3 scripts/check_app.py <repo root> <app>`. Fix every
   ERROR. Read each WARN and fix it or tell the user why it stays. Then go through
   `references/CHECKLIST.md` for what the script cannot see.
8. **Deliver** the files in the repo's own layout (`Apps/<app>/...`,
   `docker/<app>/...`, `.github/workflows/build-<app>.yml`). If the repo is attached
   or on the user's computer, write them there; otherwise zip them in that layout.
   Tell the user which port you used, which images to add, and what to verify on
   first install (below).

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
  secret becomes a wrapper (or an inline `entrypoint:` like `Apps/vscode`
  for linuxserver images that read the secret from an env var).
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
- The log shows every service started and the healthcheck turns healthy within
  `start_period`.

## Files in this skill

- `references/REPO.md` — the IceStore tree, both workflows, what the site reads.
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
