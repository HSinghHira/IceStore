---
site: https://ente.io
services:
  - { name: Photos web app, path: /, icon: globe }
  - { name: Mail viewer (sign-up codes), path: /mail/, icon: mail }
screenshots: [Phone app, End-to-end encrypted, Ente Photos, Ente is open source]
variables:
  - name: ENTE_API_URL
    group: Addresses
    default: ""
    description: >-
      The API address, if you put it behind your own domain, like
      https://api.photos.example.com. Leave it out to use PUBLIC_URL's host
      with port 6130.
  - name: ENTE_ALBUMS_URL
    group: Addresses
    default: ""
    description: >-
      The public albums address for shared links, like
      https://albums.example.com. Leave it out to use PUBLIC_URL's host with
      port 6131.
  - name: ENTE_S3_URL
    group: Addresses
    default: ""
    description: >-
      The photo storage address, like https://s3.example.com. Phones upload
      here, so it must be reachable from them. Leave it out to use
      PUBLIC_URL's host with port 6132.
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

# Ente Photos MinIO/Silo

Ente is a self-hosted, end-to-end encrypted place to store, share and rediscover your photos and videos on all your devices. This is Ente in a single container, with PostgreSQL, Silo, the community fork of MinIO that is still open source, and a mail viewer for sign-up codes inside. Secret keys and passwords are made for you on first start.

## Features

- End-to-end encryption for every photo and video
- Photos web app, plus a public albums app for sharing links
- Works with the Ente phone and desktop apps
- Silo (the open-source fork of MinIO) for S3-compatible photo storage
- Built-in mail viewer at `/mail/` for sign-up codes, or use your own email server
- No 10 GB limit: every account gets 100 TB by default

## How to use

1. Open Ente Photos MinIO/Silo from your dashboard.
2. Sign up with your email and a password.
3. Open the mail viewer at `/mail/` to read your sign-up code.
4. Type the code to finish signing up.
5. In the Ente phone app, tap the first screen 7 times and set the server to `http://your-zimaos-ip:6130`.
6. Upload photos and share albums.

## Before you install

Change `localhost` in `PUBLIC_URL` to your ZimaOS IP, like `http://192.168.1.20:6129`; phones cannot use `localhost`. Ente uses four ports on that address: 6129 for the photos web app, 6130 for the API (the server address in the phone and desktop apps), 6131 for shared album links and 6132 for photo storage. The first start takes about three minutes. Sign-up codes go to the mail viewer at `/mail/`: open the app logs, scroll to the top and find the line that says "mail viewer login" for its password. To send real email instead, and for the other settings, see the Variables tab; add them in the app settings. If you put Ente behind your own domains, set `ENTE_API_URL`, `ENTE_ALBUMS_URL` and `ENTE_S3_URL` too.
