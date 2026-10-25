---
site: https://github.com/dimartarmizi/OmniCloud
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: APP_MODE
    group: Sign-up and accounts
    default: local
    description: >-
      local is for one person and has no login. Set to hosted for accounts
      with an email and password; everyone gets their own clouds.
  - name: AUTH_SESSION_TTL_HOURS
    group: Sign-up and accounts
    default: "336"
    description: >-
      How long people stay signed in (hosted mode), in hours.
  - name: AUTH_COOKIE_NAME
    group: Sign-up and accounts
    default: omnicloud_session
    description: >-
      The name of the sign-in cookie (hosted mode).
  - name: GOOGLE_CLIENT_ID
    group: Google Drive
    default: ""
    description: >-
      The client ID of your Google Cloud OAuth app. Add
      <PUBLIC_URL>/api/accounts/google/callback as its redirect URI.
  - name: GOOGLE_CLIENT_SECRET
    group: Google Drive
    default: ""
    description: >-
      The client secret of your Google Cloud OAuth app.
  - name: GOOGLE_REDIRECT_URI
    group: Google Drive
    default: "<PUBLIC_URL>/api/accounts/google/callback"
    description: >-
      Only set it if your provider must call back to another address than
      PUBLIC_URL.
  - name: ONEDRIVE_CLIENT_ID
    group: OneDrive
    default: ""
    description: >-
      The application ID of your Microsoft Entra app. Add
      <PUBLIC_URL>/api/accounts/onedrive/callback as its redirect URI.
  - name: ONEDRIVE_CLIENT_SECRET
    group: OneDrive
    default: ""
    description: >-
      The client secret of your Microsoft Entra app.
  - name: ONEDRIVE_TENANT_ID
    group: OneDrive
    default: common
    description: >-
      Your Microsoft tenant, or common for personal and work accounts.
  - name: ONEDRIVE_REDIRECT_URI
    group: OneDrive
    default: "<PUBLIC_URL>/api/accounts/onedrive/callback"
    description: >-
      Only set it if Microsoft must call back to another address than
      PUBLIC_URL.
  - name: DROPBOX_CLIENT_ID
    group: Dropbox
    default: ""
    description: >-
      The app key of your Dropbox app. Add
      <PUBLIC_URL>/api/accounts/dropbox/callback as its redirect URI.
  - name: DROPBOX_CLIENT_SECRET
    group: Dropbox
    default: ""
    description: >-
      The app secret of your Dropbox app.
  - name: DROPBOX_REDIRECT_URI
    group: Dropbox
    default: "<PUBLIC_URL>/api/accounts/dropbox/callback"
    description: >-
      Only set it if Dropbox must call back to another address than
      PUBLIC_URL.
  - name: YANDEX_CLIENT_ID
    group: Yandex Disk
    default: ""
    description: >-
      The client ID of your Yandex OAuth app. Add
      <PUBLIC_URL>/api/accounts/yandex/callback as its redirect URI.
  - name: YANDEX_CLIENT_SECRET
    group: Yandex Disk
    default: ""
    description: >-
      The client secret of your Yandex OAuth app.
  - name: YANDEX_REDIRECT_URI
    group: Yandex Disk
    default: "<PUBLIC_URL>/api/accounts/yandex/callback"
    description: >-
      Only set it if Yandex must call back to another address than
      PUBLIC_URL.
  - name: SYNC_INTERVAL_MINUTES
    group: Sync
    default: "5"
    description: >-
      How often the file lists of your accounts are refreshed, in minutes.
---

# OmniCloud

OmniCloud brings Google Drive, OneDrive, Dropbox, Yandex Disk, MEGA, pCloud and S3-compatible storage into one file workspace, so you don't need a separate app for every provider. This is OmniCloud in a single container, built from the upstream source, with the API and the web app behind one port and one data folder. The encryption and sign-in keys are made for you on first start.

## Features

- Browse, upload, download, rename and delete files across every connected provider from one file explorer
- Home, My Drive, Recent, Starred, Shared with Me and Quota views
- Live upload progress, drag-and-drop and folder uploads
- Automatic choice of which account gets each upload (round robin, weighted, least used, most free or manual priority)
- Background sync keeps the file list of every account current
- Local mode for one person, or hosted mode with logins for many

## How to use

1. Open OmniCloud from your dashboard.
2. In local mode (the default) there is no login. Set `APP_MODE` to `hosted` to make accounts with a login.
3. Go to **Quota** to add a cloud account.
4. MEGA, pCloud and S3 storage ask for their login right there. Google Drive, OneDrive, Dropbox and Yandex Disk need an app from that provider first (see the Variables tab and upstream's [provider setup guide](https://github.com/dimartarmizi/OmniCloud/blob/main/docs/provider-setup.md)).
5. Open **My Drive** to browse, upload and download across every connected account.

## Before you install

`PUBLIC_URL` starts as `http://localhost:6154`. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6154`; the sign-in callbacks for Google, OneDrive, Dropbox and Yandex are made from it (`<PUBLIC_URL>/api/accounts/google/callback` and so on), and some providers only accept an `https://` address or `localhost`. Local mode has no login, so anyone who can open the page can use your clouds; add `APP_MODE=hosted` for logins. The first start takes about a minute. The provider client IDs and secrets are in the Variables tab; add them in the app settings.
