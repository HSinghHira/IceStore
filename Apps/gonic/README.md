---
site: https://github.com/sentriz/gonic
source: https://github.com/sentriz/gonic
services:
  - { name: Admin page, path: /admin/, icon: server }
  - { name: Subsonic API, path: /rest/, icon: plug }
variables:
  - name: GONIC_SCAN_WATCHER_ENABLED
    group: Scanning
    default: "false"
    description: >-
      true watches the music folder and scans new files right away.
  - name: GONIC_SCAN_EMBEDDED_COVER_ENABLED
    group: Scanning
    default: "true"
    description: >-
      Read cover art embedded in audio files.
  - name: GONIC_EXCLUDE_PATTERN
    group: Scanning
    default: ""
    description: >-
      Files matching this regular expression are skipped, like @eaDir|[aA]rtwork.
  - name: GONIC_MULTI_VALUE_GENRE
    group: Scanning
    default: ""
    description: >-
      How to read several genres in one tag: multi, or delim <char> like "delim ;".
  - name: GONIC_MULTI_VALUE_ARTIST
    group: Scanning
    default: ""
    description: >-
      How to read several artists in one tag: multi, or delim <char>.
  - name: GONIC_MULTI_VALUE_ALBUM_ARTIST
    group: Scanning
    default: ""
    description: >-
      How to read several album artists in one tag: multi, or delim <char>.
  - name: GONIC_SCAN_NON_ADMIN_ENABLED
    group: Scanning
    default: "false"
    description: >-
      true lets users who aren't admins start a scan from their app.
  - name: GONIC_PODCAST_PURGE_AGE
    group: Podcasts
    default: "0"
    description: >-
      Delete podcast episodes not played for this many days. 0 keeps them.
  - name: GONIC_TRANSCODE_CACHE_SIZE
    group: Transcoding
    default: "0"
    description: >-
      Most space the transcode cache may use, in MB. 0 means no limit.
  - name: GONIC_TRANSCODE_EJECT_INTERVAL
    group: Transcoding
    default: "0"
    description: >-
      Minutes between cache clean-ups. 0 never cleans.
  - name: GONIC_JUKEBOX_ENABLED
    group: Jukebox
    default: "false"
    description: >-
      true lets Subsonic apps play music on the server's own speakers (needs a sound device).
  - name: GONIC_PROXY_PREFIX
    group: Web
    default: ""
    description: >-
      Serve gonic under a sub path, like /gonic, behind a reverse proxy.
  - name: GONIC_HTTP_LOG
    group: Advanced
    default: "true"
    description: >-
      Log every web request.
---

# gonic

gonic is a small, fast music streaming server. It reads your music folders and serves them over the Subsonic API, so you can listen with apps like Symfonium, DSub, Feishin, Supersonic or Sonixd.

## Features

- Browse by folders or by tags (artists, albums, genres)
- Transcoding on the fly with ffmpeg
- Podcasts, playlists, starred tracks and play counts
- Several users, Last.fm and ListenBrainz scrobbling
- Jukebox mode and internet radio

## How to use

1. Put your music in /DATA/Media/Music (or change the music folder).
2. Open the app's log and find the admin password under CREDENTIALS.
3. In your Subsonic app, add a server http://[ZIMAOS-IP-ADDRESS]:7005 with user admin and that password.

## Before you install

gonic reads your music from /DATA/Media/Music, read only; change that folder in the app settings if your music is elsewhere. Upstream starts with the login admin/admin; this IceStore image replaces that with a password made for each install, shown in the app's log under CREDENTIALS, or the one you type in GONIC_ADMIN_PASSWORD. The admin page at http://[ZIMAOS-IP-ADDRESS]:7005/admin/ is for users, scans and podcasts; you listen with a Subsonic app.
