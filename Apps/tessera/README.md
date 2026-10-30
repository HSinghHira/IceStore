---
site: https://tessera-docs-three.vercel.app
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Panel, path: /admin, icon: server }
screenshots: [Upload, Shared snippet, Admin dashboard]
variables:
  - name: TESSERA_AUTH__ADMIN_USERNAME
    group: First admin
    default: admin
    description: >-
      The user name of the first admin account. Only used on the very first
      start.
  - name: TESSERA_AUTH__ADMIN_EMAIL
    group: First admin
    default: admin@localhost.invalid
    description: >-
      The email of the first admin account. Only used on the very first start.
  - name: TESSERA_AUTH__REGISTRATION
    group: Sign-up and accounts
    default: open
    description: >-
      Who can make an account: open, invite (invite codes from the admin
      panel) or closed (only the admin adds accounts).
  - name: TESSERA_FEATURES__ANONYMOUS_UPLOAD
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false so only people who are signed in can upload.
  - name: TESSERA_FEATURES__ACCOUNTS
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn accounts off completely, so Tessera is upload-only.
  - name: TESSERA_AUTH__SESSION_TTL_HOURS
    group: Sign-up and accounts
    default: "720"
    description: >-
      How many hours someone stays signed in.
  - name: TESSERA_SHARE__DEFAULT_EXPIRY_HOURS
    group: Shares
    default: "168"
    description: >-
      How long a share lasts when the uploader picks nothing, in hours.
      The default is one week.
  - name: TESSERA_SHARE__MAX_EXPIRY_HOURS
    group: Shares
    default: "720"
    description: >-
      The longest lifetime anyone can ask for, in hours. The default is 30
      days.
  - name: TESSERA_SERVER__MAX_BODY_BYTES
    group: Shares
    default: "104857600"
    description: >-
      The biggest single upload request in bytes (100 MiB by default). Needs a
      restart to change.
  - name: TESSERA_SERVER__PUBLIC_URL
    group: Server
    default: ""
    description: >-
      The address people open Tessera at, like https://share.example.com. Used
      in links in emails and the command-line client. Leave it out to use the
      address in the browser.
  - name: TESSERA_FEATURES__DOCS
    group: Server
    default: "false"
    description: >-
      Set to true to show the API reference page.
  - name: TESSERA_SITE__TITLE
    group: Server
    default: Tessera
    description: >-
      The name shown in the browser tab and in link previews.
  - name: TESSERA_SECURITY__SECRET_KEY
    group: Server
    default: ""
    description: >-
      Your own key for the passwords saved in the admin panel, as 64 hex
      characters (openssl rand -hex 32). Leave it out: Tessera makes one on
      first start and keeps it in the data folder as secret.key. Never change
      it afterwards.
  - name: TESSERA_MAIL__HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your SMTP server, for password reset and sign-up emails. Leave it out to
      send no email.
  - name: TESSERA_MAIL__PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      The SMTP port.
  - name: TESSERA_MAIL__TLS
    group: Email (SMTP)
    default: auto
    description: >-
      auto, starttls or implicit (for port 465).
  - name: TESSERA_MAIL__USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The SMTP user name.
  - name: TESSERA_MAIL__PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The SMTP password.
  - name: TESSERA_MAIL__FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from, like Tessera <share@example.com>.
  - name: TESSERA_TELEMETRY__FILTER
    group: Logs
    default: info
    description: >-
      How much goes in the log: error, warn, info, debug or trace.
---

# Tessera

Tessera lets you upload a file, a folder, a snippet of code or a link and get back a short code and a URL. Whoever has them can open it until it expires or has been downloaded as many times as you allowed. Then it is deleted. It is one small program with the web app built in, and keeps its data in SQLite and on local disk.

## Features

- Every share has a lifetime and, if you want, a download limit
- Optional passwords, asked before anything is shown or downloaded
- Previews for code, images, SVGs and Mermaid diagrams
- Folders and many files, downloaded together as one archive
- Upload without an account, or turn on accounts with open, invite-only or closed sign-up, GitHub, Discord or any OpenID Connect provider
- An admin panel at `/admin` for users, shares, quotas, storage (local, S3, Azure, Google Cloud, WebDAV), email and branding
- A command-line client (`tess`) and plain `curl` uploads

## How to use

1. Open Tessera at `http://[ZIMAOS-IP-ADDRESS]:6178`.
2. Drop a file, a folder or some text on the page and pick how long it should last.
3. Share the short code or link it gives you.
4. Sign in as admin and open `/admin` to change sign-up, limits and storage.

## Before you install

You can set `TESSERA_AUTH__ADMIN_PASSWORD` to pick the admin password, or leave it empty and Tessera makes one on first start and prints it in the app log once (look for the line with "password"). The admin user name is `admin`. It is ready in a few seconds at `http://[ZIMAOS-IP-ADDRESS]:6178`. Anyone who can reach it can upload without an account, so turn that off in `/admin` if other people can reach it. Most settings live in the admin panel and work straight away; the ones in the Variables tab are added in the app settings. Back up the whole data folder: it holds the files, the database and `secret.key`.
