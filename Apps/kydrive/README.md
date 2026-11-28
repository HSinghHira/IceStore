---
site: https://busnes.app/kydrive.html
source: https://github.com/Busnes-app/kydrive-server
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [My files]
variables:
  - name: KY_SESSION_SECRET
    group: Keys
    default: ""
    description: >-
      The secret that keeps browser sign-ins valid. KyDrive makes it on first
      start when left empty and keeps it in the data folder. Never change it.
  - name: KY_SCIM_TOKEN
    group: Keys
    default: ""
    description: >-
      The secret KyIdentity uses to provision people and groups. KyDrive makes
      it on first start when left empty and keeps it in the data folder. Never
      change it.
  - name: KY_COOKIE_SECURE
    group: Reverse proxy
    default: ""
    description: >-
      Leave empty to mark cookies secure for KyDrive's required https address.
      Set true or false only when your proxy cannot report the original address
      correctly.
  - name: KY_TRUSTED_PROXIES
    group: Reverse proxy
    default: ""
    description: >-
      Addresses KyDrive sees your reverse proxy connect from. Set only your
      proxy's address so sign-in limits and audit records use visitors' real
      addresses.
  - name: KYDRIVE_CONTENT_SEARCH
    group: Search
    default: "on"
    description: >-
      Set to off to search file names only. Left on, KyDrive also searches the
      text in supported files.
  - name: KY_READ_TIMEOUT
    group: Transfers
    default: "5m"
    description: >-
      Longest time for one WebDAV or single-request upload. Use a value from
      15s to 15m when people upload over a slow connection.
  - name: KY_WRITE_TIMEOUT
    group: Transfers
    default: "5m"
    description: >-
      Longest time a download, preview or folder ZIP may stop making progress
      before KyDrive ends it. Use a value from 15s to 15m.
  - name: KYDRIVE_MAX_FILE_SIZE
    group: Transfers
    default: 10GiB
    description: >-
      Largest file one person can upload. Use a size such as 10GiB.
  - name: KYDRIVE_MAX_ZIP_SIZE
    group: Transfers
    default: 10GiB
    description: >-
      Largest folder ZIP that KyDrive can make. Use a size such as 10GiB.
  - name: KY_KYSIGNON_ISSUER
    group: KyIdentity sign-in
    default: ""
    description: >-
      Your KyIdentity address, such as https://id.example.com. It must be an
      https address.
  - name: KY_KYSIGNON_CLIENT_ID
    group: KyIdentity sign-in
    default: ""
    description: >-
      The client ID KyIdentity gave KyDrive.
  - name: KY_KYSIGNON_SECRET
    group: KyIdentity sign-in
    default: ""
    description: >-
      The client secret KyIdentity gave KyDrive. Keep it private.
  - name: KY_SSO_AUTO_PROVISION
    group: KyIdentity sign-in
    default: "false"
    description: >-
      Set to true to make an account the first time an allowed KyIdentity user
      signs in. Leave it false when an administrator should create accounts.
  - name: KY_RATE_LIMIT_EXEMPT_NETWORKS
    group: Sign-in protection
    default: ""
    description: >-
      Office network addresses that skip the sign-in rate limit, such as
      192.168.1.0/24. Never add your reverse proxy or a shared network.
  - name: KY_BACKUP_DEPOSIT_INTERVAL
    group: Backups
    default: "24h"
    description: >-
      How often KyDrive creates its encrypted backup capsule. Use a duration
      such as 24h.
  - name: KY_BACKUP_KEEP
    group: Backups
    default: "7"
    description: >-
      Number of local backup capsules to keep.
  - name: KY_BACKUP_COLLECT_TIMEOUT
    group: Backups
    default: ""
    description: >-
      Maximum time to collect a backup. Leave empty for KyDrive's default.
  - name: KYDRIVE_EDITOR_URL
    group: Euro-Office editing
    default: ""
    description: >-
      Https address of your separate Euro-Office service, such as
      https://office.example.com. Fill this and KYDRIVE_EDITOR_SECRET together.
      KY_APP_URL must also be https, or KyDrive will not start.
  - name: KYDRIVE_EDITOR_SECRET
    group: Euro-Office editing
    default: ""
    description: >-
      Shared 64-character hex secret for KyDrive and Euro-Office. Fill this
      and KYDRIVE_EDITOR_URL together, and make sure KY_APP_URL is https, or
      KyDrive will not start.
  - name: KYDRIVE_TLS_CERT_FILE
    group: Linked computers
    default: ""
    description: >-
      Read-only path to the certificate served by your reverse proxy. It lets
      linked apps follow certificate renewals without being linked again.
  - name: KYDRIVE_TLS_PIN_PROBE
    group: Linked computers
    default: "false"
    description: >-
      Set to true only when your proxy certificate cannot be mounted, such as
      with a Cloudflare Tunnel. KyDrive checks the public address instead.
---

# KyDrive

KyDrive is a private file drive for the Busnes Ky Suite. It keeps files in shared workspaces, lets people upload, download, share and recover versions, and works with WebDAV and compatible desktop sync clients. Everyday users sign in through KyIdentity.

## Features

- File workspaces with roles, sharing, version history and trash
- Upload, download, folder ZIP files and resumable transfers
- Name and content search for supported documents, PDFs and text files
- WebDAV access and compatible desktop sync clients
- Optional Euro-Office editing and document previews
- AI-agent access through MCP, with a chosen access level and optional folder limit
- Encrypted metadata backups and a separate bulk-file repository for recovery

## How to use

1. Set up an https reverse proxy, such as Nginx Proxy Manager, with your own domain. Point it at `http://[ZIMAOS-IP-ADDRESS]:6875`, then set `KY_APP_URL` to the proxy's exact https address.
2. Add your proxy's address to `KY_TRUSTED_PROXIES` for WebDAV and MCP. KyDrive's sign-in puzzle and other security checks need the https address in `KY_APP_URL`.
3. Open the app logs and find the box marked **CREDENTIALS**. It has the first `admin` password when `KY_ADMIN_PASSWORD` was left empty; otherwise use the password you set. The made password is also in `initial-admin-password` in the data folder.
4. Open KyDrive at the https address in `KY_APP_URL`, sign in as `admin` and change the password. Connect KyIdentity before adding everyday users: the local administrator only manages the drive.
5. KyDrive sets up its bulk-file backup repository on first start. Copy `data`, `backups` and `bulk` to another disk or machine: all three are needed for recovery.

## Before you install

**KyDrive requires https to sign in.** Its sign-in puzzle and security checks only run on a secure connection. Set up a reverse proxy, such as Nginx Proxy Manager, with your own domain and point it at `http://[ZIMAOS-IP-ADDRESS]:6875`. Set `KY_APP_URL` to the proxy's exact https address, such as `https://drive.example.com`, before you install. Add the proxy's address to `KY_TRUSTED_PROXIES` for WebDAV and MCP. Opening `http://[ZIMAOS-IP-ADDRESS]:6875` directly shows the sign-in page, but sign-in fails. Do not change the public address after people start using the drive.

When `KY_ADMIN_PASSWORD` is empty, the first administrator password is in the **CREDENTIALS** box in the app logs and also in `initial-admin-password` in `/DATA/AppData/kydrive/data` (open it with the Files app). If you set `KY_ADMIN_PASSWORD`, use that instead. Change the password after the first sign-in and remove the file. Keep `data`, `backups` and `bulk` together in a copy on another disk: the metadata backup alone does not contain every file. More optional settings are in the Variables tab; add them in the app settings. The image is built for amd64 only.
