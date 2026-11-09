---
name: KyNotes
site: https://busnes.app
source: https://github.com/Busnes-app/KyNotes-server
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Notebooks, Canvas, Sub-pages]
variables:
  - name: TRUSTED_PROXY_CIDRS
    group: Reverse proxy
    default: ""
    description: >-
      The address of your reverse proxy as KyNotes sees it, like
      172.17.0.1/32, so it believes the visitor's IP from the proxy. Only
      your proxy; never a whole network.
  - name: BOOTSTRAP_ADMIN_USER
    group: First accounts
    default: ""
    description: >-
      Make the administrator account on first start instead of on the setup
      page. Use it with BOOTSTRAP_ADMIN_PASS.
  - name: BOOTSTRAP_ADMIN_PASS
    group: First accounts
    default: ""
    description: >-
      The administrator's first password. It must be changed at the first
      sign-in.
  - name: BOOTSTRAP_EVERYDAY_USER
    group: First accounts
    default: ""
    description: >-
      Make an everyday (note-writing) account on first start, with a
      different name from the administrator.
  - name: BOOTSTRAP_EVERYDAY_PASS
    group: First accounts
    default: ""
    description: >-
      The everyday account's first password.
  - name: KYNOTES_BACKUP_DEPOSIT_INTERVAL
    group: Backups
    default: 24h
    description: >-
      How often KyNotes sends a sealed backup to a paired KyRecovery. 0 turns
      it off; the admin page setting wins.
  - name: KYNOTES_BACKUP_DIR
    group: Backups
    default: ""
    description: >-
      A folder inside the container for local sealed backups, like
      /data/backups.
  - name: KYNOTES_BACKUP_KEEP
    group: Backups
    default: "7"
    description: >-
      How many local backups to keep.
  - name: KYNOTES_BACKUP_ALLOW_PRIVATE_RECOVERY
    group: Backups
    default: "false"
    description: >-
      Set to true for a KyRecovery on your home network (it still needs
      https).
  - name: KYNOTES_BLOB_TARGET
    group: Attachment mirror
    default: ""
    description: >-
      Where to mirror the encrypted attachments (S3, SFTP, SMB or a folder).
      Backups don't include them, so set this for a complete backup. See
      upstream's deployment guide for the format.
  - name: KYNOTES_BLOB_TARGET_ACCESS_KEY
    group: Attachment mirror
    default: ""
    description: >-
      The user name or S3 access key for the mirror.
  - name: KYNOTES_BLOB_TARGET_SECRET
    group: Attachment mirror
    default: ""
    description: >-
      The password or S3 secret key for the mirror.
  - name: KYNOTES_BLOB_TARGET_S3_ENDPOINT
    group: Attachment mirror
    default: ""
    description: >-
      The S3 endpoint, for an S3 mirror that isn't AWS.
  - name: KYNOTES_BLOB_TARGET_S3_REGION
    group: Attachment mirror
    default: ""
    description: >-
      The S3 region of the mirror.
---

# KyNotes

KyNotes is a browser notebook for encrypted text, handwriting, attachments and tasks, with shared team notebooks. Notes are decrypted in your browser, so the server (and its administrator) never reads them. Part of the Busnes Ky Suite; it works on its own or with KyIdentity sign-in.

## Features

- Notebooks, sections and pages with text, ink canvases and attachments
- Tasks and a work queue across your notebooks
- Team notebooks with shared keys
- Separate administrator and everyday accounts; optional KyIdentity sign-in
- Sealed backups to KyRecovery, and an MCP server for AI agents

## How to use

1. Put KyNotes behind your reverse proxy with an https domain.
2. Copy the setup token from the app's logs.
3. Open your https address, enter the token and make the administrator and your everyday account.
4. Sign in with your everyday account and start writing.

## Before you install

**KyNotes needs https.** Browsers only allow the encryption it uses on an https address, or on the box itself at `http://localhost:6696`. Set up a reverse proxy with your own domain, like `https://notes.example.com`, pointed at `http://[ZIMAOS-IP-ADDRESS]:6696`, and set `TRUSTED_PROXY_CIDRS` to the proxy's address.

On the first start KyNotes prints a one-time setup token in its logs (the `setup_token` line), on every start until setup is done. The setup page asks for it and makes an administrator account (manages KyNotes, can't open notes) and an everyday account (writes notes). Keep the recovery codes it shows. It starts in a few seconds. More settings (backups, the attachment mirror) are in the Variables tab; add them in the app settings. The image is built for amd64 only.
