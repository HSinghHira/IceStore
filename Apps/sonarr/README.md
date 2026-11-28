---
site: https://sonarr.tv
source: https://github.com/Sonarr/Sonarr
screenshots: [Series details]
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

# Sonarr

Sonarr watches for new episodes of the shows you follow, grabs them through your Usenet or BitTorrent client, then renames and files them into your library for Jellyfin, Plex or Emby.

## Features

- Calendar of upcoming episodes and automatic search when they air
- Quality profiles and upgrades to better releases
- Works with qBittorrent, Transmission, SABnzbd, NZBGet and more
- Indexers through Prowlarr or added by hand
- Renames and organizes files, and tells your media server to refresh

## How to use

1. Open Sonarr right away and set up the login it asks for (Forms login).
2. In Settings, Media Management, add your root folder, like /DATA/Media/TV.
3. Add your download client and indexers (or connect Prowlarr), then add what you want.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6827 and choose a login (Forms, with a user name and password). Your ZimaOS storage is shared at the same path (/DATA), so set your library to a folder like /DATA/Media/TV and keep downloads under /DATA too. IceStore's qBittorrent saves to /DATA/Downloads but calls it /downloads, so add a Remote Path Mapping in Sonarr (Settings, Download Clients) from /downloads/ to /DATA/Downloads/. Then Sonarr can move finished files without copying them. This image is built by linuxserver.io.
