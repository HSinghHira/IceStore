---
name: kovi
source: https://git.sysmd.uk/mdaleo404/kovi
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: GOOGLE_BOOKS_API_KEY
    group: Covers
    default: ""
    description: >-
      A Google Books API key, for better cover and book lookups.
  - name: CALIBRE_COVER_RESOLVER
    group: Covers
    default: auto
    description: >-
      How covers are looked up with Calibre: auto, or off.
  - name: COVER_WORKER_CONCURRENCY
    group: Covers
    default: "2"
    description: >-
      How many covers are looked up at once (1 to 4).
  - name: MAX_FILE_SIZE_MB
    group: Uploads
    default: "100"
    description: >-
      The largest statistics file you can upload, in MB.
  - name: TRUST_PROXY
    group: Server
    default: "0"
    description: >-
      Set to 1 behind a reverse proxy, so kovi sees visitors' addresses.
---

# kovi

kovi turns your KOReader history into a reading dashboard: your library, progress, reading time by day and hour, highlights and covers. Import KOReader's statistics file, or let the kovi plugin on your e-reader send it on its own.

## Features

- Library with covers, progress and time spent per book
- Reading-time heatmaps and graphs
- Highlights and notes from your books
- A KOReader plugin that syncs with a one-time pairing code
- Exports and backups

## How to use

1. Open kovi from your dashboard.
2. Upload `statistics.sqlite3` from your KOReader, or install the kovi plugin on the e-reader and pair it.
3. Browse your books, reading time and highlights.

## Before you install

Nothing to set. **kovi has no sign-in**: anyone who can reach it can read your library and download backups, so keep it on your home network or behind a reverse proxy with a login. The KOReader plugin endpoints are protected separately, with one-time pairing codes and a token per device.
