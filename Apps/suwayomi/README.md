---
site: https://suwayomi.org/
services:
  - { name: Web reader, path: /, icon: globe }
  - { name: GraphQL API, path: /api/graphql, icon: code }
variables:
  - name: AUTH_USERNAME
    group: Sign-in
    default: ""
    description: >-
      The user name for the login, when AUTH_MODE is not none.
  - name: AUTH_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The password for the login. Pick your own.
  - name: JWT_REFRESH_EXPIRY
    group: Sign-in
    default: "60d"
    description: >-
      How long you stay signed in with ui_login.
  - name: DOWNLOAD_AS_CBZ
    group: Library
    default: "false"
    description: >-
      Set to true to save chapters as CBZ files.
  - name: UPDATE_INTERVAL
    group: Library
    default: "12"
    description: >-
      How often to look for new chapters, in hours (at least 6, 0 turns it
      off).
  - name: MAX_SOURCES_IN_PARALLEL
    group: Library
    default: "6"
    description: >-
      How many sources may be checked or downloaded from at once (1 to 20).
  - name: EXTENSION_STORES
    group: Library
    default: "[]"
    description: >-
      More extension stores, as a list like ["https://.../index.min.json"].
  - name: BACKUP_TIME
    group: Backups
    default: "00:00"
    description: >-
      When the daily backup runs, as HH:MM.
  - name: BACKUP_INTERVAL
    group: Backups
    default: "1"
    description: >-
      Days between backups. 0 turns them off.
  - name: BACKUP_TTL
    group: Backups
    default: "14"
    description: >-
      How many days to keep backups.
  - name: WEB_UI_CHANNEL
    group: Web reader
    default: "stable"
    description: >-
      bundled, stable or preview.
  - name: WEB_UI_UPDATE_INTERVAL
    group: Web reader
    default: "23"
    description: >-
      Hours between web reader update checks. 0 turns it off.
  - name: FLARESOLVERR_ENABLED
    group: FlareSolverr
    default: "false"
    description: >-
      Set to true to get past Cloudflare checks with FlareSolverr.
  - name: FLARESOLVERR_URL
    group: FlareSolverr
    default: "http://localhost:8191"
    description: >-
      Your FlareSolverr address, like http://192.168.1.20:8191.
  - name: SOCKS_PROXY_ENABLED
    group: Proxy
    default: "false"
    description: >-
      Set to true to connect through a SOCKS5 proxy.
  - name: SOCKS_PROXY_HOST
    group: Proxy
    default: ""
    description: >-
      The proxy's address.
  - name: SOCKS_PROXY_PORT
    group: Proxy
    default: ""
    description: >-
      The proxy's port.
  - name: DEBUG
    group: Server
    default: "false"
    description: >-
      Set to true for more detail in the log.
---

# Suwayomi

Suwayomi is a manga reader that runs on your server, like Tachiyomi and Mihon. Add sources with extensions, follow series in your library, download chapters and read them in your browser or in apps that connect to it. New chapters are checked for on a schedule.

## Features

- Extensions for many manga sources, like Tachiyomi and Mihon
- Library with categories, read progress and history
- Chapter downloads, as images or CBZ files
- Web reader for phone and desktop
- Tracking with AniList, MyAnimeList and others
- Automatic library updates and backups

## How to use

1. Open Suwayomi from your dashboard.
2. Go to Extensions and install the sources you want.
3. Search a source in Browse and add a series to your library.
4. Open a chapter to read it, or download it.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6785`. There is no login by default, as upstream ships it: to add one, set `AUTH_MODE` to `ui_login` and add `AUTH_USERNAME` and `AUTH_PASSWORD` in the app settings. Downloads go to `/DATA/Media/Manga`, and the library and settings are in `/DATA/AppData/suwayomi/data`. Update times, backups, FlareSolverr and the other settings are in the Variables tab. The first start takes a few minutes while it downloads the web reader.
