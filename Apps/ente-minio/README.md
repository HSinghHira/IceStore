---
site: https://ente.io
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API Server, path: /, icon: server, port: 6631 }
  - { name: Public Albums, path: /, icon: external-link, port: 6632 }
  - { name: Mail Server, path: /mail/, icon: mail, port: 6634 }
  - { name: Accounts, path: /, icon: check, port: 6635 }
  - { name: Auth, path: /, icon: tag, port: 6636 }
  - { name: Cast, path: /, icon: monitor, port: 6637 }
  - { name: Public Locker, path: /, icon: external-link, port: 6638 }
  - { name: Embed, path: /, icon: code, port: 6639 }
  - { name: Paste, path: /, icon: copy, port: 6640 }
  - { name: Locker, path: /, icon: package, port: 6641 }
  - { name: Public Memories, path: /, icon: grid, port: 6642 }
screenshots: [Phone app, End-to-end encrypted, Ente Photos, Ente is open source]
variables:
  - name: ENTE_API_URL
    group: Addresses
    default: ""
    description: >-
      The API address, if you put it behind your own domain, like
      https://api.photos.example.com. Leave it out to use PUBLIC_URL's host
      with port 6631.
  - name: ENTE_APPS_PUBLIC_ALBUMS
    group: Addresses
    default: ""
    description: >-
      The Public Albums address for shared links, if you put it behind your own domain, like
      https://albums.example.com. Leave it out to use PUBLIC_URL's host with
      port 6632.
  - name: ENTE_S3_URL
    group: Addresses
    default: ""
    description: >-
      The photo storage address, like https://s3.example.com. Phones upload
      here, so it must be reachable from them. Leave it out to use
      PUBLIC_URL's host with port 6633.
  - name: ENTE_APPS_ACCOUNTS
    group: Addresses
    default: ""
    description: >-
      The Accounts app address (passkeys, family invites), if you put it behind your own domain, like
      https://accounts.example.com. Leave it out to use PUBLIC_URL's host with
      port 6635.
  - name: ENTE_APPS_CAST
    group: Addresses
    default: ""
    description: >-
      The Cast app address, if you put it behind your own domain, like
      https://cast.example.com. Leave it out to use PUBLIC_URL's host with
      port 6637.
  - name: ENTE_APPS_PUBLIC_LOCKER
    group: Addresses
    default: ""
    description: >-
      The Public Locker address for shared Locker links, if you put it behind your own domain, like
      https://share.example.com. Leave it out to use PUBLIC_URL's host with
      port 6638.
  - name: ENTE_APPS_EMBED_ALBUMS
    group: Addresses
    default: ""
    description: >-
      The Embed app address, if you put it behind your own domain, like
      https://embed.example.com. Leave it out to use PUBLIC_URL's host with
      port 6639.
  - name: ENTE_APPS_PUBLIC_PASTE
    group: Addresses
    default: ""
    description: >-
      The Ente Paste address, if you put it behind your own domain, like
      https://paste.example.com. Leave it out to use PUBLIC_URL's host with
      port 6640.
  - name: ENTE_APPS_PUBLIC_MEMORIES
    group: Addresses
    default: ""
    description: >-
      The Public Memories address for shared memories, if you put it behind your own domain, like
      https://memories.example.com. Leave it out to use PUBLIC_URL's host with
      port 6642.
  - name: ENTE_APPS_FAMILY
    group: Addresses
    default: https://family.ente.io
    description: >-
      The Family web app address. It is not in this image, so it stays
      Ente's unless you host your own copy.
  - name: ENTE_APPS_SPACE
    group: Addresses
    default: https://ente.space
    description: >-
      The Space web app address. It is not in this image, so it stays
      Ente's unless you host your own copy.
  - name: ENTE_APPS_LEGACY
    group: Addresses
    default: https://legacy.ente.com
    description: >-
      The Legacy recovery web app address. It is not in this image, so it
      stays Ente's unless you host your own copy.
  - name: ENTE_APPS_ACCOUNTS_LEGACY
    group: Addresses
    default: https://accounts.ente.io
    description: >-
      The old Accounts address, only used to move passkeys made there.
      Most people leave it out.
  - name: ENTE_WEBAUTHN_RPID
    group: Addresses
    default: ""
    description: >-
      The domain passkeys belong to, like example.com. Leave it out to use
      the Accounts app's host. Passkeys only work on https with a domain,
      not an IP address.
  - name: ENTE_INTERNAL_DISABLE_REGISTRATION
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so nobody new can sign up. Make your own account first.
  - name: ENTE_INTERNAL_ADMIN
    group: Sign-up and accounts
    default: ""
    description: >-
      The user id of the admin account, for the Ente command-line tool.
  - name: ENTE_AIO_STORAGE_GB
    group: Storage
    default: "102400"
    description: >-
      Storage for every account in GB (102400 is 100 TB). Set to 0 to keep
      Ente's normal 10 GB plan.
  - name: ENTE_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com, to send sign-up codes by real
      email. Leave it out to use the built-in mail viewer at /mail/.
  - name: ENTE_SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      The mail server port. Usually 587, or 465 for SSL.
  - name: ENTE_SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: ENTE_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: ENTE_SMTP_EMAIL
    group: Email (SMTP)
    default: noreply@ente.local
    description: >-
      The sender address. Your mail server may only accept its own address.
  - name: ENTE_SMTP_SENDER_NAME
    group: Email (SMTP)
    default: Ente
    description: >-
      The sender name on the emails.
  - name: ENTE_SMTP_ENCRYPTION
    group: Email (SMTP)
    default: ""
    description: >-
      Set to ssl for a mail server that uses SSL from the start (port 465
      sets this for you). Leave it out for 587.
  - name: MP_UI_AUTH
    group: Mail viewer
    default: ""
    description: >-
      Your own mail viewer login as user:password. Leave it out to use admin
      with the password from the app log.
---

# Ente - MinIO S3

Ente is a self-hosted, end-to-end encrypted place to store, share and rediscover your photos and videos on all your devices. This is Ente in a single container, with PostgreSQL, Silo, the community fork of MinIO that is still open source, and a mail viewer for sign-up codes inside. Secret keys and passwords are made for you on first start.

## Features

- End-to-end encryption for every photo and video
- All ten Ente web apps, each on its own port: Photos, Public Albums, Accounts, Auth, Cast, Locker, Public Locker, Embed, Paste and Public Memories
- Works with the Ente phone and desktop apps
- Silo (the open-source fork of MinIO) for S3-compatible photo storage
- Built-in mail viewer on port 6634 for sign-up codes, or use your own email server
- No 10 GB limit: every account gets 100 TB by default

## How to use

1. Open Ente - MinIO S3 from your dashboard.
2. Sign up with your email and a password.
3. Open the mail viewer at `http://your-zimaos-ip:6634` to read your sign-up code.
4. Type the code to finish signing up.
5. In the Ente phone app, tap the first screen 7 times and set the server to `http://your-zimaos-ip:6631`.
6. Upload photos and share albums.

## Server address for the apps

The Ente phone and desktop apps need the API address: `http://your-zimaos-ip:6631`. On the first screen of the app, tap 7 times, then type that address as the server. If you set `ENTE_API_URL` (your own domain), use that instead.

## Ports

Every app has its own port on your ZimaOS address, counted up from the Web App's port (6630):

| Port | App |
|---|---|
| 6630 | Web App (Ente Photos). The mail viewer also answers at /mail/ here |
| 6631 | Ente API - the server address for the phone and desktop apps |
| 6632 | Public Albums (shared album links) |
| 6633 | Photo storage (Silo S3) |
| 6634 | Mail viewer for sign-up codes and other Ente emails |
| 6635 | Accounts app (passkeys and family invites) |
| 6636 | Ente Auth web app (your two-factor codes) |
| 6637 | Cast app (show albums on a TV) |
| 6638 | Public Locker (shared Locker links) |
| 6639 | Embed app (albums inside other web pages) |
| 6640 | Ente Paste (share text that deletes itself) |
| 6641 | Ente Locker web app (store important documents) |
| 6642 | Public Memories (shared memory links) |

The Family, Space and Legacy web apps are not in this image. Ente's own copies are used unless you set `ENTE_APPS_FAMILY`, `ENTE_APPS_SPACE` or `ENTE_APPS_LEGACY` to your own.

Passkeys need the Accounts app on `https` with a domain name; browsers refuse them on a plain IP address.

## Before you install

Change `localhost` in `PUBLIC_URL` to your ZimaOS IP, like `http://192.168.1.20:6630`; phones cannot use `localhost`. The other apps use the next ports on that address (see Ports above); the phone and desktop apps need the API on 6631. The first start takes about three minutes. Sign-up codes go to the mail viewer on port 6634: open the app logs, scroll to the top and find the line that says "mail viewer login" for its password. To send real email instead, and for the other settings, see the Variables tab; add them in the app settings. If you put Ente behind your own domains, set `ENTE_API_URL`, `ENTE_S3_URL` and the `ENTE_APPS_*` addresses too.

Updating from the old ports (6129-6132)? Your install keeps working as it is. To get the new apps' ports, reinstall the app, or change the ports and `PUBLIC_URL` to 6630 and up.
