---
site: https://lidarr.audio
source: https://github.com/Lidarr/Lidarr
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: UMASK
    group: Files
    default: "022"
    description: >-
      Permissions for new files, like 002 so your group can change them.
  - name: DOCKER_MODS
    group: Add-ons
    default: ""
    description: >-
      linuxserver mods to add on start, separated by |.
---

# Lidarr

Lidarr follows your favourite artists, grabs new albums through your Usenet or BitTorrent client, then tags, renames and files them into your music library for Navidrome, Jellyfin or Plex.

## Features

- Artists and albums from MusicBrainz, with release monitoring
- Quality profiles for FLAC, MP3 and more, with upgrades
- Works with qBittorrent, Transmission, SABnzbd, NZBGet and more
- Imports and tags existing music folders
- Renames and organizes files, and tells your media server to refresh

## How to use

1. Open Lidarr right away and set up the login it asks for (Forms login).
2. In Settings, Media Management, add your root folder, like /DATA/Media/Music.
3. Add your download client and indexers (or connect Prowlarr), then add what you want.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6829 and choose a login (Forms, with a user name and password). Your ZimaOS storage is shared at the same path (/DATA), so set your library to a folder like /DATA/Media/Music and keep downloads under /DATA too. IceStore's qBittorrent saves to /DATA/Downloads but calls it /downloads, so add a Remote Path Mapping in Lidarr (Settings, Download Clients) from /downloads/ to /DATA/Downloads/. Then Lidarr can move finished files without copying them. This image is built by linuxserver.io.
