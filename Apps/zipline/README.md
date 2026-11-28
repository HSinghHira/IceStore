---
screenshots: [Home, Files, URLs, Metrics]
site: https://zipline.diced.sh/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: Dashboard, path: /dashboard, icon: server }
variables:
  - name: CORE_SECRET
    group: Server
    default: ""
    description: >-
      The key sign-ins are signed with, at least 32 characters. It is made on
      first start and kept in /data/secrets.env. Only set it to use your own.
  - name: CORE_TEMP_DIRECTORY
    group: Server
    default: ""
    description: >-
      Where uploads wait while they come in. Leave it out for the system
      temp folder.
  - name: DATASOURCE_TYPE
    group: Storage
    default: "local"
    description: >-
      local keeps files in /data/uploads; s3 keeps them in an S3 bucket.
  - name: DATASOURCE_LOCAL_DIRECTORY
    group: Storage
    default: "/data/uploads"
    description: >-
      Where files go with local storage.
  - name: DATASOURCE_S3_ENDPOINT
    group: Storage
    default: ""
    description: >-
      Your S3 server, like https://s3.example.com. Leave it out for AWS.
  - name: DATASOURCE_S3_BUCKET
    group: Storage
    default: ""
    description: >-
      The bucket name.
  - name: DATASOURCE_S3_REGION
    group: Storage
    default: ""
    description: >-
      The bucket's region, like us-east-1.
  - name: DATASOURCE_S3_ACCESS_KEY_ID
    group: Storage
    default: ""
    description: >-
      Your S3 access key.
  - name: DATASOURCE_S3_SECRET_ACCESS_KEY
    group: Storage
    default: ""
    description: >-
      Your S3 secret key.
  - name: DATASOURCE_S3_FORCE_PATH_STYLE
    group: Storage
    default: "false"
    description: >-
      Set to true for MinIO and other servers that need path-style links.
  - name: DATASOURCE_S3_SUBDIRECTORY
    group: Storage
    default: ""
    description: >-
      A folder inside the bucket to keep files in.
---

# Zipline

Zipline is your own place to upload files and screenshots and share them with a short link. Upload from the web page, or straight from ShareX, Flameshot and other screenshot tools. It also shortens links. The PostgreSQL database is built in, so it is one container with nothing else to set up.

## Features

- Upload files, images, videos and text, and share a link
- Ready-made setups for ShareX, Flameshot and other tools
- Short links for any URL
- Folders, tags, expiry dates, view limits and passwords on files
- Image thumbnails and compression
- Several users, invites, quotas and two-step sign-in
- Sign-in with Discord, GitHub, Google or OIDC

## How to use

1. Open Zipline from your dashboard.
2. Make the admin account on the first page.
3. Click Upload and drop a file, then copy its link.
4. To upload from ShareX or Flameshot, open your settings and download a ready-made setup.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6775`. There is no account yet: the first page asks you to make the admin account. The secret and the database password are made for you on first start and kept in `/DATA/AppData/zipline/data`, with your files in its `uploads` folder. S3 storage is in the Variables tab and is added in the app settings; almost everything else (sign-ups, file limits, sign-in providers, the look) is in Zipline itself under Server Settings. It is ready in about a minute.
