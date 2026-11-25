---
site: https://heimdall.site
source: https://github.com/linuxserver/Heimdall
services:
  - { name: Web App, path: /, icon: globe }
---

# Heimdall

Heimdall is a tidy start page with a tile for each of your web apps. Some tiles show live information, like downloads in progress or your Pi-hole stats, and a search bar sends you to your favourite search engine.

## Features

- Tiles with icons and colours for every app and link
- Enhanced tiles with live stats for over 100 apps
- Tags to group tiles, and several users
- Search bar for Google, DuckDuckGo, Bing and more
- Your own background image

## How to use

1. Open Heimdall and press Add an application.
2. Type the app's name; Heimdall finds its icon. Add its address and save.

## Before you install

Heimdall has no password at first, so anyone on your network can change your tiles; set a password for the admin user in Users. Add apps with your ZimaOS IP and their port. This image is built by linuxserver.io.
