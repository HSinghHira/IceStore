---
site: https://prowlarr.com
source: https://github.com/Prowlarr/Prowlarr
screenshots: [Indexers]
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

# Prowlarr

Prowlarr manages your torrent trackers and Usenet indexers in one place. Add an indexer once and Prowlarr sends it to Sonarr, Radarr, Lidarr and your other apps, and keeps them in sync.

## Features

- Hundreds of built-in torrent and Usenet indexers
- Syncs indexers to Sonarr, Radarr, Lidarr, Readarr and more
- Search every indexer at once and send results to your download client
- Indexer health, stats and history
- FlareSolverr and proxy support for protected sites

## How to use

1. Open Prowlarr right away and set up the login it asks for (Forms login).
2. In Indexers, add the trackers and indexers you use.
3. In Settings, Apps, add Sonarr, Radarr or Lidarr with their API keys, and Prowlarr fills in their indexers for you.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6880 and choose a login (Forms, with a user name and password). To connect IceStore's Sonarr, Radarr or Lidarr, add each in Settings, Apps with Prowlarr Server http://[ZIMAOS-IP-ADDRESS]:6880, the app's own address (like http://[ZIMAOS-IP-ADDRESS]:6828 for Radarr) and its API key from its Settings, General page. Use your ZimaOS IP address, not localhost, because each app runs in its own container. This image is built by linuxserver.io.
