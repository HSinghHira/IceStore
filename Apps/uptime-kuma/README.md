---
site: https://uptime.kuma.pet/
services:
  - { name: Dashboard, path: /, icon: monitor }
screenshots: [Dashboard, Light theme, Status page]
variables:
  - name: UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN
    group: Server
    default: "false"
    description: >-
      Set to true to let other sites show Uptime Kuma in a frame, like a
      dashboard that embeds your status page.
  - name: UPTIME_KUMA_WS_ORIGIN_CHECK
    group: Server
    default: "cors-like"
    description: >-
      Set to bypass if the page loads but never connects behind your
      reverse proxy.
  - name: NODE_EXTRA_CA_CERTS
    group: Server
    default: ""
    description: >-
      Path to an extra CA certificate file inside the container, for
      checking sites that use your own certificate authority.
---

# Uptime Kuma

Uptime Kuma checks your websites, servers and services every minute and alerts you the moment one stops answering. Share the results on a public status page.

## Features

- HTTP(s), keyword, JSON, TCP port, ping, DNS, push and many more kinds of checks
- Alerts by Telegram, Discord, Slack, email, ntfy, Gotify and 90+ other services
- Status pages with your own domain and logo
- Response-time charts and SSL certificate expiry warnings
- Maintenance windows, two-factor sign-in and many languages
- SQLite or a built-in MariaDB database

## How to use

1. Open Uptime Kuma from your dashboard.
2. Pick a database. SQLite is fine for most homes.
3. Make your admin account.
4. Click Add New Monitor, enter a website address and save.
5. Under Settings > Notifications, add where alerts should go.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6792`, pick a database (SQLite is fine) and make the admin account; until you do, anyone on your network who opens the page can. Monitors and history are kept in `/DATA/AppData/uptime-kuma/data`. Docker container monitors are not set up, because the Docker socket is not shared with the app. A few server settings are in the Variables tab and are added in the app settings. The first start takes about a minute.
