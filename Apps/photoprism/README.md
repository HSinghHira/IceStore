---
site: https://www.photoprism.app
source: https://github.com/photoprism/photoprism
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: PHOTOPRISM_ADMIN_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The admin password (at least 8 characters). Made on first start
      and kept in the storage folder when left out.
  - name: PHOTOPRISM_AUTH_MODE
    group: Sign-in
    default: "password"
    description: >-
      Set to public to turn off sign-in (anyone on your network can see
      and change everything).
  - name: PHOTOPRISM_READONLY
    group: Library
    default: "false"
    description: >-
      Set to true to never change, upload to or delete from
      /DATA/Gallery.
  - name: PHOTOPRISM_ORIGINALS_LIMIT
    group: Library
    default: "5000"
    description: >-
      The largest file to index, in MB.
  - name: PHOTOPRISM_DISABLE_TENSORFLOW
    group: AI
    default: "false"
    description: >-
      Set to true to turn off labels, face recognition and NSFW checks
      (uses less CPU).
  - name: PHOTOPRISM_DISABLE_FACES
    group: AI
    default: "false"
    description: >-
      Set to true to turn off face recognition.
  - name: PHOTOPRISM_DETECT_NSFW
    group: AI
    default: "false"
    description: >-
      Set to true to flag photos that may be offensive.
  - name: PHOTOPRISM_DATABASE_SERVER
    group: Database
    default: ""
    description: >-
      Your MariaDB address when the driver is mysql, like
      192.168.1.20:3306.
  - name: PHOTOPRISM_DATABASE_NAME
    group: Database
    default: ""
    description: >-
      The MariaDB database name.
  - name: PHOTOPRISM_DATABASE_USER
    group: Database
    default: ""
    description: >-
      The MariaDB user.
  - name: PHOTOPRISM_DATABASE_PASSWORD
    group: Database
    default: ""
    description: >-
      The MariaDB password.
  - name: PHOTOPRISM_FFMPEG_ENCODER
    group: Video
    default: "software"
    description: >-
      The video encoder, like intel or vaapi when the device is added to
      the app.
  - name: PHOTOPRISM_WORKERS
    group: Performance
    default: ""
    description: >-
      How many CPU cores indexing may use.
---

# PhotoPrism

PhotoPrism organizes your photos and videos with AI: it recognizes faces, places and things, so you can search for "beach 2019" or a friend's name. It shows your pictures on a world map, plays Live Photos and videos, and shares albums with a link.

## Features

- Face recognition, object labels and color search
- World map and places from GPS data
- RAW, HEIC, Live Photos and videos, with duplicate detection
- Albums, favourites, archives and share links
- Sync with phones over WebDAV, and a progressive web app

## How to use

1. Open PhotoPrism and sign in as admin with the password from the CREDENTIALS box in the app's logs.
2. Press Library, then Index, to scan /DATA/Gallery.
3. Browse, search and make albums.

## Before you install

Before installing, set PHOTOPRISM_SITE_URL to your ZimaOS IP, like http://192.168.1.20:6858/; share links use it. PhotoPrism reads and adds photos in /DATA/Gallery (the same folder as ZimaOS Photos); set PHOTOPRISM_READONLY=true if it should never change that folder. The admin password is made on first start and shown in the app's logs, in the box marked CREDENTIALS. SQLite is fine for small and medium libraries; for very large ones use MariaDB. Indexing and face recognition use a lot of CPU the first time.
