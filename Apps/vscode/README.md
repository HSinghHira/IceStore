---
name: VS Code
site: https://code.visualstudio.com/
source: https://github.com/linuxserver/docker-vscode
services:
  - { name: VS Code (HTTPS), path: /, icon: code }
variables:
  - name: TITLE
    group: Desktop
    default: Visual Studio Code
    description: >-
      The page title shown in your browser tab.
  - name: LC_ALL
    group: Desktop
    default: ""
    description: >-
      The language of the desktop, like fr_FR.UTF-8 or de_DE.UTF-8.
  - name: NO_DECOR
    group: Desktop
    default: ""
    description: >-
      Set to true to hide window borders, so VS Code fills the whole page.
  - name: NO_FULL
    group: Desktop
    default: ""
    description: >-
      Set to true to stop VS Code opening full screen.
  - name: DRINODE
    group: GPU
    default: ""
    description: >-
      The GPU to use for rendering, like /dev/dri/renderD128. Add the device
      to the container too.
  - name: DISABLE_IPV6
    group: Network
    default: ""
    description: >-
      Set to true if your network has no IPv6 and the stream won't start.
---

# VS Code

The real Visual Studio Code desktop app, running in a remote desktop session that streams to your browser. Your everyday code editor, with nothing to install locally.

## Features

- The genuine Visual Studio Code desktop app, not a limited web port
- Runs inside a full Selkies remote desktop, with a real terminal, git and any extension you like
- HTTPS out of the box with a self-signed certificate, plus a plain HTTP port for your own reverse proxy
- Optional GPU passthrough for smoother rendering
- Settings, extensions and projects survive restarts

## How to use

1. Open VS Code from your dashboard (it opens the HTTPS port, 6119).
2. Accept the self-signed certificate warning the first time.
3. Sign in with your `CUSTOM_USER` and `PASSWORD`.
4. Open folders, install extensions and use the terminal as usual.
5. Keep your projects in the home folder so they are saved.

## Before you install

Replace `CHANGEME_USERNAME` and `CHANGEME_PASSWORD` in `CUSTOM_USER` and `PASSWORD` with your own. This turns on a login screen so others on your network can't open your editor. Your browser will warn about the self-signed certificate; click through it. Port 6120 is plain HTTP for use behind your own reverse proxy. This app gives full desktop access with root inside the container, so don't expose it to the internet without a proxy that adds real authentication.
