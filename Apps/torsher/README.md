---
site: https://torsher.app
source: https://github.com/torsher-app/torsher
services:
  - { name: Control Panel, path: /panel/, icon: server }
  - { name: TV Showcase, path: /, icon: monitor }
screenshots: [TV showcase]
variables:
  - name: TMDB_ACCESS_TOKEN
    group: Catalog
    default: ""
    description: >-
      Your own TMDB API Read Access Token for the catalog, instead of the key
      built into the image. A key set in the panel wins over both.
  - name: TORSHER_SECRET
    group: Security
    default: ""
    description: >-
      The key that encrypts saved indexer keys and notification tokens.
      Leave it out: Torsher makes db/secret.key itself on first start. Keep
      that file with your backups.
  - name: TRUST_PROXY
    group: Security
    default: ""
    description: >-
      Only behind a reverse proxy: its address or subnet, like
      172.18.0.0/16, so sign-in limits see each person's own address.
  - name: HTTPS_PROXY
    group: Network
    default: ""
    description: >-
      A proxy for outgoing requests, like http://192.168.1.5:3128, until you
      set routes in the panel under Settings, Network.
  - name: LOG_LEVEL
    group: Logs
    default: "info"
    description: >-
      error, warn, info or debug.
---

# Torsher

Torsher is a media center in one container: a catalog for your TV, playback while the file downloads, your own library and new episodes that arrive on their own. It does the jobs of a torrent client, a media server, series and movie managers and a request app. It connects to a Torznab indexer you run, like Prowlarr or Jackett; it includes no sources.

## Features

- Watch right away: Torsher finds releases and plays while the file downloads
- Keep what you like in your library, laid out for Jellyfin, Plex and Kodi too
- Follow a series and new episodes download by themselves
- A TV showcase for LG webOS, Android TV and any browser, with profiles for the household
- Converts files the TV can't play on the fly, on the GPU if there is one
- Control panel for sources, storage, profiles, backups and notifications

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6197/panel/` and create the owner account.
2. Follow the setup wizard. Connect your indexer, like Prowlarr, with its address and API key.
3. Open `http://[ZIMAOS-IP-ADDRESS]:6197/` on your TV or in a browser, and connect it with the code under Profiles and devices.

## Before you install

Torsher needs a Torznab indexer, like Prowlarr or Jackett, installed first; add only the indexers you are allowed to use. There is no password to set: the first person to open `/panel/` creates the owner account. Downloads, the watch cache and your library all live in the data folder, so kept files are hard-linked instead of copied; `/DATA/Media` is available read-only at `/media/zimaos` for the movies and series you already have. Forward port 6198 (TCP and UDP) on your router for faster downloads. Hardware transcoding needs `/dev/dri` added as a device in the app settings. The other settings are in the Variables tab; most things are set in the control panel instead.
