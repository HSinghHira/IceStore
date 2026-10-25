# WRAPPER.md — upstream image + a start script (per-install secrets)

For a simple, one-image app that needs a secret unique to each install and
doesn't make one itself. A secret written in the compose file is the same for
everyone who installs from IceStore (`COMPOSE.md` §9), so the image makes it
instead. The working example is Pocket ID: `docker/pocket-id/`,
`.github/workflows/build-pocket-id.yml`, `Apps/pocket-id/`.

If the app makes the secret itself when it's missing **and keeps it** in its
data folder (DocuSeal), you need no wrapper: leave the variable out of the
compose file. An app that makes a new one on every start (portracker's
`SESSION_SECRET`, which signs everyone out on restart) still needs a wrapper.

## Files

```
docker/<app>/
  Dockerfile          FROM <upstream image>:<pinned tag>   (one FROM, no AS)
                      COPY icestore-init.sh, ENV for the secret's file path,
                      LABEL org.opencontainers.image.source, ENTRYPOINT, CMD
  icestore-init.sh    POSIX sh (upstream may be Alpine/busybox): make the
                      secret once, then exec upstream's own entrypoint
.github/workflows/build-<app>.yml   the AIO template without the capture-meta step
```

## The start script

1. Keep the secret **in the app's data volume** (`/app/data/.encryption_key`),
   so it is backed up with the data and survives updates.
2. Make it on first start only, with `head -c 32 /dev/urandom | base64 | tr -d '\n'`
   (no `openssl` in most images), `umask 077`, write to a temp file then `mv`.
3. A variable from the app settings wins: if the person sets it, use it and
   write it to the file. Blank (ZimaOS passes empty strings) means "use the
   file". If an existing file differs, keep a `.previous` copy and log it.
4. Hand the secret over the way upstream reads it. Prefer the app's `*_FILE`
   variable when it has one; otherwise `export NAME="$(cat file)"`.
5. `exec` upstream's entrypoint with `"$@"` (look it up in the image config:
   Entrypoint/Cmd), so PUID/PGID handling and everything else stays upstream's.
6. Log one `[icestore] ...` line when a new secret is made.

**`docker exec` doesn't run the start script.** If the app checks its config
for every command (Pocket ID's `healthcheck` does), set the file path as an
`ENV` in the Dockerfile too, or the compose healthcheck fails.

## Compose and README

- `image: ghcr.io/hsinghhira/<app>:latest`; no secret in `environment:`.
- The secret goes in the README `variables:` list with `default: ""` and a
  description saying it is made on first start and must not change afterwards.
- The volume description names the secret's file and says to back it up.
- `x-casaos.version` = the FROM tag exactly; `release_notes` as `en_US: |-`
  bullets mentioning `<image> <tag>`, so the weekly bumper keeps it current.

## Checks

`check_app.py` treats `docker/<app>/` with a Dockerfile and no `aio-init.sh`
as a wrapper: one pinned FROM, LABEL source, ENTRYPOINT, LF line endings,
`sh -n` on the scripts, the workflow (arm64, `workflow_dispatch`,
`AIO_VERSION`) and the bumper shapes. Test the script outside Docker by
pointing its paths at a temp folder and replacing the final `exec` with an
`echo` of the variables: first start, restart, a value set, the value removed.
