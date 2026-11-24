---
source: https://github.com/9001/copyparty
services:
  - { name: Files, path: /, icon: globe }
variables:
  - name: COPYPARTY_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The admin password to write to copyparty.conf on the first start.
      Made for you when left out. After the first start, change passwords
      in copyparty.conf instead. Avoid # in it.
  - name: LD_PRELOAD
    group: Speed
    default: ""
    description: >-
      Set to /usr/lib/libmimalloc-secure.so.2 for faster transfers, using
      about twice the memory.
  - name: DI_PREPARTY
    group: Advanced
    default: ""
    description: >-
      The name of a shell script in the config folder to run before
      copyparty starts, like preparty.sh.
---

# copyparty

copyparty turns your ZimaOS into a file server for every device. Upload huge files from the browser with resume and no size limit, search everything, play music and video, see thumbnails, and connect as a WebDAV drive.

## Features

- Fast, resumable uploads of any size, with duplicate detection
- Search by name, size, date and music tags
- Music player with playlists, and video and image thumbnails
- WebDAV for Windows, macOS, Linux and phones
- Accounts with per-folder rights, share links and upload-only folders
- Text editor, zip downloads and file renaming in the page

## How to use

1. Open copyparty and press **login**. Sign in with `admin` and the password from the CREDENTIALS box in the app's logs.
2. Browse your ZimaOS storage, or drop files on the page to upload.
3. Add accounts and folders in `/DATA/AppData/copyparty/config/copyparty.conf`, then restart the app.

## Before you install

copyparty shares your whole ZimaOS storage (`/DATA`), and the `admin` account can change and delete files. On first start, `copyparty.conf` is written with that one account and no access for anyone else (upstream's own default lets everyone read and write); the password is shown in the app's logs, in the box marked CREDENTIALS. From then on `copyparty.conf` is yours: add users, a public read-only folder or upload-only drop boxes there ([example](https://github.com/9001/copyparty/blob/hovudstraum/docs/example.conf); paths inside the container start with `/w`, which is `/DATA`). The first indexing of a large `/DATA` takes a while and keeps its database and thumbnails in `/DATA/AppData/copyparty/config/hist`.
