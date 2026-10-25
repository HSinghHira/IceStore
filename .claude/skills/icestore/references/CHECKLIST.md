# CHECKLIST.md — before pushing

First run the checker and fix every ERROR:

```bash
python3 scripts/check_app.py <repo root> <app>
```

It covers: YAML validity, `name`, ids, category, version trio, ports in
6101–6199 and unused by other apps (`port_map` for host-network apps),
`:latest` or untagged upstream images, `version: latest`, PUBLIC_URL port, `TZ=$TZ`,
`envs` ↔ `environment:`, a long compose environment, README `variables:`
format, settings (compose or README) aio-init.sh never reads, raw `env | grep`
pass-through, image URLs and their files, `#` comments, leftover
`__PLACEHOLDERS__`, old ZimaAppStore names, tips step spacing, README front
matter and icons, and for AIO apps: required files, `.gitignore` name, shell
syntax (with Git Bash on Windows), CRLF line endings, `FROM ... AS img-` format, unpinned tags, LABEL source, gateway port,
programs ↔ img stages ↔ run-svc cases ↔ `write_env`, nginx tokens, `privileged`,
healthcheck path, and the workflow.

Then check by hand what it can't see:

1. **Dry run** of aio-init.sh (`AIO.md` §6) shows an env file per service and a
   gateway listening on 8080 and the 61xx port.
2. **The port number in text** — `x-casaos.envs` descriptions, port
   descriptions, `description`, `tips.before_install`, `release_notes`, README —
   is the new 61xx port everywhere.
3. **Every upstream tag** in the Dockerfile is a real, current release, and
   `release_notes` lists the same tags.
4. **arm64**: every upstream image has it, or arm64 is removed from both the
   workflow and `architectures`.
5. **No secrets** in any committed file, and none in any compose file: each
   install makes its own (aio-init.sh, a wrapper image, or the app itself).
   The checker warns about a fixed password/secret/token/key value.
6. **Settings**: compose `environment:` is short (`TZ`, `PUBLIC_URL`, admin).
   Every other setting a person might change (sign-up, SMTP, sign-in
   providers, feature switches, API keys, log level) is in the README
   `variables:` list with a real `default` and a plain description
   (`COMPOSE.md` §8). Each one is wired up in aio-init.sh, a missing or blank
   one changes nothing, and adding, changing or removing one after the first
   start works (the second dry run in `AIO.md` §6).
7. **Chroot services that keep data** have a bind mount from `/data` (`AIO.md` §3.6).
8. **`tips.before_install`** reads like it was written for a 4th grader, covers
   install to first use, and its wait time matches the healthcheck `start_period`.
9. **README and x-casaos.description** say the same things.
9a. **Other devices**: open the app (in your head, or for real) from another
    device with `PUBLIC_URL` left at its default. Either it works (it follows
    the browser's address, `AIO.md` §3.7), or `PUBLIC_URL` ships as
    `http://[ZIMAOS-IP-ADDRESS]:<port>`, the tips and README say first that
    it must be set, and the app shows a "set PUBLIC_URL" page instead of
    redirecting to localhost (`AIO.md` §3.5). Every address people type is
    written `http://[ZIMAOS-IP-ADDRESS]:<port>`.
10. **Images** the user still has to add are listed in your reply.
11. **AIO version**: `AIO_VERSION` in the workflow is bumped for any change to
    `docker/<app>/`.
12. **Weekly bumper can read it** (AIO only): run
    `python .github/scripts/update_upstream.py` from the repo root (dry run, no
    writes). The new app is listed, each FROM shows `ok` or `bump`, and none
    shows `WARN`. A tag it should not move has `# auto-update: hold` above it.

In the reply, remind the user to check after the first push that the
`ghcr.io/hsinghhira/<app>` package is public and that the image finished
building before installing.
