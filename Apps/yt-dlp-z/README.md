---
name: yt-dlp-z
source: https://github.com/ZXY101/yt-dlp-z
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Download, Queue, Subscriptions, Options]
variables:
  - name: YTDLPZ_ADMIN_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      Sets the admin password up front, so nobody else can claim the install.
      Applied at every start; changing it signs everyone out.
  - name: YTDLPZ_SESSION_DAYS
    group: Sign-in
    default: "30"
    description: >-
      How many days a sign-in lasts.
  - name: YTDLPZ_AUTH_MODE
    group: Sign-in
    default: password
    description: >-
      Set to none to turn off the login. Only behind a proxy that handles
      login.
  - name: YTDLPZ_MAX_CONCURRENT_DOWNLOADS
    group: Downloads
    default: "3"
    description: >-
      How many downloads run at once. The Settings page can change it too.
  - name: YTDLPZ_MAX_CONCURRENT_RECORDINGS
    group: Downloads
    default: "2"
    description: >-
      How many live recordings run at once.
  - name: YTDLPZ_EXTRA_DOWNLOAD_ROOTS
    group: Downloads
    default: "[]"
    description: >-
      Extra folders downloads may use, as a JSON list, like ["/media/music"].
      Each also needs a volume in the app settings.
  - name: YTDLPZ_ALLOW_UNSAFE_OPTIONS
    group: Downloads
    default: "false"
    description: >-
      Set to true to allow the yt-dlp options yt-dlp-z blocks (like --exec).
      Only for trusted setups.
  - name: YTDLPZ_CHAT_FONT
    group: Downloads
    default: ""
    description: >-
      A font file for live chat overlays.
---

# yt-dlp-z

yt-dlp-z puts a web app in front of yt-dlp. Paste a link from your phone, pick a preset, and it downloads on your server. Point it at a YouTube channel and new uploads show up on their own; when the channel goes live, the stream is recorded from the start.

## Features

- Any site yt-dlp supports, with every yt-dlp option, grouped and searchable
- Presets, a link check before you download, and a live queue
- Channel and playlist watching, with live-stream recording from the start
- Jellyfin, Plex and Kodi friendly output, cookies, proxies and ntfy alerts
- An MCP server so AI agents can start downloads

## How to use

1. Open yt-dlp-z from your dashboard right after installing.
2. Choose the admin password and the download folder (`/downloads`).
3. Paste a link, pick a preset and download.
4. Find your files in the Files app under Downloads, yt-dlp-z.

## Before you install

The first person to open a fresh install chooses the admin password, so open `http://[ZIMAOS-IP-ADDRESS]:6705` right after installing, or set `YTDLPZ_ADMIN_PASSWORD` in the app settings first. Downloads go to `/DATA/Downloads/yt-dlp-z`; keep `/downloads` as the download folder in the setup. Most settings (presets, subscriptions, cookies, notifications) are made on the Settings page; the rest are in the Variables tab.
