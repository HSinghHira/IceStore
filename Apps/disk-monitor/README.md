---
name: Disk Monitor
site: https://github.com/isanto1306/Disk-Monitor
source: https://github.com/isanto1306/Disk-Monitor
services:
  - { name: Dashboard, path: /, icon: monitor }
screenshots: [Dashboard, Drive details, USB drive in standby, SMART check, Advanced SMART data, SMART history]
variables:
  - name: DISK_MONITOR_SESSION_SECRET
    group: Security
    default: ""
    description: >-
      The secret that keeps you signed in. It is made on first start and saved
      as .session_secret in the cache folder. Only set it if you want your own
      (at least 32 characters). Changing it signs everyone out.
  - name: DISK_MONITOR_SESSION_HTTPS_ONLY
    group: Security
    default: "false"
    description: >-
      Set to true only when you open Disk Monitor through HTTPS (a reverse
      proxy). With true, sign-in won't work over plain http.
---

# Disk Monitor

A dashboard for every disk in your ZimaOS box: SMART health, temperature, standby state, activity and RAID, with email alerts. It tries hard not to wake sleeping hard drives.

## Features

- Finds your HDDs, SSDs, NVMe and supported USB drives, with used and free space and mount points
- SMART health, temperature and detailed SMART values, with history charts
- Shows which disks are asleep and since when, and works with the ZimaOS standby timer
- Automatic SMART checks (off, 1, 2 or 3 times a day) that don't wake sleeping hard drives
- Email alerts for SMART problems, missing drives, RAID and temperature, plus scheduled status reports
- RAID overview with safe standby controls
- English, German, French, Portuguese and Spanish

## How to use

1. Open Disk Monitor from your dashboard, or go to `http://[ZIMAOS-IP-ADDRESS]:6170`.
2. Sign in as `admin` (or your `DISK_MONITOR_USERNAME`). The password is in `/DATA/AppData/disk-monitor/cache/password.txt` (open it with the Files app) and in the app log, unless you typed your own in `DISK_MONITOR_PASSWORD`.
3. Wait for the first full SMART check to finish. It runs once, on the first start only.
4. Set up email alerts, temperature warnings and automatic SMART checks in the settings. Email (SMTP) is set up in the app, not with variables.
5. For a USB hard drive, enter how long its enclosure takes to go to sleep in the USB auto-standby setting, so the sleep state shown is right.

## Before you install

Leave `DISK_MONITOR_PASSWORD` blank and the app makes its own random password on first start, saved in `password.txt` in the app's `cache` folder and shown in the app log; or type your own with at least 12 characters (shorter ones stop the app from starting). The session secret is made for you too. On the very first start the app checks every disk once, which wakes sleeping hard drives; after that it leaves them asleep. The app uses host networking and privileged mode because it reads SMART data and sends standby commands straight to your disks, so treat it like full access to your server: use it on your home network and don't open port 6170 to the internet. It runs on amd64 (Intel/AMD) only. Two more settings are in the Variables tab and are added in the app settings.
