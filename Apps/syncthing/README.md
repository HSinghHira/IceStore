---
site: https://syncthing.net/
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Folders and devices]
---

# Syncthing

Syncthing keeps the same folders on your computers, phone and ZimaOS, copying every change straight from device to device. Your files never pass through anyone else's server, and everything is encrypted on the way.

## Features

- Two-way sync between any number of devices
- Apps for Windows, macOS, Linux and Android
- Works on your home network and over the internet
- File versions, so a deleted or changed file can be got back
- Send-only, receive-only and untrusted (encrypted) devices
- Share any folder under /DATA

## How to use

1. Open Syncthing from your dashboard.
2. Set a user name and password under Actions > Settings > GUI.
3. Install Syncthing on your other device and add each device's ID on the other (Add Remote Device).
4. Add a folder, pick a path under /DATA, and share it with the other device.

## Before you install

The web page has no password at first: right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6793` and set a user name and password under Actions > Settings > GUI. Syncthing uses host networking, so other devices find it on your network and sync over port 22000 (TCP and UDP) and discovery on 21027 (UDP); nothing else on the server may use those ports. Your ZimaOS storage is shared at `/DATA`, so a folder like `/DATA/Documents` can be synced. Settings and this device's ID are kept in `/DATA/AppData/syncthing/syncthing/config`. Everything else is set in the web page. It is ready in a few seconds.
