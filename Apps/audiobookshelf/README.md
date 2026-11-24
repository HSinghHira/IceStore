---
site: https://www.audiobookshelf.org
source: https://github.com/advplyr/audiobookshelf
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: ALLOW_CORS
    group: Server
    default: ""
    description: >-
      Set to 1 to let web pages on other sites call the API.
  - name: ALLOW_IFRAME
    group: Server
    default: ""
    description: >-
      Set to 1 to let other pages show Audiobookshelf in a frame, like a
      dashboard.
  - name: PODCAST_DOWNLOAD_TIMEOUT
    group: Podcasts
    default: "30000"
    description: >-
      How long to wait for a podcast episode to start downloading, in
      milliseconds.
  - name: MAX_FAILED_EPISODE_CHECKS
    group: Podcasts
    default: "24"
    description: >-
      How many failed checks in a row before automatic downloads stop for a
      podcast.
  - name: DISABLE_SSRF_REQUEST_FILTER
    group: Network
    default: ""
    description: >-
      Set to 1 to allow podcast feeds and covers on your own network, like a
      feed served by another app on your ZimaOS.
  - name: SSRF_REQUEST_FILTER_WHITELIST
    group: Network
    default: ""
    description: >-
      Host names on your network that feeds may come from, comma separated,
      instead of turning the filter off.
---

# Audiobookshelf

Audiobookshelf streams your audiobooks, ebooks and podcasts to the browser and to its Android and iOS apps. It remembers where every listener stopped, fetches covers and details, and downloads new podcast episodes for you.

## Features

- Streams every common audio format, with chapters
- Progress kept in sync across the browser and phone apps
- Downloads for offline listening in the apps
- Podcast search, subscriptions and automatic episode downloads
- Covers and details from Audible, Google Books and more
- Users with their own libraries and rights, and an ebook reader

## How to use

1. Open Audiobookshelf right away and make the root (admin) account.
2. Add a library and pick a folder under `/DATA`, like `/DATA/Media/Audiobooks`.
3. On your phone, install the Audiobookshelf app and connect to `http://[ZIMAOS-IP-ADDRESS]:6811`.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6811` and make the root account; until you do, anyone on your network can. Your ZimaOS storage is shared at the same path (`/DATA`), so pick library folders like `/DATA/Media/Audiobooks` (one folder per book) or `/DATA/Media/Podcasts`. The database is in `/DATA/AppData/audiobookshelf/config`; back it up, or turn on the app's own backups in **Settings → Backups**.
