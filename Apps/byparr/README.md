---
source: https://github.com/ThePhaseless/Byparr
services:
  - { name: API docs, path: /docs, icon: code }
variables:
  - name: PROXY_SERVER
    group: Proxy
    default: ""
    description: >-
      A proxy for the hidden browser, like http://192.168.1.5:3128 or
      socks5://host:1080. Leave it out to use your own connection.
  - name: PROXY_USERNAME
    group: Proxy
    default: ""
    description: >-
      The user name for that proxy.
  - name: PROXY_PASSWORD
    group: Proxy
    default: ""
    description: >-
      The password for that proxy.
  - name: BROWSER_LOCALE
    group: Browser
    default: ""
    description: >-
      The browser's language, like en-US or de-DE. Leave it out to match
      the country of your internet address.
  - name: BROWSER_TIMEZONE
    group: Browser
    default: ""
    description: >-
      The browser's time zone, like Europe/Berlin. Leave it out to match
      your internet address.
  - name: OWUI_API_KEY
    group: Open WebUI
    default: ""
    description: >-
      A password for the /load web loader. Set the same value in Open
      WebUI's EXTERNAL_WEB_LOADER_API_KEY.
  - name: LOG_LEVEL
    group: Logs
    default: "info"
    description: >-
      debug, info, warning or error.
---

# Byparr

Byparr opens websites in a real, hidden browser to get past Cloudflare and similar anti-bot checks, then hands the page and its cookies to the app that asked. It speaks FlareSolverr's API, so Prowlarr, Jackett and the other *arr apps use it the same way. It can also fetch pages for Open WebUI.

## Features

- Drop-in replacement for FlareSolverr (same /v1 API)
- Works with Prowlarr, Jackett, Sonarr, Radarr and others
- Optional proxy, browser language and time zone
- Web loader for Open WebUI at /load
- No data to keep and nothing to set up

## How to use

1. In Prowlarr, go to Settings, Indexers, add a FlareSolverr proxy.
2. Set its host to `http://[ZIMAOS-IP-ADDRESS]:6199/` and give it a tag.
3. Add the same tag to the indexers that need it.

## Before you install

Nothing needs to be set first. The first start downloads a small location database before the port opens, so give it a minute. Byparr has no login: keep port 6199 on your home network. It greatly improves the odds of passing a challenge but doesn't guarantee it. A proxy and the other settings are in the Variables tab; add them in the app settings.
