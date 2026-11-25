---
site: https://transmissionbt.com
source: https://github.com/transmission/transmission
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: USER
    group: Sign-in
    default: ""
    description: >-
      A user name for the web interface (with PASS).
  - name: PASS
    group: Sign-in
    default: ""
    description: >-
      The password for the web interface.
  - name: WHITELIST
    group: Security
    default: ""
    description: >-
      IP addresses allowed to use the web interface, comma separated,
      like 192.168.*.*. Leave empty to allow all.
  - name: HOST_WHITELIST
    group: Security
    default: ""
    description: >-
      Domain names allowed to reach the web interface, when you use a
      reverse proxy.
  - name: TRANSMISSION_WEB_HOME
    group: Web
    default: ""
    description: >-
      Another web interface, like /themes/flood-for-transmission
      (installed with DOCKER_MODS).
  - name: DOCKER_MODS
    group: Add-ons
    default: ""
    description: >-
      linuxserver mods to add on start, like
      linuxserver/mods:transmission-floodui.
---

# Transmission

Transmission downloads torrents and magnet links on your ZimaOS with very little memory. Manage everything from its web page or from apps like Transmission Remote and Tremotesf.

## Features

- Torrents and magnet links, with file selection and priorities
- Speed limits and an alternative speed schedule
- Watch folder for .torrent files
- Encryption, DHT, PEX and local peer discovery
- Remote control from phone and desktop apps over RPC

## How to use

1. Open Transmission and add a torrent or magnet link.
2. Files land in /DATA/Downloads.

## Before you install

Transmission has no password until you set USER and PASS in the app settings. Downloads go to /DATA/Downloads, and .torrent files dropped into /DATA/Downloads/watch start by themselves. The peer port (6832, TCP and UDP) is set inside Transmission too, so keep it the same as the published port and forward it on your router for faster downloads. This image is built by linuxserver.io.
