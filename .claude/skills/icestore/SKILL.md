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
   recall tags from memory.
3. **AIO only: write `docker/<app>/`** from `templates/aio/`, following
   `references/AIO.md`. Copy logic from `examples/appflowy/docker/appflowy/` when
   the templates don't cover something (MinIO/Silo, mail, native binaries, a web
   image with a non-80 port).
4. **AIO only: write `.github/workflows/build-<app>.yml`** from
   `templates/build-workflow.yml`.
5. **Write `Apps/<app>/docker-compose.yml`** per `references/COMPOSE.md`.
6. **Write `Apps/<app>/README.md`** per `references/APP_README.md`, and list the
   images the user must add (`icon.png`, `screenshot-1.png`, ...).
7. **Run the checker**: `python3 scripts/check_app.py <repo root> <app>`. Fix every
   ERROR. Read each WARN and fix it or tell the user why it stays. Then go through
   `references/CHECKLIST.md` for what the script cannot see.
8. **Deliver** the files in the repo's own layout (`Apps/<app>/...`,
   `docker/<app>/...`, `.github/workflows/build-<app>.yml`). If the repo is attached
   or on the user's computer, write them there; otherwise zip them in that layout.
   Tell the user which port you used, which images to add, and what to verify on
   first install (below).

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
- **AIO apps ship no secrets in the compose file.** `aio-init.sh` makes them on
  first start and keeps them in `/data/state/secrets.env`.
- **One number, four places.** The app's 61xx port is the published port,
  `x-casaos.port_map`, the port in the `PUBLIC_URL` default in the compose file,
  and the port in the `PUBLIC_URL` default in `aio-init.sh`. The container port of
  an AIO app is always `8080`.
- **Pin every upstream tag** in the Dockerfile `FROM ... AS img-<name>` lines.
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
- `references/APP_README.md` — per-app README front matter, sections and images.
- `references/CHECKLIST.md` — the final human check.
- `templates/` — compose (simple and AIO), README, workflow, and `aio/` skeletons.
  Placeholders look like `__NAME__`; the checker fails while any are left.
- `examples/appflowy/` — the complete, working AppFlowy app in repo layout.
- `scripts/ports.py`, `scripts/check_app.py` — need Python 3 and `pyyaml`
  (`pip install pyyaml --break-system-packages`).
