---
site: https://dispatcharr.github.io/Dispatcharr-Docs/
source: https://github.com/Dispatcharr/Dispatcharr
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: DISPATCHARR_LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much detail goes in the log. One of debug, info, warning or error.
  - name: DISPATCHARR_SETUP_ALLOWED_IP
    group: Network
    default: ""
    description: >-
      Only needed to finish the first admin setup from a public IP address.
      Set it to the exact client IP shown on the setup page.
  - name: DISPATCHARR_TRUSTED_PROXIES
    group: Network
    default: ""
    description: >-
      Your reverse proxy's IP or CIDR, so Dispatcharr sees real client IPs.
      Set to none to ignore forwarded headers. Leave it out for a normal
      install.
---

# Dispatcharr

Dispatcharr is an open-source tool for managing IPTV streams, EPG data and VOD content. Think of it as the *arr family's IPTV cousin.

## Features

- Combine many IPTV/M3U and Xtream Codes sources in one place
- Stream proxy with live client management and automatic failover between backup sources
- HDHomeRun tuner emulation, so Plex, Emby and Jellyfin find it as a live TV source
- EPG matching and generation, with XMLTV, M3U, Xtream Codes and HDHomeRun output
- FFmpeg output profiles to transcode streams per client
- Video on Demand with IMDB/TMDB metadata
- Multi-user accounts with permissions and network access rules
- Plugin system for custom automations
- PostgreSQL and Redis inside the container, nothing extra to set up

## How to use

1. Open Dispatcharr from your dashboard.
2. Create your admin account on the setup page.
3. Add your IPTV sources under Settings, M3U & EPG Manager.
4. Create channels from your streams and match them to EPG data.
5. Add the M3U and XMLTV EPG links, or the HDHomeRun tuner, to Plex, Emby, Jellyfin or another player.

## Before you install

Nothing needs to be set first. Create your admin account from your home network right after install. If you miss the setup window, run `python manage.py createsuperuser` inside the container. Log level and proxy settings are in the Variables tab and are added in the app settings. The first start takes a little longer while the built-in database is set up.
