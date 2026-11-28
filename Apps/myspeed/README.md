---
site: https://myspeed.dev
source: https://github.com/gnmyt/myspeed
screenshots: [Statistics, Test history, Servers, Settings]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: DB_TYPE
    group: Database
    default: "sqlite"
    description: >-
      sqlite keeps the results in the data folder. mysql uses your own MySQL or MariaDB server with the settings below.
  - name: DB_HOST
    group: Database
    default: "localhost"
    description: >-
      MySQL server address, when DB_TYPE is mysql.
  - name: DB_NAME
    group: Database
    default: ""
    description: >-
      MySQL database name, when DB_TYPE is mysql.
  - name: DB_USER
    group: Database
    default: ""
    description: >-
      MySQL user, when DB_TYPE is mysql.
  - name: DB_PASS
    group: Database
    default: ""
    description: >-
      MySQL password, when DB_TYPE is mysql.
---

# MySpeed

MySpeed runs internet speed tests for you on a schedule and keeps the results for up to 30 days, with charts for download, upload and ping.

## Features

- Automatic tests on a schedule you pick (cron)
- Ookla, LibreSpeed and Cloudflare test servers
- Charts and averages for each day
- Alerts by Discord, Gotify, Telegram, email and more
- Prometheus and Home Assistant integration
- Optional password for the web page

## How to use

1. Open MySpeed and pick a test provider and server.
2. Set how often it should test, or start a test by hand.
3. Under Settings, set a password so others on your network can't change it.

## Before you install

MySpeed starts with no password, so right after installing open http://[ZIMAOS-IP-ADDRESS]:6889 and set one in the settings. Each test uses real internet traffic; on a metered plan, test less often. The test result is your server's connection speed, not the speed of the device you open MySpeed on.
