---
source: https://github.com/theashutoshn/Folbum
services:
  - { name: Folbum, path: /, icon: monitor }
variables:
  - name: DISK_GALLERY_ROOT
    group: Dashboard disk check
    default: ""
    description: >-
      The folder Folbum walks to compare files on disk with the Photos
      index, like /DATA/Gallery. /DATA is already shared read-only. Leave
      blank to turn the check off.
  - name: DISK_SOURCE_PATH
    group: Dashboard disk check
    default: ""
    description: >-
      The Photos source path exactly as Folbum shows it in Sync. The check
      only runs for this source. Leave blank to turn the check off.
---

# Folbum

Folbum makes an album in ZimaOS Photos for every folder that Photos has indexed. Each album is named after its folder and points at the original photos and videos, so nothing is copied or moved. Preview the changes, sync, and let it keep the albums up to date.

## Features

- One album per media folder, named after the folder (two folders with the same name are told apart by their paths)
- Preview what will be made or updated before you sync
- Repeat syncs add new files and keep what is already there
- Automatic sync on a timer
- Optional Dashboard check of files on disk against the Photos index

## How to use

1. Open Folbum from your dashboard and make your account.
2. In **Connection**, press **+** and enter your ZimaOS address and login. Tick **Keep NAS connected** to keep it after restarts.
3. In **Sync**, pick a Photos source, read the preview and run the sync.
4. Open ZimaOS Photos to see your new albums. Pick an automatic sync interval in Folbum to keep them current.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6799` and make your account (the password needs at least 12 characters); until you do, anyone on your network can. In **Connection**, use `http://[ZIMAOS-IP-ADDRESS]` as the NAS address: inside the container, `localhost` is Folbum itself. Folbum is an unofficial helper for ZimaOS Photos and needs Photos installed. Your account, settings and saved ZimaOS sign-in are in `/DATA/AppData/folbum/data`; keep that folder private. For the Dashboard disk check, add `DISK_GALLERY_ROOT` and `DISK_SOURCE_PATH` in the app settings (see Variables).
