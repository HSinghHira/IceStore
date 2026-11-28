---
site: https://github.com/Donkie/Spoolman
source: https://github.com/Donkie/Spoolman
screenshots: [Library, Dashboard, Label designer]
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API docs, path: /api/v1/docs, icon: code }
variables:
  - name: SPOOLMAN_DB_TYPE
    group: Database
    default: "sqlite"
    description: >-
      sqlite keeps the database in the data folder. postgres, mysql or cockroachdb use your own server with the settings below.
  - name: SPOOLMAN_DB_HOST
    group: Database
    default: ""
    description: >-
      Database server address, when not using sqlite.
  - name: SPOOLMAN_DB_PORT
    group: Database
    default: ""
    description: >-
      Database server port, when not using sqlite.
  - name: SPOOLMAN_DB_NAME
    group: Database
    default: ""
    description: >-
      Database name, when not using sqlite.
  - name: SPOOLMAN_DB_USERNAME
    group: Database
    default: ""
    description: >-
      Database user, when not using sqlite.
  - name: SPOOLMAN_DB_PASSWORD
    group: Database
    default: ""
    description: >-
      Database password, when not using sqlite.
  - name: SPOOLMAN_AUTOMATIC_BACKUP
    group: Database
    default: "TRUE"
    description: >-
      Back up the SQLite database every night into the data folder.
  - name: SPOOLMAN_BASE_PATH
    group: Web
    default: ""
    description: >-
      Serve Spoolman under a sub path, like /spoolman, behind a reverse proxy.
  - name: SPOOLMAN_CORS_ORIGIN
    group: Web
    default: ""
    description: >-
      Other web pages allowed to talk to Spoolman, like http://mainsail.local. Comma separated, with the scheme.
  - name: SPOOLMAN_ALLOWED_HOSTS
    group: Web
    default: ""
    description: >-
      Your domain names, when Spoolman sits behind a reverse proxy. Guards against DNS rebinding.
  - name: SPOOLMAN_LEGACY_CLIENT
    group: Web
    default: "FALSE"
    description: >-
      TRUE serves the older web client instead of the current one.
  - name: EXTERNAL_DB_URL
    group: Catalog
    default: "https://donkie.github.io/SpoolmanDB/"
    description: >-
      Filament catalog to load from. Blank turns the catalog off.
  - name: EXTERNAL_DB_SYNC_INTERVAL
    group: Catalog
    default: "3600"
    description: >-
      Seconds between catalog updates. 0 loads it only on start.
  - name: SPOOLMAN_METRICS_ENABLED
    group: Advanced
    default: "FALSE"
    description: >-
      TRUE collects Prometheus metrics at /metrics.
  - name: SPOOLMAN_UPDATE_CHECK
    group: Advanced
    default: "TRUE"
    description: >-
      Check GitHub for a newer Spoolman and show it in the footer.
  - name: SPOOLMAN_LOGGING_LEVEL
    group: Advanced
    default: "INFO"
    description: >-
      Log detail: DEBUG, INFO, WARNING, ERROR or CRITICAL.
---

# Spoolman

Spoolman keeps a list of your 3D printing filament: makers, filaments and every spool, with how much is left on each. Klipper (Moonraker), OctoPrint and Home Assistant can update it as you print.

## Features

- Spools, filaments and makers with colors, weights and prices
- Filament used is subtracted as you print
- Built-in catalog of common filaments (SpoolmanDB)
- QR code labels for each spool
- Works with Moonraker, Fluidd, Mainsail, OctoPrint and Home Assistant
- REST API and live updates over websockets

## How to use

1. Open Spoolman and add a maker and a filament, or pick one from the catalog.
2. Add your spools and print labels for them.
3. In Moonraker or OctoPrint, set the Spoolman server to http://[ZIMAOS-IP-ADDRESS]:6888.

## Before you install

Spoolman has no login: anyone on your network who opens http://[ZIMAOS-IP-ADDRESS]:6888 can change your spools, so keep it off the internet. Printers and Home Assistant must use your ZimaOS IP address, not localhost. A Fluidd or Mainsail page on another device needs its address in SPOOLMAN_CORS_ORIGIN. This IceStore image only adds one step to upstream's: it gives the data folder to your ZimaOS user so Spoolman can write its database there.
