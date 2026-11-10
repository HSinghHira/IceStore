---
name: Trackhop
site: https://trackhop.org
source: https://github.com/xlollx/Trackhop
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Syncs, A sync, Stats, Services]
variables:
  - name: SONGPORT_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The password for every page. Made on first start and kept in
      .icestore-password in the data folder when left out.
  - name: SONGPORT_USER
    group: Sign-in
    default: ""
    description: >-
      Only this user name may sign in. Left out, any name works.
  - name: SONGPORT_MULTIUSER
    group: Sign-in
    default: ""
    description: >-
      Set to true for separate accounts per person; the admin signs in with
      the password and invites the others.
  - name: SONGPORT_LOCALE
    group: Server
    default: ""
    description: >-
      The language of the engine's texts, like it, de or pt-BR.
  - name: SONGPORT_MUSIC
    group: Server
    default: ""
    description: >-
      A music folder for the Lyrics tool. Add it as a volume too (not
      read-only).
  - name: SONGPORT_UPDATE_CHECK
    group: Server
    default: ""
    description: >-
      Set to false to turn off the daily version check.
  - name: SPOTIFY_CLIENT_ID
    group: Service keys
    default: ""
    description: >-
      Your Spotify app's client ID (developer.spotify.com), instead of
      entering it in the page.
  - name: GOOGLE_CLIENT_ID
    group: Service keys
    default: ""
    description: >-
      A Google "Web application" OAuth client ID, for YouTube Music.
  - name: TIDAL_CLIENT_ID
    group: Service keys
    default: ""
    description: >-
      Your TIDAL app's client ID (developer.tidal.com).
  - name: DEEZER_APP_ID
    group: Service keys
    default: ""
    description: >-
      Your Deezer app's ID.
  - name: DEEZER_REDIRECT_URL
    group: Service keys
    default: ""
    description: >-
      Deezer's redirect address (must be https). Left out, it is
      SONGPORT_URL followed by /callback.
  - name: LASTFM_API_KEY
    group: Service keys
    default: ""
    description: >-
      Your Last.fm API key.
---

# Trackhop

Trackhop keeps playlists identical across Spotify, Apple Music, YouTube Music, Amazon Music, TIDAL, Deezer, SoundCloud, Navidrome, Jellyfin, Emby and Plex. Scheduled syncs run on your server, and tracks it can't find are easy to review. No Trackhop account: your sign-ins stay on your server.

## Features

- Two-way and one-way playlist syncs between music services and your own servers
- Scheduled syncs, with a report of what was matched
- Review and replace tracks that weren't found or can't be played
- Playlist files (CSV, M3U, iTunes XML) and Last.fm, ListenBrainz sources
- Optional separate accounts for each person

## How to use

1. Set `SONGPORT_URL` to your ZimaOS IP (or your https address) before you install.
2. Open Trackhop. Your browser asks for a user name and password: type any name and the password from the CREDENTIALS box in the app's logs.
3. Connect your music services, then create a sync.

## Before you install

**You must set `SONGPORT_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6715`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6715`, and always open Trackhop at exactly that address, because music service sign-ins come back to `SONGPORT_URL/callback`.

Spotify, YouTube Music and Deezer only allow https sign-ins: put Trackhop behind a reverse proxy with your own domain and set `SONGPORT_URL` to it, like `https://music.example.com`, then register that callback with each service. Navidrome, Jellyfin and Plex work without https.

This install's password is made on first start and shown in the app's logs, in the box marked CREDENTIALS; when the browser asks, type any user name and that password. To choose your own password, add `SONGPORT_PASSWORD` in the app settings. Service keys and more settings are in the Variables tab.
