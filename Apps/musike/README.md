---
source: https://github.com/Ernani1234/musike
services:
  - { name: Web Player, path: /, icon: globe }
screenshots: [Home, Album, Browse by genre, Cinema mode, Search a list, Your colors and layout]
variables:
  - name: YTDLP_EXTRA_ARGS
    group: YouTube
    default: ""
    description: >-
      Extra yt-dlp options. If YouTube asks you to sign in to prove you are
      not a bot, export your YouTube cookies to cookies.txt, put it in the
      data folder and set this to --cookies /data/cookies.txt.
  - name: MUSIKE_LANG
    group: YouTube
    default: "en"
    description: >-
      The YouTube Music language when the app does not send one, like en or
      pt. The app normally sends the language picked in Settings.
  - name: MUSIKE_CACHE_MAX_MB
    group: Video cache
    default: "2048"
    description: >-
      How many megabytes of HD music videos to keep. The least recently
      played go first.
---

# Musike

Musike is a personal music player for YouTube's catalog: any song or music video, as audio or video, with no ads, no account and no subscription. Your server fetches the music, so every device on your network can play it in the browser.

## Features

- Search YouTube Music for songs, videos and albums, or paste a YouTube link
- Browse by genre, open artists and play full albums in order
- Search a list: type several songs at once and play them all
- Queue, shuffle, repeat and autoplay radio
- Video mode with the official music video, cinema mode and HD
- Playlists, favorites and history, with backup to a file
- Dark and light themes, any accent color, installable as an app on phones

## How to use

1. Open Musike from your dashboard.
2. Search for a song, artist or album, or click Genres.
3. Press play. Add songs to a playlist or your favorites to keep them.

## Before you install

Set `MUSIKE_LOCATION` to your country, like `US` or `GB`. There is no account or password: everyone who can reach `http://[ZIMAOS-IP-ADDRESS]:6189` shares the same library, so keep it on your home network. Run it at home, not on a rented server: YouTube blocks data-center addresses. If YouTube still asks you to sign in, see `YTDLP_EXTRA_ARGS` in the Variables tab. More settings are in the Variables tab; add them in the app settings. yt-dlp can be updated from Musike's Settings page; an app update brings a fresh copy.
