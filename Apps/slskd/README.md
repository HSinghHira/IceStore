---
site: https://slskd.org/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API docs, path: /swagger, icon: code }
screenshots: [Search, Downloads, Search results]
variables:
  - name: SLSKD_USERNAME
    group: Web UI
    default: "slskd"
    description: >-
      The web UI user name.
  - name: SLSKD_JWT_KEY
    group: Web UI
    default: ""
    description: >-
      The key sign-ins are signed with. It is made on first start and kept in
      /app/secrets.env.
  - name: SLSKD_API_KEY
    group: Web UI
    default: ""
    description: >-
      An API key for other apps, at least 16 characters.
  - name: SLSKD_NO_AUTH
    group: Web UI
    default: "false"
    description: >-
      Set to true to turn off the web UI login. Only do this behind another
      sign-in.
  - name: SLSKD_URL_BASE
    group: Web UI
    default: "/"
    description: >-
      The path slskd is served under behind a reverse proxy, like /slskd.
  - name: SLSKD_REMOTE_CONFIGURATION
    group: Web UI
    default: "true"
    description: >-
      Lets you change the options file from the web UI (Options). Set to
      false to lock it.
  - name: SLSKD_SHARED_DIR
    group: Transfers
    default: "/music"
    description: >-
      The folders you share, separated by semicolons. /music is your
      /DATA/Media/Music folder.
  - name: SLSKD_SLSK_DESCRIPTION
    group: Soulseek
    default: ""
    description: >-
      The text on your Soulseek profile.
  - name: SLSKD_UPLOAD_SLOTS
    group: Transfers
    default: "10"
    description: >-
      How many uploads may run at once.
  - name: SLSKD_UPLOAD_SPEED_LIMIT
    group: Transfers
    default: ""
    description: >-
      The upload speed cap in KiB/s. Leave it out for no cap.
  - name: SLSKD_DOWNLOAD_SLOTS
    group: Transfers
    default: ""
    description: >-
      How many downloads may run at once.
  - name: SLSKD_DOWNLOAD_SPEED_LIMIT
    group: Transfers
    default: ""
    description: >-
      The download speed cap in KiB/s. Leave it out for no cap.
  - name: SLSKD_SHARE_FILTER
    group: Transfers
    default: ""
    description: >-
      Files not to share, as patterns separated by semicolons, like
      \.ini$;Thumbs.db$.
  - name: SLSKD_ROOMS
    group: Soulseek
    default: ""
    description: >-
      Chat rooms to join on start, separated by semicolons.
  - name: SLSKD_NO_VERSION_CHECK
    group: Server
    default: "false"
    description: >-
      Set to true to stop checking for new versions.
  - name: SLSKD_DEBUG
    group: Server
    default: "false"
    description: >-
      Set to true for more detail in the log.
---

# slskd

slskd connects your server to Soulseek, a peer-to-peer network for sharing music. Search for albums and tracks, download them straight to your server and share your own music back, all from a web page. It runs all the time, so downloads keep going while your computer is off.

## Features

- Search the Soulseek network and download whole folders
- Shares your music library with others, read-only
- Chat rooms and private messages
- Upload and download limits and speed caps
- An API, so apps like Lidarr helpers can use it

## How to use

1. Set your Soulseek user name and password before you install (any free name works).
2. Open slskd from your dashboard.
3. Sign in with the login from the app's logs (the box marked CREDENTIALS).
4. Type in Search and pick what to download.
5. Find your files in /DATA/Downloads/slskd.

## Before you install

Set `SLSKD_SLSK_USERNAME` and `SLSKD_SLSK_PASSWORD` to your Soulseek account; any free name works, since the account is made the first time it signs in. Without them slskd starts but can't join the network. The web UI login is `slskd` with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/slskd/app/.web_password`. Downloads go to `/DATA/Downloads/slskd`, and `/DATA/Media/Music` is shared read-only. Forward port 6780 on your router for faster transfers. Speed limits and the other settings are in the Variables tab and are added in the app settings, or in the web UI under Options.
