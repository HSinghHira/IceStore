---
source: https://github.com/sigoden/dufs
services:
  - { name: Files, path: /, icon: globe }
variables:
  - name: DUFS_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The admin password. Made on first start and kept in
      .icestore-password in the config folder when left out. Avoid : and @
      in it.
  - name: DUFS_AUTH
    group: Sign-in
    default: ""
    description: >-
      Your own account rules instead of the single admin, like
      admin:pass@/:rw|guest:pass@/Media|@/Public for an admin, a read-only
      guest and a public folder. When set, DUFS_USER and DUFS_PASSWORD are
      not used.
  - name: DUFS_ALLOW_UPLOAD
    group: Permissions
    default: ""
    description: >-
      With DUFS_ALLOW_ALL=false, set to true to allow uploads only.
  - name: DUFS_ALLOW_DELETE
    group: Permissions
    default: ""
    description: >-
      With DUFS_ALLOW_ALL=false, set to true to allow deleting files.
  - name: DUFS_ALLOW_SEARCH
    group: Permissions
    default: ""
    description: >-
      With DUFS_ALLOW_ALL=false, set to true to allow file name search.
  - name: DUFS_ALLOW_ARCHIVE
    group: Permissions
    default: ""
    description: >-
      With DUFS_ALLOW_ALL=false, set to true to allow downloading folders
      as zip files.
  - name: DUFS_ALLOW_SYMLINK
    group: Permissions
    default: ""
    description: >-
      Set to true to follow links that point outside the shared folder.
  - name: DUFS_ALLOW_HASH
    group: Permissions
    default: ""
    description: >-
      Set to true to answer ?hash with a file's SHA-256.
  - name: DUFS_SERVE_PATH
    group: Server
    default: /srv
    description: >-
      The folder inside the container to share, like /srv/Media for only
      /DATA/Media.
  - name: DUFS_HIDDEN
    group: Server
    default: ""
    description: >-
      Names to hide from listings, comma separated, like tmp,*.log,.git.
  - name: DUFS_PATH_PREFIX
    group: Server
    default: ""
    description: >-
      Serve under a sub-path, like /dufs, for a reverse proxy.
  - name: DUFS_ENABLE_CORS
    group: Server
    default: ""
    description: >-
      Set to true to let web pages on other sites call Dufs.
  - name: DUFS_COMPRESS
    group: Server
    default: low
    description: >-
      Zip compression for folder downloads: none, low, medium or high.
  - name: DUFS_LOG_FORMAT
    group: Server
    default: ""
    description: >-
      Your own access log line, like $remote_addr "$request" $status.
  - name: DUFS_RENDER_INDEX
    group: Website
    default: ""
    description: >-
      Set to true to show index.html for a folder instead of the file list,
      to host a static website.
  - name: DUFS_RENDER_TRY_INDEX
    group: Website
    default: ""
    description: >-
      Like DUFS_RENDER_INDEX, but shows the file list when there is no
      index.html.
  - name: DUFS_RENDER_SPA
    group: Website
    default: ""
    description: >-
      Set to true to host a single-page web app (unknown paths get
      index.html).
---

# Dufs

Dufs is a small, fast file server. Open it in a browser to browse, upload, search, edit and download your files, or connect to it as a WebDAV drive from your computer or phone.

## Features

- Browse, upload (drag and drop, resumable) and delete files in the browser
- Download whole folders as zip files
- Search file names
- Edit text files in the page
- WebDAV for Windows, macOS, Linux and phone file apps
- Accounts with read-only or read-write folders

## How to use

1. Open Dufs and sign in with `admin` and the password from the CREDENTIALS box in the app's logs.
2. Browse your ZimaOS storage, or drop files on the page to upload.
3. For a network drive, add a WebDAV location at `http://[ZIMAOS-IP-ADDRESS]:6801` with the same login.

## Before you install

Dufs shares your whole ZimaOS storage (`/DATA`) and the `admin` account can change and delete files. The password is made on first start and shown in the app's logs, in the box marked CREDENTIALS; it is kept in `/DATA/AppData/dufs/config/.icestore-password`. To pick your own, add `DUFS_PASSWORD` in the app settings. For several accounts, read-only guests or a public folder, set `DUFS_AUTH` (Variables tab). To share less, set `DUFS_SERVE_PATH` to a folder under `/srv`, like `/srv/Media`.
