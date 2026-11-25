---
site: https://termix.site
source: https://github.com/Termix-SSH/Termix
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: PORT
    group: Server
    default: "8080"
    description: >-
      The port inside the container. Change the published port instead.
---

# Termix

Termix is a server manager in your browser. Save your SSH hosts once, then open terminals in tabs and split panes, browse and edit files, run tunnels and watch server stats, from any device.

## Features

- SSH terminals with tabs and split screens
- File manager to upload, download and edit files over SSH
- SSH tunnels and port forwards that reconnect by themselves
- Host list with folders, tags, keys and saved passwords
- Server stats, users with roles and OIDC sign-in

## How to use

1. Open Termix right away and make your account. The first account is the admin.
2. Add a host with its address, user and password or key.
3. Open a terminal or the file manager.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6872 and make your account; the first account is the admin, so do it before anyone else, then turn off sign-ups in the admin settings. Saved hosts, keys and passwords are stored encrypted in /DATA/AppData/termix/data; keep that folder private.
