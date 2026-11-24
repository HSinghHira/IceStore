---
site: https://kopia.io
source: https://github.com/kopia/kopia
services:
  - { name: Web UI, path: /, icon: globe }
variables:
  - name: KOPIA_SERVER_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The web page password. Made on first start and kept in
      .icestore-password in the config folder when left out.
  - name: KOPIA_PASSWORD
    group: Repository
    default: ""
    description: >-
      The repository password, to open the repository on start without the
      saved one. Leave it out unless you need it: the password you type in
      the web page is saved already. A wrong value here stops the server
      from opening the repository.
  - name: USER
    group: Repository
    default: zimaos
    description: >-
      The user name in each snapshot's owner (user@kopia). Change it before
      the first snapshot, or old snapshots show under the old name.
  - name: KOPIA_CHECK_FOR_UPDATES
    group: Server
    default: "false"
    description: >-
      Set to true to let Kopia check for new versions. IceStore updates the
      app for you.
  - name: KOPIA_UI_TITLE_PREFIX
    group: Server
    default: ""
    description: >-
      Text put before the page title, like "NAS: ", to tell several Kopia
      servers apart.
  - name: KOPIA_SERVER_CONTROL_USER
    group: Server
    default: server-control
    description: >-
      The user name for kopia server commands (status, refresh) run from
      another machine.
  - name: KOPIA_SERVER_CONTROL_PASSWORD
    group: Server
    default: ""
    description: >-
      The password for those server commands, used with
      KOPIA_SERVER_CONTROL_USER.
---

# Kopia

Kopia makes fast, encrypted backups of your folders. Each backup is a snapshot you can browse and restore, and files that did not change are stored only once. Keep the backups on another disk, a NAS or cloud storage like Backblaze B2, S3, Google Cloud, Azure, SFTP, WebDAV or any rclone remote.

## Features

- End-to-end encryption and compression
- Deduplication: unchanged data is stored once
- Snapshot schedules and keep rules (hourly, daily, weekly, ...)
- Browse snapshots and restore single files or whole folders
- Local disks, S3, B2, Azure, Google Cloud, SFTP, WebDAV and rclone

## How to use

1. Open Kopia and sign in with `admin` and the password from the CREDENTIALS box in the app's logs.
2. Create a repository: a folder like `/repository` (in `/DATA/AppData/kopia/repository`), a disk under `/media`, or cloud storage. Choose a repository password and write it down.
3. Add a snapshot of a folder under `/data`, like `/data/Documents`, and set its schedule.

## Before you install

The web page login is made on first start and shown in the app's logs, in the box marked CREDENTIALS; to pick your own password, add `KOPIA_SERVER_PASSWORD` in the app settings. The **repository password** is a different one: you choose it when you create the repository, and without it nobody, not even Kopia, can open your backups. Kopia saves it in `/DATA/AppData/kopia/config` so scheduled backups keep running after a restart; keep that folder private.

Your ZimaOS storage is shared read-only at `/data`. To restore, use **Restore** to a folder under `/media` or `/repository`, or download files from the snapshot browser. A backup on the same disk as the data does not protect you from a disk failure: use a second disk under `/media` or cloud storage for that. Mounting snapshots as folders needs FUSE, which this app does not set up.
