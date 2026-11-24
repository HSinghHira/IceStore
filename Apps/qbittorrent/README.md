---
site: https://www.qbittorrent.org
source: https://github.com/qbittorrent/qBittorrent
services:
  - { name: Web UI, path: /, icon: globe }
variables:
  - name: DOCKER_MODS
    group: Add-ons
    default: ""
    description: >-
      linuxserver mods to add on start, like
      ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest for the VueTorrent web
      UI (then pick it in Options, Web UI, alternative web UI at
      /vuetorrent).
  - name: UMASK
    group: Files
    default: "022"
    description: >-
      Permissions for new files, like 002 so your group can change them.
---

# qBittorrent

qBittorrent downloads torrents and magnet links on your ZimaOS, so your computer does not have to stay on. Add and manage downloads from any browser.

## Features

- Torrents and magnet links, with sequential download and file priorities
- RSS feeds with download rules
- Built-in torrent search with plugins
- Speed limits and an alternative speed schedule
- Categories, tags and a watched folder

## How to use

1. Open qBittorrent. Sign in as `admin` with the temporary password in the app's logs.
2. Right away, set your own user name and password in **Tools → Options → Web UI**.
3. Add a torrent or magnet link. Files land in `/DATA/Downloads`.

## Before you install

The first password is a temporary one, written in the app's logs on every start until you set your own in **Tools → Options → Web UI**. The web UI port (`6805`) and the peer port (`6806`, TCP and UDP) are set inside qBittorrent too, so keep them the same as the published ports; to change one, change both the port and `WEBUI_PORT` or `TORRENTING_PORT`. Forward port `6806` on your router for faster downloads. This image is built by [linuxserver.io](https://docs.linuxserver.io/images/docker-qbittorrent/).
