---
site: https://docs.fluidd.xyz
source: https://github.com/fluidd-core/fluidd
screenshots: [Dashboard, Thermals, Bed mesh, Tool controls]
services:
  - { name: Web App, path: /, icon: monitor }
---

# Fluidd

Fluidd is a web interface for 3D printers that run Klipper. It talks to Moonraker on your printer, so you can watch and control prints, edit config files and see your camera from one page.

## Features

- Print status, temperatures and graphs
- Upload and start G-code files, with previews
- Edit Klipper config files in the browser
- Webcams, console, macros and bed mesh view
- Several printers from one page

## How to use

1. Your printer needs Klipper and Moonraker running.
2. Open Fluidd and add your printer with its address, like http://192.168.1.50.
3. If it can't connect, add the Fluidd address to cors_domains in Moonraker's settings.

## Before you install

Fluidd is only the web page: your browser connects straight to Moonraker on the printer, so nothing is stored on your ZimaOS and there are no settings here. Moonraker only answers web pages it trusts, so add http://[ZIMAOS-IP-ADDRESS]:7006 to cors_domains in the [authorization] section of moonraker.conf and restart Moonraker. Spoolman (also in IceStore) can track your filament from Fluidd.
