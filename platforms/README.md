# Platforms: one source, more app stores

`Apps/` is the only place an app is written. Other platforms get their store
generated from it, so a compose file is never copied by hand.

| Platform | Reads | Made by |
|---|---|---|
| ZimaOS, CasaOS, ReCasaOS, Homeio | `store.json` / `store.zip` on GitHub Pages | `release-store.yml`, straight from `Apps/` (unchanged) |
| MOS | `maintainer.json`, `compose/<Name>/`, `docker/<Name>.json` in the repo root | `adapters/mos.py` |

Everything lives in this one repo. MOS Hub `git clone`s the repo's default
branch and reads those paths from its root (checked in its source, mos-api
`hub.service.js`). It reads only `*.json` files directly inside `docker/`, so
the templates sit beside IceStore's `docker/<app>/` build folders and never touch
them. The ZimaOS/CasaOS builder reads only `Apps/`, and `store.zip` leaves the
MOS files out.

**Never edit the generated files** (`compose/`, `docker/*.json`,
`maintainer.json`). Every run replaces them.

To add the store in MOS, open **Settings → System Configuration → MOS Hub
Settings**, add `https://github.com/HSinghHira/IceStore` and click **Refresh**.
App data goes to `/mnt/cache/appdata/<app>`. Users with a pool not named
`cache` change the path in the install dialog (forms) or in `.env` (stacks).

## Run it

```sh
just platforms                        # make the MOS templates and update them in the repo root
just platforms-preview --app ntfy     # one app, into _platforms/ only
```

`just deploy` runs `just platforms` before it commits, so the templates go up
with the app change. The `platforms.yml` workflow does the same on GitHub and
commits anything that was missed (edits made on github.com, merged pull
requests). It needs no secret.

`_platforms/report.md` lists every app that was skipped or has warnings, and
why. `--check` exits 1 on any error. `--compose-config` also runs `docker compose
config` on every generated stack (CI does both).

## What the MOS adapter does

Rules come from the MOS docs (*Creating Your Own MOS Hub Repository*) and the
MOS source (mos-api `hub.service.js`, `dockercompose.service.js`).

- **`docker/<Name>.json`, the MOS install form.** Used for a single-service
  app whose settings all fit the form. Paths, ports and variables become form
  fields, and the rest becomes `docker run` flags (`extra_parameters`): restart,
  init, stop timeout, memory/CPU limits, user, capabilities, read-only, tmpfs,
  hostname, extra hosts and the health check. `$$` in the compose file becomes `$`.
- **`compose/<Name>/` (`compose.yaml`, `.env`, `template.json`), a stack.**
  Used for anything the form cannot hold: several services, an entrypoint
  script, a command, custom networks. `compose.yaml` is the master compose
  minus `x-casaos` and the icon label. Host folders, `TZ`, `PUID`/`PGID` and the
  server IP become `.env` settings, which MOS shows before deploying.
- `/DATA/AppData/$AppID` → `/mnt/cache/appdata/<app>`, `$TZ` → `Etc/UTC`,
  `$PUID`/`$PGID` → `500` (the MOS defaults), `[ZIMAOS-IP-ADDRESS]` → `YOUR-SERVER-IP`.
- `x-casaos.architectures` becomes `architecture`, so MOS hides amd64-only apps
  on ARM machines.
- Anything the form cannot carry is listed in the report ("not carried into the
  MOS form: ..."), never dropped silently. The usual one is
  `deploy.resources.reservations.cpus`, which `docker run` has no flag for. If
  a dropped setting matters, force the app to a stack with `format: compose`.

Store-wide values (path maps, variable values, wording, category names) are in
`config.yml`.

## Per-app overrides: `platforms/mos/overrides/<app>.yml`

Optional, and only for what has to differ on MOS. `Apps/` stays untouched and
no app has one yet. A file for an app that does not exist stops the generator,
so a typo or a renamed app is caught.

```yaml
enabled: false                 # leave the app out of MOS
reason: needs a USB device     # shown in the report
format: compose                # or docker; by default it is picked per app
name: My-App                   # template name (default: the title, dashed)
template:                      # merged into docker/<Name>.json or template.json (null deletes a key)
  category: [Media]
compose:                       # merged into compose.yaml (stacks only)
  services:
    myapp:
      privileged: null
env:                           # extra or changed .env lines (stacks only)
  APPDATA: /mnt/user/appdata/myapp
```

## Adding a platform later

1. Read the platform's packaging docs, and its source if the docs don't say
   where it reads the store from. Do not assume it runs the same compose file.
2. Check that its files can share this repo's root without clashing (Umbrel
   cannot: it needs one folder per app at the root).
3. Write `adapters/<name>.py`: a class based on `Adapter` with `build_app`
   (one app → files; raise `Skip("why")` when it cannot run there),
   `build_store` (store-level files), `check` (look over what was written), and
   `owned` / `outputs` (which repo-root paths are its own). `self.translate()`
   and `self.words()` already handle paths, variables and wording.
4. Add it to `ADAPTERS` in `adapters/__init__.py`, give it a block in `config.yml`,
   and add its root paths to the `git add` line in `platforms.yml` and the
   `-x` list in `release-store.yml`.
