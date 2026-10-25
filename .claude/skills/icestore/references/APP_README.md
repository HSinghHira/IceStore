# APP_README.md — Apps/<app>/README.md and images

The README is the app page's **Introduction** tab on the IceStore website
(`site/build.py`). It is not shown inside ZimaOS — the store uses
`x-casaos.description` there — so keep the two saying the same things.
Start from `templates/README.md`; `examples/appflowy/Apps/appflowy/README.md` is
a finished one.

## Front matter

All keys are optional. `build.py` reads only these:

```yaml
---
name: AppFlowy            # overrides x-casaos.title
tagline: ...              # overrides x-casaos.tagline
category: Productivity    # overrides x-casaos.category
site: https://appflowy.com            # "Visit project site" button
source: https://github.com/...        # "View source" button (default: x-casaos.repo)
services:                              # cards under App details
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Console, path: /console, icon: server }
  - { name: Mail Viewer, path: /mail, icon: mail }
screenshots: [Home, Editor, Board]     # captions, in screenshot order
variables:                             # the full list of optional settings (below)
  - name: GOTRUE_DISABLE_SIGNUP
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so only people you invite can join.
---
```

Normally only `site`, `services`, `screenshots` and `variables` are needed;
the rest comes from the compose file.

`variables`: every optional setting a person might change (`COMPOSE.md` §8
says which). The site shows them in the **Variables** tab after the compose
variables, one heading per `group`, with a note that they are added in the app
settings. Each item:

| Key | Required | Notes |
|---|---|---|
| `name` | yes | the variable name; not also in the compose file |
| `group` | recommended | heading in the table; items with the same group are shown together, in file order |
| `default` | yes | the value used when it is left out: a real value, quoted (`"465"`, `"true"`), or `""` |
| `description` | yes | one or two plain sentences, `>-` folded |

`services`: one card per URL a person opens in a browser. Each card shows
`http://localhost:<first published port><path>`. `path` starts with `/`.
Add `port: <published port>` for a URL on another published port (Ente's API
on its second port: `{ name: API, path: /, icon: server, port: 6130 }`).
`icon` must be one of the names in `build.py`'s `ICONS`, or the site falls back
to `globe` with a warning:

`globe`, `server`, `mail`, `monitor`, `table`, `code`, `file-code`, `package`,
`plug`, `tag`, `search`, `info`, `grid`, `github`, `external-link`, `copy`,
`check`, `plus`, `plus-circle`, `issues`, `arrow-left`, `arrow-right`

Without `services`, the site shows one "Web UI" card at `x-casaos.index`.

## Body

```markdown
# <App Name>                  ← dropped by the site (the page has its own title); keep it for GitHub

<pitch, same as x-casaos.description's first paragraph>

## Features
- ...                         (same bullets as the store description)

## How to use
1. ...                        (same steps, "your dashboard" instead of "Zima OS dashboard",
                               since the page also serves CasaOS and Homeio)

## Before you install
<one short paragraph: which variables to set, where a generated password appears,
how to use it from other devices, that more settings are in the Variables tab and
are added in the app settings, how long first start takes>
```

When the app needs a real address (`COMPOSE.md` §7), "Before you install"
starts with it in bold: "**You must set `PUBLIC_URL` first.** It starts as
`http://[ZIMAOS-IP-ADDRESS]:6164`: replace `[ZIMAOS-IP-ADDRESS]` with your
ZimaOS IP, like `http://192.168.1.20:6164`." Write every address people type
as `http://[ZIMAOS-IP-ADDRESS]:<port>/path`, here and in the steps.

Normal markdown with single newlines is fine here (it is not inside YAML).
Write it plainly, like the tips.

## Images

| File | Needed | Notes |
|---|---|---|
| `icon.png` | yes | square, at least 256×256, transparent background if possible; also used by the store via jsdelivr |
| `screenshot-1.png`, `-2`, ... | strongly recommended | sorted by number; 16:10 or 16:9 desktop screenshots of the real app; the first one is the social preview image |

png, webp, jpg, jpeg, gif and svg all work. Download them from upstream's repo or
site into `Apps/<app>/` — never hotlink. If you can't fetch them, tell the user
exactly which files to add; never commit a placeholder image.
