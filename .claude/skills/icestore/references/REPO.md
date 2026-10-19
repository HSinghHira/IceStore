# REPO.md — the IceStore repo

```
.github/workflows/
  build-<app>.yml        one per all-in-one app: builds docker/<app>/ and pushes ghcr.io/hsinghhira/<app>
  release-store.yml      builds the store and the website on every push to main
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
justfile                 `just deploy` / `just d` = git add -A, commit "Building", push
README.md                two-line description of the store (no app table)
```

There is no app table in the root `README.md` and no port ledger file. The site
lists apps, and `scripts/ports.py` reads the ports from the compose files.

## release-store.yml

Runs on every push to `main`:

1. `IceWhaleTech/build-appstore-action` over the whole repo → `dist/store.json`.
   Fails the run if an app has no `x-casaos.id`.
2. `zip -r dist/store.zip .` minus `.git`, `.github`, `dist`, `_site`, `site`.
   Note that `docker/` **is** inside `store.zip`; that is harmless.
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
