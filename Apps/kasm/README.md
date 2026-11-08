---
site: https://www.kasmweb.com
source: https://github.com/linuxserver/docker-kasm
services:
  - { name: Workspaces, path: /, icon: monitor }
  - { name: Install Wizard, path: /, icon: package, port: 6194 }
screenshots: [Workspaces, Chrome session]
variables:
  - name: DOCKER_HUB_USERNAME
    group: Docker inside Kasm
    default: ""
    description: >-
      Your Docker Hub user name, to pull private workspace images or avoid
      Docker Hub's download limits.
  - name: DOCKER_HUB_PASSWORD
    group: Docker inside Kasm
    default: ""
    description: >-
      Your Docker Hub password or access token.
  - name: DOCKER_MTU
    group: Docker inside Kasm
    default: "1500"
    description: >-
      The network packet size for workspaces. Lower it, like 1400, when
      sessions can't load web pages over a VPN.
  - name: NVIDIA_VISIBLE_DEVICES
    group: Docker inside Kasm
    default: ""
    description: >-
      Set to all to give workspaces your NVIDIA GPU. Needs the NVIDIA
      Container Toolkit on ZimaOS.
---

# Kasm Workspaces

Kasm Workspaces streams full Linux desktops, web browsers and single apps to any web browser. Each session is a fresh, throw-away container, so you can open risky links or try software without touching your own computer. This is linuxserver's Kasm image: the whole Kasm platform runs inside one container, with its own Docker for the sessions.

## Features

- Ubuntu, Debian, Kali, Fedora and other desktops in the browser
- Isolated Chrome, Firefox, Brave, Tor Browser and more
- Apps like VS Code, GIMP, LibreOffice, Steam, Signal and Telegram
- A fresh, disposable session every time, or saved profiles
- Users, groups and session limits in an admin panel
- Sound, clipboard, file upload and download, and gamepads

## How to use

1. Open `https://[ZIMAOS-IP-ADDRESS]:6194` and finish the install wizard. Pick the passwords for `admin@kasm.local` and `user@kasm.local` there.
2. Open Kasm Workspaces from your dashboard and sign in.
3. Go to Workspaces, Registry, install a workspace, then launch it.

## Before you install

Kasm needs at least 4 GB of memory and 30 GB of disk, more for many workspaces. There are no passwords to set first: the install wizard at `https://[ZIMAOS-IP-ADDRESS]:6194` asks for them. Both ports use https with a self-signed certificate, so your browser warns once; click Advanced and continue. The wizard downloads Kasm and the workspaces you pick, which takes 10 minutes or more. To update Kasm later, update the app, then run the update in the wizard; a new image alone doesn't upgrade Kasm. The container runs privileged because Kasm starts its sessions with its own Docker. Docker Hub and GPU settings are in the Variables tab; add them in the app settings.
