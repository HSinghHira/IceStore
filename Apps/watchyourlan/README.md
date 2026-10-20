---
name: WatchYourLAN
site: https://github.com/aceberg/WatchYourLAN
services:
  - { name: Web UI, path: /, icon: monitor }
variables:
  - name: TIMEOUT
    group: Scanning
    default: "120"
    description: >-
      Seconds between scans.
  - name: ARP_ARGS
    group: Scanning
    default: ""
    description: >-
      Extra options passed to arp-scan, for advanced users.
  - name: TRIM_HIST
    group: Scanning
    default: "48"
    description: >-
      How many hours of online and offline history to keep.
  - name: SHOUTRRR_URL
    group: Notifications
    default: ""
    description: >-
      A Shoutrrr link for alerts about new devices, like a Telegram, Discord
      or ntfy URL.
  - name: THEME
    group: Look
    default: sand
    description: >-
      The color theme of the web UI.
  - name: COLOR
    group: Look
    default: dark
    description: >-
      Light or dark mode. One of light or dark.
  - name: USE_DB
    group: Database
    default: sqlite
    description: >-
      The database to use. One of sqlite or postgres.
  - name: PG_CONNECT
    group: Database
    default: ""
    description: >-
      The PostgreSQL connection link when USE_DB is postgres, like
      postgres://user:pass@192.168.1.10:5432/wyl?sslmode=disable.
  - name: PROMETHEUS_ENABLE
    group: Monitoring
    default: "false"
    description: >-
      Set to true to share device data with Prometheus at /metrics.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much detail goes in the log. One of debug, info, warn or error.
---

# WatchYourLAN

WatchYourLAN is a lightweight network IP scanner with a clean web UI. It keeps track of every device that joins or leaves your local network.

## Features

- Uses arp-scan to list every device on your network, with vendor and hostname lookup
- Sends a notification when a new, unknown device shows up
- Keeps online and offline history for each device
- Can send data to InfluxDB2 or Prometheus for a Grafana dashboard
- SQLite storage by default, with optional PostgreSQL
- Uses host networking so arp-scan can see your real network

## How to use

1. Open WatchYourLAN from your dashboard.
2. Wait a minute for the first scan, then refresh.
3. Click a device to name it, tag it or see its history.
4. Set a Shoutrrr URL on the Config page to get alerts for new devices.

## Before you install

Replace `CHANGEME_IFACE` in `IFACES` with your real network interface name, like `eth0` or `enp3s0`. You can find it in your system's network settings. This app uses host networking, so port 6121 must be free on your server. Most settings can also be changed later on the Config page in the app.
