---
site: https://poketube.fun
source: https://codeberg.org/ashleyirispuppy/poke
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Home, News, Music, Gaming]
variables:
  - name: POKE_BANNER
    group: Server
    default: welcome to poke!
    description: >-
      The short message shown on Poke's landing page.
  - name: POKE_ALWAYS_HTTPS
    group: Server
    default: "false"
    description: >-
      Set to true when you open Poke through your own https:// domain, so it
      always makes https links.
  - name: POKE_WORKERS
    group: Server
    default: ""
    description: >-
      How many Poke processes to run. Blank picks one for each CPU core.
      Lower it to use less memory.
  - name: POKE_CLUSTER
    group: Server
    default: "on"
    description: >-
      Set to off to run Poke as a single process.
  - name: POKE_MEDIA_PROXY
    group: Server
    default: https://image-proxy.poketube.fun
    description: >-
      The image proxy for thumbnails and banners. Point it at your own copy
      of Poke's image proxy if you run one.
  - name: POKE_YOUTUBE_PROXY
    group: YouTube
    default: ""
    description: >-
      A proxy for talking to YouTube, like http://user:pass@proxy:8080. Use
      it if YouTube blocks your address and videos stop playing.
  - name: YOUTUBE_SESSION_COOKIES
    group: YouTube
    default: ""
    description: >-
      YouTube cookies for the Invidious companion, if YouTube asks it to
      sign in. Most people leave this out.
  - name: CAPTIONS_ENABLED
    group: YouTube
    default: "true"
    description: >-
      Set to false to turn captions off, if YouTube blocks your address for
      fetching them.
---

# Poke

Poke is a YouTube front-end that keeps Google out of your browser. Watch videos, follow channels and listen to music without ads or tracking. This is Poke in a single container, with one port and one data folder. It brings its own Invidious, Invidious companion and PostgreSQL, so it does not lean on poketube.fun's video servers. Thumbnails and dislike counts still come from Poke's and Return YouTube Dislike's public services.

## Features

- Watch YouTube without ads, tracking or a Google account
- Videos stream through your own server
- Return YouTube Dislike counts built in
- Accounts to follow channels, without Google
- Captions, ambient mode and audio boost
- Installs like an app (PWA)

## How to use

1. Open Poke from your dashboard.
2. Search for a video or a channel.
3. Make an account to follow channels.

## Before you install

There is nothing to set: Poke works from whatever address you open it at, like `http://[ZIMAOS-IP-ADDRESS]:6133`. Every setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. If videos stop playing, YouTube may be blocking your address: add `POKE_YOUTUBE_PROXY`. The first start takes about four minutes while Invidious sets up its database.
