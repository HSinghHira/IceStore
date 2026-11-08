---
name: roadmap
description: Use when the user types /roadmap or asks to add apps to the IceStore roadmap. Reads the links in .task/apps-to-release.md, checks each one can become an IceStore app (self-hosted, runs in Docker on a home server), adds the ones that can to site/roadmap.json with an icon in site/static/img/roadmap/, removes those links from the task file and leaves the rest with a short reason.
---

# /roadmap: move apps from the task file to the roadmap

The roadmap page (`/roadmap/` on the site) is built by `site/build.py`
(`roadmap_page`) from `site/roadmap.json`. Planned apps show first; every app
already in `Apps/` shows after them, faded, as "Live". An entry drops off the
planned list on its own once an app in `Apps/` has the same GitHub repo as its
source link (README `source:`, else x-casaos `repo:`), or the same `slug`.

Input: `.task/apps-to-release.md` (gitignored), one link per line, blank lines
between. Links can be GitHub repos, GitHub orgs, Docker Hub pages or project
websites.

## Steps

1. **Read the task file.** Collect every link. Lines that already end in
   `— skipped: ...` were checked on an earlier run: leave them alone unless the
   user asks to look again.

2. **Drop links that are already handled.** A link is handled when:
   - `site/roadmap.json` has an entry with the same `url` (case does not
     matter), or the same GitHub `owner/repo`; or
   - an app in `Apps/` has that repo as its source (grep `source:` in
     `Apps/*/README.md` and `repo:` in `Apps/*/docker-compose.yml`).
   These count as added: remove them from the task file in step 6.

3. **Check each new link can be an IceStore app.** For a GitHub repo, read the
   README and look at the files (`gh api repos/<owner>/<repo>`,
   `gh api repos/<owner>/<repo>/readme -H "Accept: application/vnd.github.raw"`,
   `gh api repos/<owner>/<repo>/contents`). For other links, fetch the page.

   **Add it** when all of these hold:
   - It is a server or web app a person runs for themselves (has a web UI or an
     API other apps use, like Byparr or FlareSolverr).
   - It can run in Docker: a published image, a Dockerfile, or a compose file.
     No image yet is fine if a Dockerfile exists (IceStore can build it).
   - It runs on a normal x86-64 or arm64 home server. Needing `/dev/kvm`, a
     GPU or extra RAM is fine; say so in the report.
   - The code is available to self-host (open source or source-available with
     a free self-host tier).
   - The repo is not abandoned (a commit or release in the last ~12 months) or
     the app is finished and still works.

   **Skip it** when it is:
   - a desktop-only, mobile-only or browser-extension app;
   - a library, SDK, CLI tool or framework with no server to run;
   - SaaS only, or the self-host version is paid only;
   - archived, a dead repo, or an empty / placeholder repo;
   - something that cannot run in a container (needs a full OS install, a
     kernel module, Windows host).

   When unsure, ask the user in one question listing the unsure apps, rather
   than guessing.

4. **Write the entry** for each app to add, appended to the end of
   `site/roadmap.json` (keep one entry per line, same key order as the
   existing ones):

   ```json
   {"name": "Tolgee", "category": "Developer", "desc": "Developer and translator friendly web-based localization platform.", "url": "https://github.com/tolgee/tolgee-platform", "icon": "tolgee.svg"},
   ```

   - `name`: the app's own name and capitals.
   - `category`: one short word. Prefer ones already used: Productivity, Media,
     Networking, Developer, AI, Home, Social, Finance, Utilities, Music, Video,
     Chat, Analytics, Documents, Business.
   - `desc`: one plain sentence, under ~100 characters, saying what it does.
     No marketing words ("blazing", "powerful", "ultimate"), no emoji.
   - `url`: the GitHub repo if there is one, else the link as given.
   - `icon`: a file name in `site/static/img/roadmap/`, named after the app
     (lowercase, no spaces), `.png` or `.svg`.
   - `slug`: only when `url` is not the app's GitHub repo (a Docker Hub page,
     a GitHub org, a website). Set it to the folder name the app will get in
     `Apps/`, so the entry drops off once the app is live.

   Check the file still parses: `python -c "import json;json.load(open('site/roadmap.json',encoding='utf-8'))"`.

5. **Get the icon** into `site/static/img/roadmap/<name>.png|svg`. Try in order:
   1. a logo in the repo (`logo`, `icon`, `favicon`, `apple-touch-icon` under
      `public/`, `assets/`, `docs/`, `static/`, `.github/`); find it with
      `gh api "repos/<owner>/<repo>/git/trees/HEAD?recursive=1" --jq '.tree[].path' | grep -iE 'logo|icon|favicon'`;
   2. the project website's `apple-touch-icon` or favicon;
   3. the owner's GitHub avatar, `https://github.com/<owner>.png?size=512`
      (good when the owner is an org named after the app).
   Pick a square image, 180 px or larger. A PNG bigger than 512 px: shrink it
   to 512 x 512 with Pillow. Download each one into its own new folder in the
   scratchpad first, open it with Read to check it is the right logo, then
   copy it in. Never leave out `icon`: the tile falls back to a letter, which
   looks broken next to the others.
   To check many at once, write an HTML grid of the files and screenshot it
   with headless Edge (`msedge --headless --screenshot=<png> --window-size=1200,900 file:///<html>`),
   then Read the PNG. The roadmap page is **dark**: a thin black logo, or an
   SVG that switches colour with `prefers-color-scheme`, disappears. Use a
   PNG version, or wrap the SVG on a light rounded `<rect>`. Never use a
   person's photo avatar; a wordmark logo can be cropped to its symbol.

6. **Update the task file.**
   - Remove every link that is now on the roadmap (added this run or already
     there from step 2).
   - Keep each skipped link and add the reason after it, so the next run does
     not check it again:
     `https://github.com/x/y — skipped: desktop app only`
   - Keep one blank line between the remaining links. If nothing is left, leave
     the file empty (do not delete it).
   - If the file is a table, keep its header and remove the added rows; put
     the skip reason after the link in the skipped rows.

7. **Build and check the page.** From the repo root:
   `python site/build.py`, then check
   `_site/roadmap/index.html` has a tile for each new app (grep the names) and
   the "N apps on the way" count went up by the number added. Fix any missing
   icon or JSON error. If the build stops on an `::error::` in an `Apps/`
   folder you did not touch (another app half-added), leave that folder
   alone: copy the tracked files without it (`git ls-files`) plus your new
   files into a scratchpad folder and build there instead.

8. **Report** in a short table: app, added or skipped, and why (for skipped
   ones, and for added ones that need `/dev/kvm`, a GPU, lots of RAM or many
   services). Do not commit or push unless the user asks; `just deploy "<msg>"`
   is how they publish.
