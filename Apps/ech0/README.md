---
site: https://www.ech0.app/
services:
  - { name: Timeline, path: /, icon: globe }
  - { name: API docs, path: /api/docs, icon: code }
screenshots: [Timeline]
variables:
  - name: JWT_SECRET
    group: Server
    default: ""
    description: >-
      The key sign-ins are signed with. It is made on first start and kept in
      /app/data/secrets.env. Only set it to use your own.
  - name: ECH0_JWT_EXPIRES
    group: Server
    default: "900"
    description: >-
      How long a sign-in token lasts, in seconds.
  - name: ECH0_JWT_REFRESH_EXPIRES
    group: Server
    default: "604800"
    description: >-
      How long people stay signed in, in seconds (a week).
  - name: ECH0_LOG_LEVEL
    group: Server
    default: "info"
    description: >-
      How much goes in the log: debug, info, warn or error.
  - name: ECH0_UPLOAD_IMAGE_MAX_SIZE
    group: Uploads
    default: "20971520"
    description: >-
      The biggest image you can upload, in bytes (20 MiB).
  - name: ECH0_UPLOAD_AUDIO_MAX_SIZE
    group: Uploads
    default: "20971520"
    description: >-
      The biggest audio file, in bytes (20 MiB).
  - name: ECH0_UPLOAD_VIDEO_MAX_SIZE
    group: Uploads
    default: "67108864"
    description: >-
      The biggest video, in bytes (64 MiB).
  - name: ECH0_AUTH_WEBAUTHN_RP_ID
    group: Sign-in
    default: ""
    description: >-
      Your domain, like ech0.example.com, for passkeys. Only read on the
      first start; change it later in the admin panel.
  - name: ECH0_AUTH_WEBAUTHN_ORIGINS
    group: Sign-in
    default: ""
    description: >-
      Addresses passkeys may be used from, comma separated, like
      https://ech0.example.com. Only read on the first start.
  - name: ECH0_EGRESS_ALLOW_PRIVATE
    group: Server
    default: "false"
    description: >-
      Set to true so link cards and webhooks may reach addresses on your own
      network.
---

# Ech0

Ech0 is a small personal microblog. Post short thoughts, links, pictures and videos to your own timeline, and let others follow it by RSS, comment and react. It is light enough for a Raspberry Pi, and your posts stay on your server.

## Features

- Short posts in Markdown, with tags and search
- Images, audio and video, and cards for links and GitHub projects
- Comments, emoji reactions and an RSS feed
- Several accounts, passkeys and single sign-on (OAuth2, OIDC)
- Backups, exports and S3 storage
- An API, webhooks, an MCP server and an AI helper for your posts

## How to use

1. Open Ech0 from your dashboard.
2. Click Register and make your account. The first account is the owner.
3. Write your first post on the timeline.
4. Open the admin panel to set your site name, comments and storage.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6782`. There is no account yet: click Register, and the first account is the owner. The sign-in secret is made for you on first start and kept in `/DATA/AppData/ech0/data`, so you stay signed in across restarts. Most settings (comments, S3 storage, sign-in providers) are in Ech0's admin panel; the few others are in the Variables tab and are added in the app settings. It is ready in under a minute.
