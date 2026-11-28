---
site: https://github.com/Jackett/Jackett
source: https://github.com/Jackett/Jackett
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: RUN_OPTS
    group: Advanced
    default: ""
    description: >-
      Extra start options for Jackett, like --NoRestart.
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

# Jackett

Jackett is a proxy for your torrent trackers. It turns hundreds of tracker sites into one Torznab API that Sonarr, Radarr, Lidarr, qBittorrent search and other apps can use.

## Features

- Over 500 public and private trackers built in
- Torznab and TorrentPotato feeds for each tracker, or all at once
- Manual search across every tracker from the web page
- FlareSolverr and proxy support for protected sites

## How to use

1. Open Jackett and set an admin password at the bottom of the page.
2. Click Add indexer and pick your trackers.
3. Copy a tracker's Torznab feed and the API key into Sonarr or Radarr as a Torznab indexer.

## Before you install

Jackett starts with no password, so right after installing open http://[ZIMAOS-IP-ADDRESS]:6881 and set an admin password at the bottom of the page. When you copy a Torznab feed into Sonarr or Radarr, it must start with http://[ZIMAOS-IP-ADDRESS]:6881, not localhost, because each app runs in its own container. If you use Prowlarr, you usually don't need Jackett too. AUTO_UPDATE is false because IceStore ships each new Jackett version as a new image. This image is built by linuxserver.io.
