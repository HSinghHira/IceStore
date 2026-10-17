# IceStore

3rd-Party Community AppStore for Zima OS, Casa OS and Homeio.

This repository holds the apps and the website that lists them. The website is generated from the `apps/` folder by a script and published with GitHub Pages. Adding an app is a matter of adding a folder.

## Layout

```
IceStore/
├── apps/
│   └── appflowy/
│       ├── docker-compose.yml     required
│       ├── README.md              optional, becomes the Introduction tab
│       ├── icon.png               optional, falls back to a letter tile
│       └── screenshot-1.png       optional, screenshot-2.png, screenshot-3.png ...
├── site/
│   ├── build.py                   scans apps/ and writes the site into _site/
│   ├── site.json                  site name, tagline, links, store URL
│   ├── requirements.txt
│   └── templates/
│       ├── index.html             home page
│       └── app.html               one app page
├── .github/workflows/deploy-site.yml
└── store.json                     copied to the site if present
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

Values of variables whose names contain `password`, `secret`, `token` or `key` are replaced with `change-me` on the site, in both the Variables table and the Docker Compose tab. The compose file in `apps/` is not changed.

## Build locally

```bash
pip install -r site/requirements.txt
python site/build.py
python -m http.server -d _site
```

Open http://localhost:8000. The build prints a warning for a missing icon or screenshots, and stops with an error if an app has no `docker-compose.yml` or no image.

## Publish with GitHub Pages

1. In the repository, open **Settings → Pages** and set **Source** to **GitHub Actions**.
2. Push to `main`. The **Deploy site** workflow runs when `apps/**`, `site/**` or `store.json` change. You can also run it by hand from the **Actions** tab.
3. The site appears at `https://<user>.github.io/<repo>/`. All links are relative, so it also works on a custom domain.

A repository can only deploy one Pages site. If another workflow already deploys Pages, merge the two.

## Settings

Edit `site/site.json` to change the site name, tagline, repository link, author, or the store URL shown in the ZimaOS, CasaOS and Homeio tabs.
