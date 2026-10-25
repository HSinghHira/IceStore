# COMPOSE.md — Apps/<app>/docker-compose.yml

Start from `templates/docker-compose.aio.yml` or `templates/docker-compose.simple.yml`.
`examples/appflowy/Apps/appflowy/docker-compose.yml` is a finished AIO manifest.

## 1. Top level

```yaml
name: <app>              # required, = folder name. Without it the app silently doesn't appear.
services:
  <app>: ...             # main service, named <app>
x-casaos: ...            # required; id is required or the build action fails
```

## 2. The main service

| Key | AIO app | Simple app |
|---|---|---|
| `image` | `ghcr.io/hsinghhira/<app>:latest` | upstream image, pinned tag |
| `container_name` | `<app>` | `<app>` |
| `restart` | `unless-stopped` | `unless-stopped` |
| `stop_grace_period` | `90s` (Postgres needs time to stop) | `40s`, more for databases |
| `privileged` | `true` when any service runs in a chroot (aio-init mounts /proc) | no |
| `network_mode` | leave out | `bridge` unless upstream needs otherwise |
| ports | `target: 8080`, `published: "<61xx>"` | upstream port → `"<61xx>"` |
| volume | `/DATA/AppData/$AppID/data` → `/data` | `/DATA/AppData/$AppID/<name>` → upstream path |
| `healthcheck` | `curl` to `http://127.0.0.1:8080<health path>`, `start_period` long enough for first start (AppFlowy: 240s) | only if the image has curl/wget |
| `deploy.resources` | limits and reservations, both required | same |
| `labels.icon` | jsdelivr icon URL (§6) | same |

Ports use the long form (`target`, `published` as a quoted string, `protocol: tcp`).
Volumes use the long form with `bind.create_host_path: true`.

Prefer env vars over mounting a config file: a missing host file becomes an
empty directory and breaks the container in a confusing way.

## 3. Service-level `x-casaos`

```yaml
    x-casaos:
      id: com.icestore.<app>          # same as top level
      envs:                           # one entry per variable in environment:
        - container: TZ
          description:
            en_US: ...
      ports:
        - container: "8080"
          description:
            en_US: <what is on it>, published on host as <61xx>
      volumes:
        - container: /data
          description:
            en_US: <what is stored>
```

**Every `envs[].container` must also be in `environment:`**, even when its value
is empty (`- ADMIN_PASSWORD=`). ZimaOS and the site only show `environment:`
entries; the description alone does nothing. Every `environment:` entry should
have a description. Keep `environment:` short; the full list of optional
settings goes in the README (§8).

## 4. Top-level `x-casaos`

```yaml
x-casaos:
  id: com.icestore.<app>
  architectures: [amd64, arm64]      # only what every upstream image ships
  main: <app>
  author: HSinghHira
  category: <fixed list>
  developer: <upstream org>
  icon: https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/<app>/icon.png
  title: {en_US: <App Name>}
  tagline: {en_US: <one line>}
  description: {en_US: <markdown, see §5>}
  tips: {before_install: {en_US: <numbered steps, see §5>}}
  index: /
  port_map: "<61xx>"
  scheme: http
  is_uncontrolled: false
  version: "<main upstream version>"
  update_at: "<YYYY-MM-DD this manifest was checked>"
  release_notes: {en_US: <bullets about THIS manifest/image change>}
  repo: "<upstream repo>"
  support: "<upstream repo>/issues"
  docs: "<upstream docs>"
```

**Category** must be one of: Media, Productivity, Home, Networking, AI, Finance,
Social, Developer, Others.

`version`, `update_at` and `release_notes` go together. For an AIO app,
`version` is the main upstream version (AppFlowy: `appflowy_cloud` 0.19.2), and
`release_notes` lists every upstream image and tag inside the image.

The weekly bumper edits these three for AIO apps (`REPO.md`,
update-upstream.yml), so keep them in the form it reads: `version` is exactly the
main image's FROM tag (no `v` added or dropped), `release_notes` is
`en_US: |-` with one `      - ` bullet per line, and tags are written as
`<image basename> <tag>` or `<full image> <tag>`, e.g. `gotrue 0.18.8`.

`supported-languages.json` is `["en_US"]`, so only write `en_US`.

## 5. Text fields

`description` and `tips.before_install` are markdown inside a YAML `>-` block.
A folded block joins single newlines into spaces, so **leave a blank line between
every paragraph, bullet and numbered step** (AppFlowy uses two blank lines between
steps; one is the minimum). Indent the continuation of a long step under its text.

`description` = one or two sentences of pitch, then `**Features**` bullets, then
`**How to use?**` numbered steps. For AIO apps say what is bundled inside
("PostgreSQL, Redis and Silo file storage inside") and what is left out.

`tips.before_install` covers install to first use, written for a 4th grader:
short sentences, everyday words, one action per step, no explaining why. It
must cover, when they apply:

1. Values to set first (`ADMIN_EMAIL`, `CHANGEME` placeholders) — name the variable.
2. `PUBLIC_URL` (§7). When the address must be set, the step says so plainly
   ("You must do this, or sign-in won't work"), quotes the placeholder
   `http://[ZIMAOS-IP-ADDRESS]:<port>` and gives an example with a real IP.
   When it is optional, say what changing `localhost` gives (links in emails).
3. How long the first start takes.
4. Where to find a generated password (the app log line, e.g. "admin password is").
5. First sign-in / account creation.
6. Extra paths like `/console` or `/mail`, written as
   `http://[ZIMAOS-IP-ADDRESS]:<port>/path`.

Write every address a person types the same way, in the tips, the
description, the envs descriptions and the README: `http://[ZIMAOS-IP-ADDRESS]:<port>`,
never `your-zimaos-ip`, `<your-ip>` or `[SERVER-IP]`. The README's "Before
you install" starts with the required address in bold when there is one.

## 6. Images

All image URLs point at this repo through jsdelivr, never at upstream or
raw.githubusercontent.com:

```
https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/<app>/<file>
```

The path is case-sensitive and must match a committed file. `icon` is required.
`thumbnail` and `screenshot_link` are optional; leave them commented out until
the files exist (the only allowed `#` lines).

## 7. Variables

- `TZ=$TZ` always (ZimaOS fills it in). Never hardcode a time zone.
- `PUID=$PUID` / `PGID=$PGID` only if upstream lists them (rare for AIO apps:
  services run as their own users inside the container).
- **App URL**: `PUBLIC_URL` with the literal 61xx port. `$PORT` is not used in
  IceStore because it hasn't been confirmed to be filled in. ZimaOS can't fill
  in the box's IP either (inside the container only the Docker bridge address
  is known), so pick the default by asking: **does the app work from another
  device while `PUBLIC_URL` says localhost?**
  - **No — the address must be set** (the app is or uses an OIDC/OAuth server
    such as Logto, Authentik or GoTrue whose issuer and redirect URIs are
    fixed; or it builds absolute redirects the browser follows): ship
    `PUBLIC_URL=http://[ZIMAOS-IP-ADDRESS]:<61xx>`. The envs description
    starts with "Required. Replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP".
    aio-init must handle the placeholder (`AIO.md` §3.5): run on localhost so
    the services start, and show a "set PUBLIC_URL to http://<this host>:<port>"
    page to every other address instead of redirecting to localhost.
    Trackie is the example. The checker fails a placeholder that aio-init or
    the tips never mention.
  - **Yes — it is only used for links** (emails, share links) or the app can
    follow the browser's address (`AIO.md` §3.7, Stoat): ship
    `PUBLIC_URL=http://localhost:<61xx>`, as AppFlowy does, and the tips say
    to change `localhost` for working email links.
  Never `CHANGEME_IP` or `[SERVER-IP]`: one placeholder, `[ZIMAOS-IP-ADDRESS]`.
- Shell variables (`$HOME`, `$USER`, ...) are never install-time values.
- Data path is always `/DATA/AppData/$AppID/...`.

## 8. Settings: short compose, full list in the README

Two places, two audiences:

- **`docker-compose.yml` `environment:`** is what a newcomer sees in the ZimaOS
  install screen. Keep it **short**: only what is needed to start or what
  almost everyone sets — `TZ`, `PUBLIC_URL`, and the admin email/password when
  the app has them. Nothing optional.
- **`README.md` front matter `variables:`** is the **full list** of settings a
  person might change. The website shows it in the app page's **Variables**
  tab, grouped, under the compose ones (`APP_README.md` has the format). To use
  one, people add the variable in the app settings in ZimaOS; leaving it out
  means the default.

What goes in the README list (go through upstream's `.env` example, config
reference and docs, not only its compose file):

| Include | Leave out |
|---|---|
| sign-up rules (disable sign-up, invite only, email confirmation) | values the AIO wires up itself: database/Redis/S3 URLs, internal ports, hostnames |
| outgoing email (SMTP host, port, user, password, sender, TLS) | secrets `aio-init.sh` generates (JWT, DB, S3 keys) |
| sign-in with Google/GitHub/OIDC/... (enabled, client id, secret) | settings for services the AIO dropped (AI service, pgAdmin) |
| server name, session length, password rules | developer/debug switches, test flags, tuning knobs most people never touch |
| feature switches (AI on/off, search, guest access, notifications) | anything that would break the AIO if changed (sub-path, listen address) |
| API keys for optional features | |
| log level | |

Rules:

- **Every README variable must work.** For AIO apps, `aio-init.sh` reads each
  one (`AIO.md` §3.5) and treats a missing or blank one as "use the default",
  also when it is added, changed or removed after install. The checker fails a
  README variable that `aio-init.sh` never reads.
- **Simple apps** pass variables straight to the image, so only list ones the
  image reads itself, under their upstream names.
- **Use the upstream name** when the service reads that variable itself
  (`GOTRUE_DISABLE_SIGNUP`, `MAILER_HOST`). Make up a name only when upstream
  has no variable for it (a config-file key, or a value shared by several
  services); prefix it with the app name (`AFFINE_ALLOW_SIGNUP`).
- **`default`** is the value used when the variable is left out — a real
  value (`465`, `true`) or `""` when there is none. Never prose: put "Leave it
  out to keep Google sign-in off" in the description instead.
- **`description`**: one or two plain sentences: what it does, what to type.
  For switches, say what setting it changes it to ("Set to false so only
  people you invite can join.").
- **`group`** them the way people think: Server, Sign-up and accounts, Email
  (SMTP), Sign in with ..., Features, AI, Logs.
- A variable is in **one** place: compose or README, never both.
- `tips.before_install` gets one step pointing at the list:
  "More settings ... are listed on the <App> page at
  https://icestore.hsinghhira.me/app/<app>/ (Variables tab). You can add
  them now or later in the app settings."

## 9. Secrets

Nothing personal ever goes in the repo; the compose file is shown on the website.

- **AIO apps:** no secret values in the compose file at all. `aio-init.sh` makes
  them with `openssl rand` on first start and keeps them in
  `/data/state/secrets.env`. The admin password is `ADMIN_PASSWORD=` (empty):
  empty means "make one and print it in the log"; a value means "use this".
- **Simple apps:** a cryptographic secret (encryption key, JWT/session secret,
  database password) must be **unique to each install**. A value written in the
  compose file is the same for everyone who installs from IceStore, so never
  put one there, not even a freshly generated one. Instead:
  1. If the app makes the secret itself when it's missing and keeps it in its
     data folder, leave the variable out of the compose file (it may go in the
     README `variables:` list for people who want their own).
  2. Otherwise build a **wrapper image** (`WRAPPER.md`): upstream's image plus
     a start script that makes the secret on first start, keeps it in the data
     folder and hands it to the app. Pocket ID's `ENCRYPTION_KEY` works this way.
  Identifying values (an email, a username) use a `CHANGEME...` placeholder
  (`ADMIN_EMAIL=CHANGEME@example.com`).
- The site shows secret-looking variables (password/secret/token/key in the name)
  as `change-me` unless the value starts with `$`. Don't rely on that.

## 10. No comments

Never use `#` to explain anything in the compose file.

| Needs explaining | Goes in |
|---|---|
| what a variable is / what to put | `x-casaos.envs[].description` |
| what a port is for | `x-casaos.ports[].description` |
| what a volume holds | `x-casaos.volumes[].description` |
| why something is missing or floating | `release_notes` or `description` |
| something to do before install | `tips.before_install` |
