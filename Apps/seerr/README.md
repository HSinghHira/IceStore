---
source: https://github.com/seerr-team/seerr
screenshots: [Discover, Settings]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: PORT
    group: Server
    default: "5055"
    description: >-
      The port inside the container. Change the published port instead.
  - name: API_KEY
    group: Server
    default: ""
    description: >-
      A fixed API key instead of the one Seerr makes.
---

# Seerr

Seerr lets your family and friends browse movies and shows and ask for the ones they want. Approved requests go straight to Sonarr and Radarr, and everyone sees when their request is ready to watch on Jellyfin, Plex or Emby. It is the merged successor of Overseerr and Jellyseerr.

## Features

- Sign in with your Jellyfin, Plex or Emby account
- Discover trending and upcoming movies and shows
- Requests sent to Sonarr and Radarr, with approval rules and limits
- Shows what is already in your library
- Notifications by email, Discord, Telegram, ntfy, Pushover and more

## How to use

1. Open Seerr right away and sign in with your Jellyfin, Plex or Emby admin account.
2. Pick the libraries to scan, then add Sonarr and Radarr with their API keys.
3. Import your media server's users and let them request.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6830 and finish the setup with your Jellyfin, Plex or Emby admin account; until then anyone on your network can. Seerr runs in its own container, so reach Jellyfin, Sonarr and Radarr at your ZimaOS IP with their ports, not localhost.
