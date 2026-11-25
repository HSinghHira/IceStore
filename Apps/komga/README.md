---
site: https://komga.org
source: https://github.com/gotson/komga
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: JAVA_TOOL_OPTIONS
    group: Server
    default: ""
    description: >-
      Java memory settings, like -Xmx1g to let Komga use up to 1 GB for
      big libraries (keep it below the app's 2G limit).
  - name: KOMGA_CORS_ALLOWED_ORIGINS
    group: Network
    default: ""
    description: >-
      Web addresses allowed to call the API from a browser, comma
      separated.
  - name: SERVER_SERVLET_CONTEXT_PATH
    group: Network
    default: ""
    description: >-
      Serve Komga under a sub-path, like /komga, for a reverse proxy.
---

# Komga

Komga organizes and serves your comics, manga, magazines and ebooks. Read them in the browser, sync them to reader apps over OPDS or the Kobo and KOReader integrations, and keep reading progress for every user.

## Features

- CBZ, CBR, PDF and EPUB, with a web reader for each
- Series, collections, read lists and metadata from ComicInfo.xml and EPUB files
- OPDS feeds and Kobo sync, plus apps like Tachiyomi/Mihon and Paperback
- Users with library access rights and age restrictions
- Duplicate page detection and metadata editing in the browser

## How to use

1. Open Komga right away and make the admin account.
2. Add a library and pick a folder under /DATA, like /DATA/Media/Comics.
3. Komga scans it; open a series and start reading.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6819 and make the admin account; until you do, anyone on your network can. Your ZimaOS storage is shared at the same path, so add libraries like /DATA/Media/Comics with one folder per series. More settings go in /DATA/AppData/komga/config/application.yml (see the Komga docs).
