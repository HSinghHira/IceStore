---
source: https://github.com/garethgeorge/backrest
services:
  - { name: Web App, path: /, icon: globe }
---

# Backrest

Backrest is a friendly web interface for restic, the fast and encrypted backup tool. Add a repository on another disk, a NAS or the cloud, plan what to back up and when, and browse snapshots to restore files in a few clicks.

## Features

- Encrypted, deduplicated restic backups to disks, SFTP, S3, B2, rclone remotes and more
- Plans with cron schedules and keep rules (hourly, daily, weekly)
- Browse snapshots and restore files or folders from the browser
- Prune and check jobs, with history and logs
- Notifications to Discord, Slack, Gotify, ntfy, Shoutrrr and more, plus hooks

## How to use

1. Open Backrest right away and set the instance name and your login.
2. Add a repository, like a folder under /media on a second disk, and choose its password.
3. Add a plan with folders under /DATA and a schedule.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6851 and set the instance name, user name and password; until then anyone on your network can. Your ZimaOS storage is shared at the same path (/DATA) and your other disks at /media. Repository passwords are saved in /DATA/AppData/backrest/config/config.json; write them down too, because without them no one can open the backups. A backup on the same disk does not protect you from a disk failure.
