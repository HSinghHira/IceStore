---
name: screenshots-hunter
description: "Use when the user types /screenshots-hunter, or asks to find, collect or add screenshots for IceStore apps, or to list apps that have no screenshots. Lists every Apps/<app> without screenshot files, then works through them: finds candidate images in the app's upstream README, repo and website, looks at each one, keeps only real screenshots of that app, saves them as Apps/<app>/screenshot-N.png, writes screenshot_link, thumbnail and README captions, and ships each app on its own. Apps with nothing usable are recorded with a reason so later runs skip them."
---

# Screenshots Hunter

The site shows a screenshot slider on each app page, and the first screenshot is
the link preview. ZimaOS and CasaOS show `screenshot_link` in the store. About a
third of IceStore's apps have none. This skill collects them from each app's own
upstream project.

Everything runs from the repo root with one helper script:

```
python .claude/skills/screenshots-hunter/scripts/hunt.py list            # apps with no screenshots
python .claude/skills/screenshots-hunter/scripts/hunt.py find <app>      # download candidates
python .claude/skills/screenshots-hunter/scripts/hunt.py add <app> <img> [<img> ...] --captions "Home|Editor"
python .claude/skills/screenshots-hunter/scripts/hunt.py skip <app> "reason"
```

`find` saves candidates in `.task/shots/<app>/` (git-ignored) with a
`candidates.json`. `skip` writes to `.task/screenshots-missing.md`, which `list`
reads so skipped apps are not tried again (`list --all` shows them with the
reason).

## Steps

1. **List.** Run `hunt.py list` and show the user how many apps have no
   screenshots. If the user named apps, do only those; otherwise work down the
   list in order. Don't ask before each app.

2. **For each app, find candidates.** Run `hunt.py find <app>`. It pulls images
   from upstream's README, screenshot-like files in the repo tree (`docs/`,
   `screenshots/`, `assets/`, `.github/`), and the og:image and `<img>` tags on
   the project site. It drops badges, logos, icons, SVGs and anything smaller
   than 500x300.

3. **Look at every candidate before choosing.** Open each file with the Read
   tool. The script can't tell a screenshot from a diagram. Keep an image only
   when all of these are true:
   - It shows **this app's own interface** (not a logo, banner, architecture
     diagram, terminal of the install, chart of stars, or another product).
   - It is **upstream's own image**: from the app's repo, its official site or
     docs, or its official demo. Never from blogs, review sites, stock photos or
     search results, and never made up or edited to look like the app.
   - It is current enough to look like the app people will install (skip
     screenshots of a clearly older major version when newer ones exist).
   - No personal data that looks real (emails, faces, addresses). Demo data is
     fine.

   Pick **1 to 4** images. Put the best wide desktop view first: it becomes the
   thumbnail and the social preview. Phone-shaped (portrait) images only go
   after a desktop one, and only for apps that are mainly phone apps. A
   marketing image that frames the real UI (for example in a laptop mockup) is
   fine when there is nothing plainer.

4. **Nothing usable in the found candidates? Look a bit further** before
   giving up:
   - The docs site linked in the README (a "Screenshots", "Features" or
     "Getting started" page). Download the image URL you find there into
     `.task/shots/<app>/` with `curl -L -o`, then look at it.
   - The GitHub repo's latest release notes, often with images
     (`gh api repos/<owner>/<repo>/releases/latest -q .body`).
   - An **official public demo** that upstream links. Take a 1600x1000
     screenshot of it with a headless browser, for example on Windows:
     `"C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless=new --disable-gpu --window-size=1600,1000 --screenshot="<abs path>.png" <demo url>`.
     Only the landing page or pages a visitor sees without signing in; never
     sign up or type anything into someone else's demo.

   Still nothing: run `hunt.py skip <app> "<short reason>"` (like "README has
   only a logo, no docs site", "only a terminal app screenshot", "demo needs
   sign-in") and move on.

5. **Add.** Run `hunt.py add <app> <file1> <file2> ... --captions "A|B"`.
   Captions are 1 to 4 plain words each, saying what the picture shows (Home,
   Board view, Settings, Dark mode). The script:
   - converts to PNG, at most 1920 px wide and about 1.5 MB, first frame of a GIF;
   - names them `screenshot-1.png`, `-2`, ... after any existing ones
     (`--replace` removes the old ones first);
   - writes `screenshot_link:` and `thumbnail:` (the first screenshot) under the
     top-level `x-casaos` icon line in `docker-compose.yml`;
   - writes `screenshots: [...]` captions into the README front matter;
   - runs the IceStore checker and prints its errors and warnings.

   Fix any ERROR it prints. The "no screenshot-N.png" warning should be gone.

6. **Ship each app on its own:**
   `bash tools/ship_app.sh <app> -m "Add screenshots for <Title>"`. It stages only
   `Apps/<app>/` (plus `docker/<app>/` and the workflow, which are unchanged
   here), so other work in the checkout is never swept in. Screenshots don't
   start an image build; the store release and MOS template runs pick them up.
   If the push is rejected because of unrelated tracked changes in the
   checkout, stop and tell the user instead of committing those.

7. **Report.** At the end (or when the user says stop) give a short table: apps
   that got screenshots (how many each) and apps skipped with the reason. Clean
   up `.task/shots/` for apps that are done.

## Rules

- Never commit a placeholder, a generated picture or an icon as a screenshot.
  No screenshot is better than a wrong one.
- Never hotlink: files go in `Apps/<app>/` and are served by jsdelivr
  (`https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/<app>/screenshot-N.png`).
- Don't change anything else in the app (compose settings, README text) while
  adding screenshots.
- Apps that already have screenshots are left alone unless the user asks to
  replace them (`--replace`).
- Root `README.md` and `readme/*.svg` are redrawn by a workflow after the push;
  don't touch them (same rule as the icestore skill).
