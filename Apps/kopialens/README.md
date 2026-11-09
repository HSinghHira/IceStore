---
name: KopiaLens
site: https://kopialens.com
source: https://github.com/AnshulJ999/KopiaLens
services:
  - { name: Web App (https), path: /, icon: globe }
screenshots: [Dashboard, Tree, Search, Churn]
variables:
  - name: KOPIALENS_HTTPS
    group: Server
    default: ""
    description: >-
      Set to off to serve plain http instead of https with KopiaLens's own
      certificate (for example behind your own reverse proxy).
  - name: KOPIALENS_ACCESS
    group: Server
    default: ""
    description: >-
      Set to addresses to only let the addresses in
      KOPIALENS_ACCESS_ADDRESSES in.
  - name: KOPIALENS_ACCESS_ADDRESSES
    group: Server
    default: ""
    description: >-
      Allowed addresses or ranges, like 192.168.1.0/24.
  - name: PUID
    group: Server
    default: ""
    description: >-
      Run as this user instead of root. Use the user that writes your Kopia
      repository; the backed-up folders must be readable by it.
  - name: PGID
    group: Server
    default: ""
    description: >-
      The group to run as, with PUID.
  - name: KOPIALENS_KEY_FILE
    group: Server
    default: ""
    description: >-
      A file with the encryption password, so the index unlocks on start.
  - name: KOPIALENS_NO_UPDATE_CHECK
    group: Privacy
    default: ""
    description: >-
      Set to 1 to turn off update checks.
  - name: KOPIALENS_NO_USAGE_STATS
    group: Privacy
    default: ""
    description: >-
      Set to 1 to turn off usage stats.
---

# KopiaLens

KopiaLens is a backup app for Kopia with an analysis engine built in. It creates repositories, runs your backups on a schedule, restores files and runs maintenance, and it shows what Kopia can't show quickly: what each folder really costs after deduplication, which snapshots hold a file, how your backups grow, and what isn't backed up at all.

## Features

- Scheduled, encrypted, deduplicated backups to disks, S3, B2, SFTP and more, with Kopia inside
- Restore or download any file from any snapshot; policies and retention
- Real sizes after deduplication, search across every snapshot, tree and churn views
- Excluded view: the folders no backup covers
- Notifications, an HTTP API and the `klens` command line; clean-up tools in the Pro version

## How to use

1. Open KopiaLens from your dashboard (https; accept the certificate warning).
2. Finish the first-time setup and choose a sign-in password.
3. Connect your Kopia repository or create a new one, for example in `/DATA/Backup/kopia`.
4. Add folders under `/DATA` to back up.

## Before you install

KopiaLens serves **https** with its own certificate on port 6708, so your browser warns the first time: open `https://[ZIMAOS-IP-ADDRESS]:6708` and go on. Set a sign-in password in the setup; without one, anyone on your network can open it. Setup is open for the first 30 minutes after a start, then it asks for a setup code printed in the app's logs.

All of `/DATA` is mounted at the same path inside, so repositories and folders there keep their paths. Mounting snapshots as folders needs FUSE: in the app settings add the device `/dev/fuse`, the `SYS_ADMIN` capability and `apparmor:unconfined`. Everything else works without it. It runs as root unless you set `PUID`/`PGID`.
