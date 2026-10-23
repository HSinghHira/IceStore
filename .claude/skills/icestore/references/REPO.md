# REPO.md — the IceStore repo

```
.github/workflows/
  build-<app>.yml        one per all-in-one app: builds docker/<app>/ and pushes ghcr.io/hsinghhira/<app>
  release-store.yml      builds the store and the website on every push to main
  update-upstream.yml    weekly: bumps the FROM tags of every AIO app, then starts its build
.github/scripts/
  update_upstream.py     the bumper that update-upstream.yml runs (dry run without --write)
Apps/<app>/
  docker-compose.yml     the store manifest (x-casaos)
  README.md              the app page's Introduction tab (+ front matter)
  icon.png               app icon (store and site)
  screenshot-1.png ...   screenshots for the site slider, in number order
docker/<app>/            all-in-one apps only: the image's build context
  Dockerfile  aio-init.sh  run-svc.sh  capture-meta.sh  supervisord.conf  nginx.conf.tpl  .gitignore
site/
  build.py  requirements.txt  site.json  static/  templates/
store-config.json        store id com.icestore, name, maintainer, url
supported-languages.json ["en_US"] — write every x-casaos text as en_US only
justfile                 `just check` runs the checker on every app; `just deploy ["message"]`
                         (alias `just d`) = check, then git add -A, commit, push
.gitattributes           forces LF line endings on shell, Dockerfile, nginx and compose files
README.md                how to add the store on each OS + a hand-written app table
```

The root `README.md` has an `## 📦 Apps` table, one row per app in
alphabetical order, written by hand. Add a row for a new app (copy an existing
row: icon, image badge, project badge, port badge(s), one-line description,
screenshot-1) and update the badges when the image tag or port changes. There
is no port ledger file: `scripts/ports.py` reads the ports from the compose files.

## release-store.yml

Runs on every push to `main`:

1. `IceWhaleTech/build-appstore-action` over the whole repo → `dist/store.json`.
   Fails the run if an app has no `x-casaos.id`.
2. `zip -r dist/store.zip .` minus `.git`, `.github`, `.claude`, `.history`,
   `dist`, `_site`, `site`, `docker` and `justfile`, so only the store files ship.
   A new top-level folder that isn't part of the store must be added to that
   exclude list too.
3. `python site/build.py --out dist --no-clean` adds the website to the same folder.
4. Deploys `dist/` to GitHub Pages. Base URL comes from `site/site.json`
   (`https://icestore.hsinghhira.me/`).

`site/build.py` stops the whole release (exit 1) if any app folder has no
`docker-compose.yml`, no services, or a main service without `image:`. Missing
README, icon or screenshots are only warnings.

## build-<app>.yml

Runs when `docker/<app>/**` (or the workflow itself) changes, or by hand:

1. `bash capture-meta.sh` in `docker/<app>` — pulls each upstream image and
   saves its config to `meta/<name>.json` (that's why `meta/` is git-ignored).
2. QEMU + Buildx, log in to GHCR with `GITHUB_TOKEN`.
3. Build `linux/amd64,linux/arm64`, push `:<AIO_VERSION>` and `:latest`.
   `AIO_VERSION` is the env at the top of the workflow — this image's own version,
   separate from the upstream version in `x-casaos.version`.

Bump `AIO_VERSION` whenever the image changes (new upstream tag, script fix).
Cache uses `scope=<app>` so apps don't evict each other's build cache.
Keep `workflow_dispatch:` — update-upstream.yml starts the build with it.

## update-upstream.yml

Runs every Monday 03:00 UTC, or by hand. It finds every `docker/*/Dockerfile`
by itself, so a new AIO app needs no change here — only the shapes below.

1. `python .github/scripts/update_upstream.py --write`. For each
   `FROM <image>:<tag>` line it lists the registry's tags (Docker Hub, GHCR or
   any v2 registry, anonymously) and takes the newest tag **of the same shape**:
   the tag with its digit runs replaced by `\d+` must match (`0.19.2` →
   `0.19.10`, `v1.31.4` → `v1.32.0`, `RELEASE.2026-09-16T00-00-00Z` → a later
   date). Betas, `latest` and digit-less tags (`debian:trixie-slim`) are skipped.
   A `# auto-update: hold` comment on the line above a FROM freezes it.
   Images that only publish `latest` plus one tag per git commit (`ghcr.io/ente/*`)
   are pinned to a 40-character commit tag; those follow `latest` (the line moves
   to the commit tag with `latest`'s digest), and `x-casaos.version` may be the
   first 7 characters of the main image's commit tag.
2. For each app that changed it also: raises the patch of `AIO_VERSION` in
   `build-<app>.yml`; in the compose, sets `version:` if the FROM whose tag
   equalled it moved, sets `update_at:` to today, puts
   `- Updated <name> <old> to <new>, ...` first under `release_notes.en_US: |-`,
   and rewrites every `<image> <old>` / `<basename> <old>` mention to the new tag.
3. Commits as github-actions[bot], pushes to main, then `gh workflow run
   build-<app>.yml` for each changed app and `release-store.yml` (a
   GITHUB_TOKEN push does not trigger workflows on its own).

So for the bumper to keep an AIO app current, the app must have:
- pinned, numeric FROM tags in the exact `FROM <image>:<tag> AS img-<svc>` form;
- `x-casaos.version` equal to the main image's FROM tag, character for character;
- `release_notes:` written as `en_US: |-` followed by `      - ` bullets, with the
  image list as `<basename> <tag>` (AppFlowy) or `<image> <tag>` (AFFiNE);
- `AIO_VERSION: "x.y.z"` and `workflow_dispatch:` in `build-<app>.yml`.

`check_app.py` warns when one of these is off. Simple apps (upstream image in
the compose, no `docker/<app>/`) are not touched: with `:latest` ZimaOS sees
new digests on its own; a pinned tag is bumped by hand.

Besides one page per app and the homepage, `build.py` writes `404.html`
(GitHub Pages serves it for any missing path, so all its links are absolute),
`app/index.html` (sends `/app/` to the homepage) and `CNAME` (the custom
domain from `site.json` `base_url`, currently `https://icestore.hsinghhira.me/`).

## What site/build.py reads from Apps/<app>/

| Source | Used for |
|---|---|
| folder name | page URL `app/<folder>/` (lower-cased) |
| `x-casaos.title` / `tagline` / `category` | name, subtitle, category chip (README front matter can override) |
| `x-casaos.main` service `image` | the image:tag chip |
| main service published ports | port chips; the first one builds the service links `http://localhost:<port><path>` |
| main service `environment:` + `x-casaos.envs` | the Variables tab (values of password/secret/token/key variables are shown as `change-me` unless they start with `$`) |
| `x-casaos.repo` | "View source" (front matter `source` overrides) |
| `README.md` body | the Introduction tab; the first `# Title` line is dropped |
| `README.md` front matter | see `APP_README.md` |
| `README.md` front matter `variables:` | the Variables tab, after the compose variables, one heading per `group` (defaults are shown as written, not redacted) |
| `icon.*`, `screenshot*.*` | icon and slider (png, webp, jpg, jpeg, gif, svg) |
| `x-casaos.index` | default service path when front matter has no `services` |
| whole compose file | the Docker Compose tab (secrets redacted) |

Category → schema.org type mapping in `build.py` knows `productivity`,
`finance`, `media`, `developer`, `social`, `home automation`, `network`... Anything
else is `UtilitiesApplication`. That's only SEO; use the fixed category list in
`COMPOSE.md`.
