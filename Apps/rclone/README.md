---
site: https://rclone.org
source: https://github.com/rclone/rclone
services:
  - { name: Web GUI, path: /, icon: globe }
variables:
  - name: RCLONE_GUI_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The web GUI password. Made on first start and kept in
      .icestore-password in the config folder when left out.
  - name: RCLONE_CONFIG_PASS
    group: Config
    default: ""
    description: >-
      The password of an encrypted rclone.conf, so rclone can read it
      without asking.
  - name: RCLONE_TRANSFERS
    group: Transfers
    default: "4"
    description: >-
      How many files are copied at the same time.
  - name: RCLONE_CHECKERS
    group: Transfers
    default: "8"
    description: >-
      How many files are compared at the same time.
  - name: RCLONE_BWLIMIT
    group: Transfers
    default: ""
    description: >-
      A speed limit, like 10M for 10 MB/s, or a timetable like
      "08:00,1M 23:00,off".
  - name: RCLONE_LOG_LEVEL
    group: Logging
    default: NOTICE
    description: >-
      How much is written to the log: DEBUG, INFO, NOTICE or ERROR.
---

# Rclone

Rclone moves files between your ZimaOS and cloud storage: Google Drive, OneDrive, Dropbox, S3, Backblaze B2, pCloud, Mega, SFTP, WebDAV and over 70 more. This app runs Rclone's built-in web GUI, so you can set up remotes, browse them and start copies and syncs in the browser.

## Features

- Over 70 storage services, with encryption (crypt) on top of any
- Explorer to browse and transfer between remotes and your disks
- Copy, move and sync jobs with live progress
- Edit `rclone.conf`, logging and speed settings in the page

## How to use

1. Open Rclone. On the login page, type the API URL `http://[ZIMAOS-IP-ADDRESS]:6804` with your ZimaOS IP, and the user and password from the CREDENTIALS box in the app's logs.
2. Add a remote in **Remotes**.
3. In **Explorer**, copy or sync between the remote and `/data` (your ZimaOS storage).

## Before you install

Rclone uses two ports: the web GUI on `6803` and the API it calls on `6804`; both need the same login. The password is made on first start and shown in the app's logs, in the box marked CREDENTIALS; to pick your own, add `RCLONE_GUI_PASSWORD` in the app settings. Rclone can change and delete files in `/DATA` and `/media`, and `/DATA/AppData/rclone/config/rclone/rclone.conf` holds the keys to your cloud accounts: keep it private and back it up. Sign-ins that open a browser (Google Drive, OneDrive, Dropbox) are easiest with `rclone authorize` on your computer, then pasting the token. Mounting remotes as folders needs FUSE, which this app does not set up.
