---
name: RomSeek
source: https://github.com/Evident-Dev/romseek
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: QBIT_CATEGORY
    group: qBittorrent
    default: roms
    description: >-
      The qBittorrent category RomSeek's downloads get.
  - name: ROMM_PUBLIC_URL
    group: RomM
    default: ""
    description: >-
      The RomM address your users open, for direct game links.
  - name: ROMM_API_TOKEN
    group: RomM
    default: ""
    description: >-
      A RomM client API token with "View ROMs" and "View platforms" (and "Edit
      ROMs" for the admin game menu).
  - name: ROMM_FIRMWARE
    group: RomM
    default: ""
    description: >-
      RomM's bios folder. Left out, the bios folder next to ROMM_LIBRARY.
  - name: EXCLUDED_INDEXERS
    group: Search
    default: LimeTorrents
    description: >-
      Prowlarr indexers to hide, comma separated.
  - name: SCAN_STATE
    group: Virus scanning
    default: ""
    description: >-
      A file whose change time marks how far your virus scanner has checked.
      Left out, games are imported right away.
  - name: POLL_SECONDS
    group: Search
    default: "60"
    description: >-
      How often RomSeek checks qBittorrent for finished downloads.
  - name: UPLOAD_MAX_MB
    group: Search
    default: "1024"
    description: >-
      The largest BIOS file you can upload, in MB.
  - name: ADMIN_GROUPS
    group: Admin
    default: admins
    description: >-
      Groups (from a forward-auth proxy's Remote-Groups header) that get the
      admin game menu.
---

# RomSeek

RomSeek is a game download manager for RomM. It does for games what Sonarr and Radarr do for TV and movies: search your Prowlarr indexers, pick a game, and RomSeek sends it to qBittorrent. When the download finishes, it puts the game in your RomM library.

## Features

- Search every Prowlarr indexer for console games in one place
- Detects the system for each result from the release name and a 56,000-title game list
- Sends downloads to qBittorrent and imports finished games into RomM
- BIOS setup for the systems that need them
- Blocks Windows programs and junk files; optional ClamAV gate

## How to use

1. Set the Prowlarr, qBittorrent and RomM addresses and the Prowlarr key before you install.
2. Open RomSeek, search for a game and pick a result.
3. The finished game shows up in RomM.

## Before you install

You need RomM, Prowlarr and qBittorrent running first. Replace `CHANGEME-IP` with your ZimaOS IP in `PROWLARR_URL`, `QBIT_URL` and `ROMM_URL`, and paste Prowlarr's API key into `PROWLARR_KEY`; RomSeek won't start without it. RomSeek has no qBittorrent login, so in qBittorrent turn on **Bypass authentication for clients in whitelisted IP subnets** and add your Docker network.

`/DATA` is mounted at the same path, so point `QBIT_SAVE_PATH` and `ROMM_LIBRARY` at folders under `/DATA` and make sure qBittorrent sees them at the same paths. **RomSeek has no login of its own**: keep it on your home network or behind a reverse proxy with a login, and never open its port to the internet.
