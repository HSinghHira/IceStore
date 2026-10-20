---
site: https://searxng.org
services:
  - { name: Search, path: /, icon: search }
variables:
  - name: SEARXNG_VALKEY_URL
    group: Cache
    default: ""
    description: >-
      Connects SearXNG to the bundled Valkey cache. Set it to
      valkey://searxng-valkey:6379/0 to use it.
  - name: SEARXNG_LIMITER
    group: Security
    default: "false"
    description: >-
      Set to true to block bots and too many requests. Needs
      SEARXNG_VALKEY_URL.
  - name: SEARXNG_PUBLIC_INSTANCE
    group: Security
    default: "false"
    description: >-
      Set to true if strangers on the internet will use your instance. It
      turns on extra protection.
  - name: SEARXNG_SECRET
    group: Security
    default: ""
    description: >-
      The secret key SearXNG uses. Set a long random value; it overrides the
      one in settings.yml.
  - name: SEARXNG_IMAGE_PROXY
    group: Privacy
    default: "false"
    description: >-
      Set to true to load result images through your server, so image sites
      don't see your IP.
---

# SearXNG

SearXNG gathers results from many search engines without tracking you. It is a private, self-hosted alternative to Google or DuckDuckGo that you fully control.

## Features

- Results from dozens of search engines with no tracking, profiling or ads
- Configurable through settings.yml: turn engines on or off, tune ranking, change the look
- Valkey cache included
- Settings and cache kept in the app data folder

## How to use

1. Open SearXNG from your dashboard.
2. Start searching. No account is needed.
3. To change engines, ranking or the look, edit `settings.yml` in the config folder, then restart the app.

## Before you install

Nothing needs to be set first. To use SearXNG from other devices, change `localhost` in `SEARXNG_BASE_URL` to your server's IP. The Valkey cache container starts with SearXNG; add `SEARXNG_VALKEY_URL=valkey://searxng-valkey:6379/0` from the Variables tab to connect them. More settings live in `settings.yml` under `/DATA/AppData/searxng/config`.
