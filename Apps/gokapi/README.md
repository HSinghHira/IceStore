---
site: https://github.com/Forceu/Gokapi
source: https://github.com/Forceu/Gokapi
services:
  - { name: Web App, path: /admin, icon: globe }
  - { name: First-time Setup, path: /setup, icon: server }
screenshots: [Upload page, File Requests page, Status page, Users page]
variables:
  - name: GOKAPI_MAX_FILESIZE
    group: Uploads
    default: "102400"
    description: >-
      Largest file you can upload, in MB. 102400 is 100 GB. Add it before you
      finish the first setup.
  - name: GOKAPI_CHUNK_SIZE_MB
    group: Uploads
    default: "45"
    description: >-
      Size of each upload piece, in MB. Make it smaller if your reverse proxy
      blocks large requests. Add it before you finish the first setup.
  - name: GOKAPI_MIN_FREE_SPACE
    group: Uploads
    default: "400"
    description: >-
      Free disk space, in MB, needed before an upload is accepted.
  - name: GOKAPI_GUEST_UPLOAD_BY_DEFAULT
    group: File requests
    default: "false"
    description: >-
      Set to true to let all users create upload request links.
  - name: GOKAPI_MAX_FILES_GUESTUPLOAD
    group: File requests
    default: "100"
    description: >-
      Most files per upload request made by a user who is not an admin.
  - name: GOKAPI_MAX_SIZE_GUESTUPLOAD
    group: File requests
    default: "10240"
    description: >-
      Largest file, in MB, for upload requests made by a user who is not an
      admin.
  - name: GOKAPI_MIN_LENGTH_PASSWORD
    group: Accounts and access
    default: "8"
    description: >-
      Shortest password allowed. It cannot be lower than 6.
  - name: GOKAPI_DISABLE_API_MENU
    group: Accounts and access
    default: "false"
    description: >-
      Set to true to stop users who are not admins from making API keys.
  - name: GOKAPI_TRUSTED_PROXIES
    group: Reverse proxy
    default: "127.0.0.1"
    description: >-
      Addresses of your reverse proxy, separated by commas, so Gokapi sees the
      visitor's real address.
  - name: GOKAPI_USE_CLOUDFLARE
    group: Reverse proxy
    default: "false"
    description: >-
      Set to true if visitors reach Gokapi through Cloudflare.
  - name: GOKAPI_ENABLE_HOTLINK_VIDEOS
    group: Sharing
    default: "false"
    description: >-
      Set to true to allow direct links to videos. Playing a video once may count
      as several downloads.
  - name: GOKAPI_LOG_STDOUT
    group: Logs
    default: "false"
    description: >-
      Set to true to also show Gokapi's log entries in the app log.
  - name: GOKAPI_AWS_BUCKET
    group: S3 cloud storage
    default: ""
    description: >-
      Name of your S3 bucket. Leave the S3 settings out to keep files on your
      server.
  - name: GOKAPI_AWS_REGION
    group: S3 cloud storage
    default: ""
    description: >-
      Region of your S3 bucket, like eu-central-1.
  - name: GOKAPI_AWS_KEY
    group: S3 cloud storage
    default: ""
    description: >-
      Access key ID for your S3 storage.
  - name: GOKAPI_AWS_KEY_SECRET
    group: S3 cloud storage
    default: ""
    description: >-
      Secret access key for your S3 storage.
  - name: GOKAPI_AWS_ENDPOINT
    group: S3 cloud storage
    default: ""
    description: >-
      Server address for S3-compatible storage such as Backblaze B2. Leave it out
      for Amazon S3.
  - name: GOKAPI_AWS_PROXY_DOWNLOAD
    group: S3 cloud storage
    default: "false"
    description: >-
      Set to true to send S3 downloads through Gokapi instead of straight from
      the storage provider.
---

# Gokapi

Gokapi is a self-hosted file sharing app, an alternative to Firefox Send. Upload a file, send the link, and the file is removed after the number of downloads or days you choose.

## Features

- Links that expire after a set number of downloads or days
- Optional password for each shared file
- Upload request links, so other people can send files to you
- User accounts with permissions
- Identical files are stored only once
- Optional encryption, including end-to-end encryption
- Optional S3 cloud storage
- OpenID Connect sign-in and a REST API

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6874/setup` in your browser, using your server's IP address.
2. In the setup, change **Public facing URL** to `http://[ZIMAOS-IP-ADDRESS]:6874/`, with the same IP address.
3. Create your admin username and password, choose your options, and finish the setup.
4. Sign in at `http://[ZIMAOS-IP-ADDRESS]:6874/admin`.
5. Drag a file into the upload area, then copy its link and share it.

## Before you install

**Run the setup right after installing.** The setup page has no password, so anyone who can reach it can set up your Gokapi. Until you finish, the other pages say the server is in maintenance mode.

The **Public facing URL** is used to build your share links. It starts as `http://127.0.0.1:53842/`, which only works inside the app, so replace it with `http://[ZIMAOS-IP-ADDRESS]:6874/`, like `http://192.168.1.20:6874/`. Keep the database on SQLite and leave SSL off. If you turn on encryption, do not pick a "Key on startup" level: it asks for a password in a command line each time the app starts.

To share files outside your home network, put a reverse proxy with HTTPS in front of Gokapi and use that `https://` address as the Public facing URL. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default.
