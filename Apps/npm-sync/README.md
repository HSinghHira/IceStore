---
name: NPM Sync
source: https://github.com/ToYoNiX/nginx-proxy-manager-sync
services:
  - { name: Web page, path: /, icon: globe }
  - { name: Status API, path: /api/v1/status, icon: code }
variables:
  - name: CRON
    group: Schedule
    default: 0 */12 * * *
    description: >-
      When to sync, as a cron pattern. Set it empty to only sync from the
      page.
  - name: RUN_ON_START
    group: Schedule
    default: "true"
    description: >-
      Sync once when the app starts.
  - name: DRY_RUN
    group: Safety
    default: "false"
    description: >-
      Set to true to only show what a sync would change.
  - name: MAX_DELETES
    group: Safety
    default: "10"
    description: >-
      The most objects one run may delete on a backup; 0 means no limit.
  - name: EXCLUDE_DOMAINS
    group: Safety
    default: ""
    description: >-
      Domains never synced or touched, comma separated; * and ? work, like
      *.lab.example.com.
  - name: ALLOW_EMPTY_MASTER
    group: Safety
    default: "false"
    description: >-
      Set to true to allow syncing an empty master (which deletes everything
      on the backups).
  - name: FEATURES_CERTIFICATES
    group: What to sync
    default: "true"
    description: >-
      Set to false to leave certificates alone.
  - name: FEATURES_STREAMS
    group: What to sync
    default: "true"
    description: >-
      Set to false to leave streams alone.
  - name: BACKUP2_URL
    group: More backups
    default: ""
    description: >-
      A second NPM to copy to, with BACKUP2_USERNAME and BACKUP2_PASSWORD
      (then BACKUP3_..., with no gaps).
  - name: ACCESSLIST1_NAME
    group: Access lists
    default: ""
    description: >-
      An access list's name, with ACCESSLIST1_USER1_USERNAME and
      ACCESSLIST1_USER1_PASSWORD. NPM never shows these passwords, so lists
      without them aren't synced.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      debug, info, warn or error.
---

# NPM Sync

npm-sync copies everything from one Nginx Proxy Manager (the master) to one or more others: proxy hosts, redirections, 404 hosts, streams, access lists and certificates, including Let's Encrypt renewals. It is a one-way sync on a schedule, with a web page to watch and start it.

## Features

- Proxy hosts, redirection hosts, 404 hosts and streams created, updated and deleted to match the master
- Let's Encrypt and custom certificates copied and refreshed on renewal
- Access lists, with the passwords you give it
- Schedule, dry run, a cap on deletes and domains to leave alone
- Web page and API with each object's last result

## How to use

1. Make a user without two-factor sign-in on every NPM.
2. Set the master and backup addresses and logins before you install.
3. Open npm-sync from your dashboard and press **Sync now**.

## Before you install

Fill in `MASTER_URL`, `MASTER_USERNAME`, `MASTER_PASSWORD` (the NPM to copy from) and the `BACKUP1_` settings (the NPM to copy to) first; npm-sync won't start without them. Use NPM's admin port (usually 81) and a dedicated NPM user without two-factor sign-in on each instance, all on the same NPM version and time zone. Set `WEB_PASSWORD` so only you can use npm-sync's page, and try `DRY_RUN=true` first to see what it would change. More settings are in the Variables tab.
