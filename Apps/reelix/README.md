---
name: Reelix
source: https://github.com/demonzoned/Reelix
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Dashboard, Quality profiles, Custom formats, System status]
variables:
  - name: UMASK
    group: Files
    default: "022"
    description: >-
      The permissions of files Reelix creates.
---

# Reelix

Reelix is an all-in-one media manager: it finds, downloads, renames and organizes movies, series, books, audiobooks and music, the jobs of Radarr, Sonarr, Prowlarr, Lidarr and Readarr in one app written in Rust. It can migrate from those apps.

## Features

- Movies, series, books, audiobooks and music in one library
- Indexers, download clients, quality profiles and custom formats
- Requests, a calendar, wanted lists and a queue
- Media server and notification connections
- Migration from Radarr, Sonarr, Prowlarr, Lidarr and Readarr

## How to use

1. Open Reelix from your dashboard and make the admin account.
2. Add your indexers and download client under **Settings**.
3. Point your media folders at `/data/...` (your `/DATA`) and add movies and series.

## Before you install

Nothing to set first; the setup makes the admin account on the first visit. Your ZimaOS storage is mounted at `/data` inside (upstream's one mount for downloads and media, so hardlinks work): `/DATA/Media/Movies` is `/data/Media/Movies`. Give your download client the same mount so its paths match. Coming from Radarr or Sonarr, use **System › Migrate**.
