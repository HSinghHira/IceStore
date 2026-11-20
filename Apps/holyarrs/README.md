---
site: https://holyarrs.com
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Explore with trailers, Home, Requests, Downloads]
variables:
  - name: UMASK
    group: Files
    default: "022"
    description: >-
      Permission bits new files leave out. Use 002 when a group must write
      too.
  - name: HOLYARRS_SAVE_PATH
    group: Files
    default: ""
    description: >-
      Your downloader's save folder as the downloader sees it, like
      /downloads. Sent with every download.
  - name: HOLYARRS_FOLLOW_LINKS
    group: Files
    default: ""
    description: >-
      Set to 1 to use video and music files that are symlinks.
  - name: HOLYARRS_READONLY_DOWNLOADERS
    group: Files
    default: ""
    description: >-
      Downloaders HolyArrs must never change, by id or address, separated by
      commas.
  - name: HOLYARRS_URL_BASE
    group: Server
    default: ""
    description: >-
      Serve HolyArrs under a path behind a reverse proxy, like /holyarrs.
  - name: HOLYARRS_ALLOWED_HOSTS
    group: Server
    default: ""
    description: >-
      Extra host names people use to reach HolyArrs, separated by commas,
      like holyarrs.example.com. IP addresses and localhost always work.
  - name: HOLYARRS_TRUSTED_PROXIES
    group: Server
    default: ""
    description: >-
      Your reverse proxy's address or network, so HolyArrs sees real client
      addresses.
  - name: HOLYARRS_LOW_MEMORY
    group: Server
    default: ""
    description: >-
      1 forces low-memory mode on, 0 forces it off. Left out, it turns on by
      itself on small machines.
  - name: HOLYARRS_SAFE_MODE
    group: Server
    default: ""
    description: >-
      Set to 1 to start only the core (sign-in, library, settings, backups)
      while you fix a problem. Remove it afterwards.
  - name: HOLYARRS_METADATA_MODE
    group: Server
    default: ""
    description: >-
      Where posters and details come from: full (the HolyArrs server), own
      (your own keys) or off.
  - name: HOLYARRS_OIDC_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to turn on single sign-on.
  - name: HOLYARRS_OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's exact https issuer, like https://id.example.com.
  - name: HOLYARRS_OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your provider.
  - name: HOLYARRS_OIDC_CLIENT_SECRET_FILE
    group: Sign in with OIDC
    default: ""
    description: >-
      A file holding the client secret, like /config/oidc-secret.txt. Leave
      it out for a public client.
  - name: HOLYARRS_OIDC_REDIRECT_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      Your address plus /api/v1/auth/oidc/callback, like
      https://holyarrs.example.com/api/v1/auth/oidc/callback.
  - name: HOLYARRS_OIDC_ALLOW_JOIN
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true so new people join as members who can only ask.
  - name: HOLYARRS_OIDC_ALLOW_LOCAL_NETWORK
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true when your provider is on your home network.
---

# HolyArrs

HolyArrs is one self-hosted app for your shows, movies and music. It does the jobs of Sonarr, Radarr, Lidarr, Bazarr, Prowlarr and Seerr in one small program: browse like a streaming app, ask for a title, and it finds it, downloads it and files it in your library.

## Features

- Explore page with posters, trailers and scores, like a streaming app
- Requests: family and friends ask, you approve, it shows up
- Searches your indexers (Sources), picks the best release with your rules and sends it to your downloader
- Renames and files downloads into your library and keeps subtitles
- Calendar, Health page and a red dot for anything that needs you
- Tells Plex, Jellyfin or Emby when something new lands; OIDC sign-in

## How to use

1. Open HolyArrs from your dashboard right after you install it.
2. Make the owner account. There is no default password.
3. Follow the short setup: library folders (`/movies`, `/tv`, `/music`), a downloader and a Source.
4. Search for a show or movie and press Request.

## Before you install

Your libraries come from `/DATA/Media/Movies`, `/DATA/Media/TV Shows` and `/DATA/Media/Music`, and downloads from `/DATA/Downloads`; change them if yours are elsewhere, and point your downloader at the same downloads folder. `PUID`/`PGID` must be able to write to those folders. Open `http://[ZIMAOS-IP-ADDRESS]:6754` right after install and make the owner account: whoever opens it first becomes the owner. More settings (OIDC, reverse proxy, save path) are in the Variables tab; add them in the app settings.
