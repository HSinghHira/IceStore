---
source: https://github.com/kieraneglin/pinchflat
screenshots: [Home, Media profile]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: BASIC_AUTH_USERNAME
    group: Sign-in
    default: ""
    description: >-
      A user name for the web page (with BASIC_AUTH_PASSWORD).
  - name: BASIC_AUTH_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The password for the web page.
  - name: UMASK
    group: Files
    default: "022"
    description: >-
      Permissions for new files, like 002 so your group can change them.
  - name: YT_DLP_WORKER_CONCURRENCY
    group: Downloads
    default: "2"
    description: >-
      How many videos download at the same time.
  - name: ENABLE_PROMETHEUS
    group: Server
    default: ""
    description: >-
      Set to true to serve metrics at /metrics.
  - name: EXPOSE_FEED_ENDPOINTS
    group: Server
    default: ""
    description: >-
      Set to true to keep the RSS feeds reachable without the login.
  - name: JOURNAL_MODE
    group: Server
    default: ""
    description: >-
      Set to delete if your config folder is on a network share.
---

# Pinchflat

Pinchflat watches YouTube channels and playlists and downloads new videos with yt-dlp, named and organized for Jellyfin, Plex or Kodi. Set up a media profile once, add your sources, and let it keep your library up to date.

## Features

- Channels and playlists checked on your schedule, with only new videos fetched
- Media profiles for quality, format, file names, subtitles and thumbnails
- Filters by title, length and date, and SponsorBlock to cut segments
- Media-center metadata (NFO files) and a podcast RSS feed per source
- Old videos removed after a set number of days if you like

## How to use

1. Open Pinchflat and make a Media Profile (quality and file names).
2. Add a Source with a channel or playlist link.
3. New videos appear in /DATA/Media/YouTube.

## Before you install

Pinchflat has no login unless you set BASIC_AUTH_USERNAME and BASIC_AUTH_PASSWORD in the app settings. Videos are saved to /DATA/Media/YouTube; point Jellyfin or Plex at that folder. If YouTube asks to confirm you are not a bot, add a cookies.txt file in /DATA/AppData/pinchflat/config/extras (see the Pinchflat wiki).
