---
site: https://cloudreve.org
services:
  - { name: Web App, path: /, icon: globe }
  - { name: WebDAV, path: /dav, icon: server }
screenshots: [Files, Desktop sync client, Mobile app, Cloudreve]
variables:
  - name: CR_SETTING_DEFAULT_siteName
    group: Site
    default: Cloudreve
    description: >-
      The name shown in the browser tab and in emails. Only used on the
      first start; change it later in the admin panel.
  - name: CR_SETTING_DEFAULT_register_enabled
    group: Sign-up and accounts
    default: "1"
    description: >-
      Set to 0 so nobody can sign up on their own after you; you add users
      in the admin panel. Only used on the first start. Make your own
      account first, or turn sign-up off later in the admin panel instead.
  - name: CR_SETTING_DEFAULT_email_active
    group: Sign-up and accounts
    default: "0"
    description: >-
      Set to 1 so new accounts must confirm their email. Set up email (SMTP)
      in the admin panel first. Only used on the first start.
  - name: CR_SETTING_DEFAULT_login_captcha
    group: Sign-up and accounts
    default: "0"
    description: >-
      Set to 1 to show a captcha on the sign-in page. Only used on the first
      start.
  - name: CR_SETTING_DEFAULT_reg_captcha
    group: Sign-up and accounts
    default: "0"
    description: >-
      Set to 1 to show a captcha on the sign-up page. Only used on the first
      start.
  - name: CR_CONF_System.LogLevel
    group: Logs
    default: info
    description: >-
      How much goes in the app log: debug, info, warning or error.
---

# Cloudreve

Cloudreve is an open-source, self-hosted file management and sharing platform - a private Dropbox or Google Drive that you fully control. This is Cloudreve in a single container, with PostgreSQL and Redis inside, one web port and one data folder.

## Features

- Drag-and-drop uploads, previews in the browser, and share links with passwords and expiry dates
- WebDAV, to use Cloudreve as a network drive on Windows, macOS or Linux
- Many storage backends - Local, S3-compatible (MinIO, Backblaze B2, Cloudflare R2, AWS S3), OneDrive and more - set per user group
- Remote downloads with the built-in aria2, straight to your storage
- Thumbnails for photos, videos and Office files (ffmpeg, libvips, LibreOffice and libraw are included)
- PostgreSQL and Redis inside, with nothing to set up

## How to use

1. Open Cloudreve from your dashboard.
2. Create an account. The first account becomes the admin.
3. Upload files and make folders.
4. Open the admin panel to add other storage, user groups and sharing rules.
5. Turn on WebDAV in your user settings to use it as a network drive.

## Before you install

Change `localhost` in `PUBLIC_URL` to your ZimaOS IP, like `http://192.168.1.20:6125`, so share links and WebDAV work on other devices. It is only used on the first start; after that, change the Site URL in the admin panel. The first start takes about a minute. Then open `http://your-zimaos-ip:6125` and sign up: the first account becomes the admin, so make yours before anyone else. The site name, sign-up switches and log level are in the Variables tab; add them in the app settings.
