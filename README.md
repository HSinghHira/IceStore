# IceStore

3rd-Party Community AppStore for Zima OS, Casa OS and Homeio.

This repository holds the apps and the website that lists them. The website is generated from the `Apps/` folder by a script and published with GitHub Pages. Adding an app is a matter of adding a folder.

## Layout

```
IceStore/
├── Apps/
│   └── appflowy/
│       ├── docker-compose.yml     required
│       ├── README.md              optional, becomes the Introduction tab
│       ├── icon.png               optional, falls back to a letter tile
│       └── screenshot-1.png       optional, screenshot-2.png, screenshot-3.png ...
├── site/
│   ├── build.py                   scans Apps/ and writes the site into _site/
│   ├── site.json                  site name, tagline, links, base URL
│   ├── requirements.txt
│   └── templates/
│       ├── index.html             home page
│       └── app.html               one app page
├── .github/workflows/release-store.yml
├── store-config.json              store identity, read by the store build
└── supported-languages.json
```

## What the build reads from an app folder

| File | Used for |
| --- | --- |
| `docker-compose.yml` | Name, tagline and category from the top-level `x-casaos` block. Image, version and port from the main service. The Variables table from `environment`, with descriptions from the service's `x-casaos.envs`. The Docker Compose tab shows the file itself. |
| `README.md` | The Introduction tab. The first `# Title` line is dropped because the page already shows the name. |
| `icon.*` | App icon on the home page, the scrolling rows and the app page. |
| `screenshot-*.*` | The slider, in number order. With none, the slider is hidden. |

The main service is the one named in `x-casaos.main`, or the first service in the file.

### Optional front matter

Some details cannot be read from a compose file. Add them at the top of the app's `README.md`:

```yaml
---
site: https://appflowy.com        # "Visit project site" button (defaults to x-casaos repo)
source: https://github.com/...    # "View source" button (defaults to x-casaos repo)
category: Productivity            # defaults to x-casaos category
services:                         # the App details cards (defaults to one Web UI card)
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Console, path: /console, icon: server }
  - { name: Mail Viewer, path: /mail, icon: mail }
---
```

Available service icons are `globe`, `server`, `mail` and `monitor`. The URL on each card is `http://localhost:<port><path>`, using the app's published port.

### Secrets

Values of variables whose names contain `password`, `secret`, `token` or `key` are replaced with `change-me` on the site, in both the Variables table and the Docker Compose tab. The compose file in `Apps/` is not changed.

## Build locally

```bash
pip install -r site/requirements.txt
python site/build.py
python -m http.server -d _site
```

Open http://localhost:8000. The build prints a warning for a missing icon or screenshots, and stops with an error if an app has no `docker-compose.yml` or no image.

## Store links

Each OS gets its own short link, all under the base URL in `site/site.json`:

| OS | Link | What it serves |
| --- | --- | --- |
| Zima OS | https://git.hsinghhira.me/IceStore/ZimaOS | a copy of `store.json` |
| Casa OS | https://git.hsinghhira.me/IceStore/CasaOS | a copy of `latest.zip` |
| Homeio | https://git.hsinghhira.me/IceStore/Homeio | a copy of `latest.zip` |

The website shows these links in its three tabs. To move the store to another address, change `base_url` in `site/site.json`. The tabs, the terminal commands and the store bundle all follow it.

## Publish with GitHub Pages

The **Build and publish app store** workflow (`release-store.yml`) does everything on each push to `main`:

1. Builds the store bundle with `IceWhaleTech/build-appstore-action` into `dist/`.
2. Adds `latest.zip`, then the `ZimaOS`, `CasaOS` and `Homeio` link files.
3. Runs `site/build.py --out dist --no-clean`, which adds the website to the same folder.
4. Deploys `dist/` to GitHub Pages.

Setup:

1. Open **Settings → Pages** and set **Source** to **GitHub Actions**.
2. Make sure the custom domain `git.hsinghhira.me` is set on your account's Pages, so this project is served under `/IceStore/`.
3. Push to `main`, or run the workflow from the **Actions** tab.

This replaces the old workflow that pushed to a `gh-pages` branch. A repository can only deploy one Pages site, so remove any other Pages workflow.

## Settings

Edit `site/site.json` to change the site name, tagline, repository link, author, or the base URL for the store links.
