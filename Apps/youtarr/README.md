---
site: https://youtarr.com
source: https://github.com/DialmasterOrg/Youtarr
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Home, Channels, Videos, Playlists]
variables:
  - name: AUTH_PRESET_USERNAME
    group: Sign-in
    default: admin
    description: >-
      The admin's user name, 1 to 32 characters.
  - name: AUTH_PRESET_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      Your own admin password, 8 to 64 characters. Leave it out to keep the
      one made on first start (shown in the CREDENTIALS box).
  - name: AUTH_ENABLED
    group: Sign-in
    default: "true"
    description: >-
      Set to false only when Youtarr sits behind another sign-in, like a VPN
      or a reverse proxy with its own login.
  - name: EXTERNAL_API_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to turn on the external API (it always needs an API key).
  - name: YOUTARR_COOKIES_FILE
    group: Features
    default: ""
    description: >-
      A YouTube cookies file Youtarr reads, like
      /app/config/cookies.external.txt. Put the file in
      /DATA/AppData/youtarr/data/youtarr/config and turn on Cookies in
      Settings.
  - name: TRUST_PROXY
    group: Server
    default: ""
    description: >-
      Set to 1 or your proxy's network when a reverse proxy sends the real
      client address; false when there is none.
  - name: OUTPUT_DIR_HEALTHCHECK_TIMEOUT
    group: Server
    default: ""
    description: >-
      How long the health check waits for the videos folder, in
      milliseconds. Raise it for a slow network share.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      warn, info or debug.
  - name: LOG_FILE_MAX_SIZE
    group: Logs
    default: ""
    description: >-
      The largest a log file gets before a new one starts.
  - name: LOG_FILE_MAX_COUNT
    group: Logs
    default: ""
    description: >-
      How many old log files to keep.
---

# Youtarr

Youtarr downloads videos from the YouTube channels you pick, on a schedule, and files them so Plex, Jellyfin, Emby or Kodi show them like TV shows. MariaDB is built in, so it is one container.

## Features

- Subscribe to channels and get new videos on a schedule
- Download single videos or playlists by pasting a link
- Pick the quality, and skip Shorts or live streams
- Saves thumbnails and info files your media server reads
- Refreshes your Plex library when new videos land
- Clean-up rules and notifications

## How to use

1. Open Youtarr from your dashboard.
2. Sign in as `admin` with the password from the app's logs (the box marked CREDENTIALS).
3. Go to Channels and add a channel link.
4. Videos land in `/DATA/Media/YouTube`. Add that folder to your media server as a TV or Other Videos library.

## Before you install

Videos go to `/DATA/Media/YouTube`; change the folder if you want them elsewhere. The admin password is made on first start and shown in the app's logs in the box marked CREDENTIALS; to use your own, set `AUTH_PRESET_PASSWORD` in the app settings. Open it from other devices at `http://[ZIMAOS-IP-ADDRESS]:6755`. More settings are in the Variables tab; add them in the app settings. The first start takes about 2 minutes.
