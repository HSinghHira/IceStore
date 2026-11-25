---
site: https://ombi.io
source: https://github.com/Ombi-app/Ombi
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: BASE_URL
    group: Server
    default: ""
    description: >-
      Serve Ombi under a sub-path, like /ombi, for a reverse proxy.
---

# Ombi

Ombi gives the people who use your Plex, Emby or Jellyfin server a place to ask for new movies, shows and music. Requests can be approved by you or automatically, and are sent to Sonarr, Radarr and Lidarr.

## Features

- Users sign in with their Plex, Emby or Jellyfin account
- Movie, TV and music requests with approval and limits
- Sends requests to Sonarr, Radarr, Lidarr, CouchPotato and SickRage
- Issue reporting for broken files
- Notifications by email, Discord, Telegram, Pushover and more

## How to use

1. Open Ombi right away and follow the setup wizard.
2. Connect your media server, then add Sonarr, Radarr or Lidarr.
3. Share the address with your users.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6833 and finish the setup wizard; until then anyone on your network can. Reach your media server and Sonarr/Radarr at your ZimaOS IP with their ports. For a newer request app for Jellyfin and Plex, see Seerr. This image is built by linuxserver.io.
