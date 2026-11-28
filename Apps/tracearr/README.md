---
screenshots: [Dashboard, Stats, Stream map, Automations]
site: https://tracearr.com
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: TRUST_PROXY
    group: Server
    default: ""
    description: >-
      Set to true behind one reverse proxy, so Tracearr sees real client
      addresses. Use 2 for two proxies, or list the proxy addresses.
  - name: CORS_ORIGIN
    group: Server
    default: "*"
    description: >-
      Other websites that may use a signed-in session, separated by commas,
      like https://dash.example.com. Not needed for Tracearr itself.
  - name: GZIP_ENABLED
    group: Server
    default: ""
    description: >-
      Set to true to compress answers, when no reverse proxy does it.
  - name: POLLER_ENABLED
    group: Monitoring
    default: "true"
    description: >-
      Set to false to stop checking your media servers for streams.
  - name: POLLER_INTERVAL
    group: Monitoring
    default: "15000"
    description: >-
      How often to check your media servers, in milliseconds.
  - name: ENCRYPTION_KEY
    group: Server
    default: ""
    description: >-
      Your own key for stored server tokens and notification secrets. Leave
      it out; Tracearr uses the secrets it made on first start.
  - name: MOBILE_BETA_MODE
    group: Mobile app
    default: ""
    description: >-
      Set to true for beta testing the mobile app: reusable pairing tokens
      that never expire. Not for everyday use.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much Tracearr logs: error, warn, info or debug.
---

# Tracearr

Tracearr watches your Plex, Jellyfin and Emby servers in real time. See who is streaming what, look back at play history and stats, and catch accounts that are shared with people outside your home. This is upstream's all-in-one image, with PostgreSQL and Redis inside.

## Features

- Live view of every stream, with quality and transcode details
- Play history and stats per user, title, device and day
- Account-sharing detection: impossible travel, too many streams, new devices and locations
- Rules that notify you or stop a stream
- Several servers of different kinds in one dashboard
- Notifications to Discord, ntfy and more, plus a mobile app

## How to use

1. Open Tracearr from your dashboard right after you install it.
2. Make the owner account.
3. Add your Plex, Jellyfin or Emby server with its address and token.
4. Watch the dashboard fill up as people play things.

## Before you install

Tracearr needs at least 3 GB of memory. It makes its own secrets on first start and keeps them in `/DATA/AppData/tracearr/tracearr`. Open `http://[ZIMAOS-IP-ADDRESS]:6757` right after install and make the owner account. More settings (reverse proxy, poll interval) are in the Variables tab; add them in the app settings. The first start takes about 2 minutes.
