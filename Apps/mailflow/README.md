---
site: https://mailflow.sh
services:
  - { name: Web App, path: /, icon: mail }
  - { name: CardDAV (contacts), path: /carddav, icon: server }
screenshots: [Default dark theme, Light theme, Compose window, Account management]
variables:
  - name: TRUST_PROXY_HOPS
    group: Server
    default: "1"
    description: >-
      How many proxies sit between the browser and MailFlow, counting its own
      gateway. Set to 2 if you put MailFlow behind your own reverse proxy, so
      sign-in limits and Login Activity see the real address.
  - name: LOG_LEVEL
    group: Server
    default: "info"
    description: >-
      How much the app log shows: error, warn, info or debug.
  - name: UPDATE_CHECK_DISABLED
    group: Server
    default: "false"
    description: >-
      Set to true to stop MailFlow from checking GitHub for new versions.
  - name: IMAP_MAX_PERSISTENT_PER_HOST
    group: Mail accounts
    default: "0"
    description: >-
      Most always-on connections MailFlow keeps to one mail server. Only set
      this if you have many accounts on one server that limits connections;
      the rest are checked on a timer. 0 means no limit.
  - name: ALLOW_PRIVATE_IMAP_HOSTS
    group: Mail accounts
    default: "false"
    description: >-
      Set to true to allow mail servers on your own network and any port, like
      Proton Mail Bridge.
  - name: IMAGE_CACHE_MAX_MB
    group: Mail accounts
    default: "512"
    description: >-
      Disk space in MB for images in emails that MailFlow keeps so it doesn't
      fetch them from the sender again.
  - name: MS_BUILTIN_APP
    group: Sign in with Microsoft
    default: "true"
    description: >-
      Personal Outlook.com and Hotmail accounts connect through MailFlow's own
      Microsoft app with no setup. Set to false to stop offering it. The
      switch under Settings, Email providers wins over this.
  - name: MS_CLIENT_ID
    group: Sign in with Microsoft
    default: ""
    description: >-
      The client ID of your own Microsoft Entra app. Needed for work and
      school accounts. You can also set this under Settings, Email providers.
  - name: MS_CLIENT_SECRET
    group: Sign in with Microsoft
    default: ""
    description: >-
      The client secret of your own Microsoft Entra app.
  - name: MS_TENANT_ID
    group: Sign in with Microsoft
    default: "common"
    description: >-
      Your Microsoft tenant ID, or common for any account.
  - name: MS_REDIRECT_URI
    group: Sign in with Microsoft
    default: ""
    description: >-
      The redirect address registered in your Microsoft app, like
      https://mail.example.com/oauth/microsoft/callback.
  - name: GOOGLE_CLIENT_ID
    group: Sign in with Google
    default: ""
    description: >-
      The client ID of your Google Cloud OAuth app, to connect Gmail and Google
      Workspace with OAuth instead of an app password. You can also set this
      under Settings, Email providers.
  - name: GOOGLE_CLIENT_SECRET
    group: Sign in with Google
    default: ""
    description: >-
      The client secret of your Google Cloud OAuth app.
  - name: GOOGLE_REDIRECT_URI
    group: Sign in with Google
    default: ""
    description: >-
      The redirect address registered in your Google app, like
      https://mail.example.com/oauth/google/callback.
  - name: VAPID_PUBLIC_KEY
    group: Push notifications
    default: ""
    description: >-
      Your own web push public key. Leave it out to use the keys made on
      first start. Set it together with VAPID_PRIVATE_KEY.
  - name: VAPID_PRIVATE_KEY
    group: Push notifications
    default: ""
    description: >-
      Your own web push private key. Only used together with
      VAPID_PUBLIC_KEY.
  - name: VAPID_SUBJECT
    group: Push notifications
    default: "mailto:admin@mailflow.local"
    description: >-
      Contact for the push services, like mailto:you@example.com. When
      PUBLIC_URL starts with https, that address is used instead.
---

# MailFlow

MailFlow is a self-hosted webmail client that puts all your email accounts, like Gmail, iCloud Mail, Outlook and any other IMAP account, into one fast, modern inbox. A modern alternative to Roundcube and SnappyMail. This is MailFlow in a single container, with one port and one data folder. Secret keys are made for you on first start.

## Features

- A unified inbox for many accounts, with live updates over IMAP IDLE
- Threaded conversations, fast full-text search and inbox rules
- Contacts with a built-in CardDAV server for your phone
- Several users, an admin panel, two-factor sign-in and OIDC single sign-on
- Themes, layouts and push notifications (keys made for you)
- PostgreSQL and Redis inside; the optional Caddy HTTPS service is left out

## How to use

1. Open MailFlow from your dashboard, or go to `http://[ZIMAOS-IP-ADDRESS]:6130`.
2. Create your account. The first account becomes the admin.
3. Add an email account. For Gmail and iCloud, use an app password from your Google or Apple account settings.

## Before you install

Change `localhost` in `PUBLIC_URL` to your ZimaOS IP, like `http://192.168.1.20:6130`, or to your domain. MailFlow opens from any address either way, but links in invite and password reset emails and single sign-on (OIDC) use this one. Create your account as soon as the app starts: the first account becomes the admin. Push notifications only work over HTTPS (or on the ZimaOS box itself), so put MailFlow behind a reverse proxy with a domain if you want them, and set `TRUST_PROXY_HOPS` to 2. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. The first start takes about 2 minutes. Back up the whole data folder: the keys in `data/state` are needed to read your stored mail passwords.
