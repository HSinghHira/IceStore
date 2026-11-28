---
site: https://github.com/seriousm4x/UpSnap
source: https://github.com/seriousm4x/UpSnap
screenshots: [Devices, Light theme, Settings]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: UPSNAP_SCAN_TIMEOUT
    group: Scan
    default: "500ms"
    description: >-
      How long the network scan waits for each device.
  - name: UPSNAP_PING_PRIVILEGED
    group: Scan
    default: "true"
    description: >-
      Use raw ping (needs the NET_RAW permission this app has). Set false for plain ping.
  - name: UPSNAP_WEBSITE_TITLE
    group: Web
    default: ""
    description: >-
      A custom title for the browser tab.
  - name: UPSNAP_LOG_LEVEL
    group: Advanced
    default: "INFO"
    description: >-
      Log detail: DEBUG, INFO, WARN, ERROR or OFF.
---

# UpSnap

UpSnap is a Wake on LAN dashboard. It shows which of your devices are on, wakes them with one click, and can turn them off or wake them on a schedule.

## Features

- One-click Wake on LAN for each device
- Live on/off status and open ports
- Scheduled wake and shutdown with cron
- Network scan to find devices
- Users with their own permissions, and 30+ languages

## How to use

1. Open UpSnap and make the admin account.
2. Add a device with its IP and MAC address, or set UPSNAP_SCAN_RANGE and scan your network.
3. Click a device to wake it.

## Before you install

UpSnap uses your ZimaOS host network, because Wake on LAN packets must go straight onto your home network; it listens on http://[ZIMAOS-IP-ADDRESS]:6894. The first person to open it makes the admin account, so do that right after installing. Each computer you want to wake needs Wake on LAN turned on in its BIOS and network adapter. To shut devices down from UpSnap, set a shutdown command for each device in its settings.
