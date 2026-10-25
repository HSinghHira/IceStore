---
site: https://github.com/ulsklyc/yuvomi
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Dashboard, Calendar, Modules]
variables:
  - name: BASE_URL
    group: Server
    default: ""
    description: >-
      The address you open Yuvomi at, like http://192.168.1.20:6161. Needed
      for links in password-reset and invite emails.
  - name: SESSION_SECURE
    group: Server
    default: "false"
    description: >-
      Set to true only when Yuvomi is behind an HTTPS reverse proxy.
  - name: TRUST_PROXY
    group: Server
    default: "1"
    description: >-
      Which proxies to trust for the visitor's address: 1 (one proxy),
      loopback (no proxy) or a subnet like 172.16.0.0/12.
  - name: LOG_LEVEL
    group: Server
    default: info
    description: >-
      How much the app logs: debug, info, warn or error.
  - name: MAX_UPLOAD_MB
    group: Server
    default: "5"
    description: >-
      The largest file people can upload, in megabytes (1 to 100).
  - name: SESSION_SECRET
    group: Keys
    default: ""
    description: >-
      Signs logins. Leave it out: one is made on first start and kept in
      .session_secret in the data folder. Changing it signs everyone out.
  - name: DB_ENCRYPTION_KEY
    group: Keys
    default: ""
    description: >-
      Encrypts the database. Leave it out: one is made on first start and
      kept in .db_encryption_key in the data folder. Never change it after
      the first start, or the database can't be opened.
  - name: EMAIL_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Turns on password reset by
      email and email notifications.
  - name: EMAIL_SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port.
  - name: EMAIL_SMTP_SECURE
    group: Email (SMTP)
    default: starttls
    description: >-
      How to connect: ssl (port 465), starttls (port 587) or none.
  - name: EMAIL_SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: EMAIL_SMTP_PASS
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: EMAIL_FROM_ADDRESS
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address on emails, like yuvomi@example.com.
  - name: EMAIL_FROM_NAME
    group: Email (SMTP)
    default: Yuvomi
    description: >-
      The sender name on emails.
  - name: OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      Your sign-in provider's address, like
      https://auth.example.com/application/o/yuvomi/. All four OIDC values
      are needed.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your sign-in provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your sign-in provider.
  - name: OIDC_REDIRECT_URI
    group: Sign in with OIDC
    default: ""
    description: >-
      Your Yuvomi address plus /api/v1/auth/oidc/callback. Add the same
      address at your provider.
  - name: OIDC_ALLOW_SIGNUP
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false so OIDC sign-in never makes new accounts.
  - name: AUTH_ALLOW_PASSWORD_LOGIN
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false to make OIDC the only way in, once an admin account is
      linked to it.
  - name: GOOGLE_CLIENT_ID
    group: Calendars
    default: ""
    description: >-
      Google OAuth client ID, for Google Calendar sync.
  - name: GOOGLE_CLIENT_SECRET
    group: Calendars
    default: ""
    description: >-
      Google OAuth client secret.
  - name: GOOGLE_REDIRECT_URI
    group: Calendars
    default: ""
    description: >-
      Your Yuvomi address plus /api/v1/calendar/google/callback, exactly as
      registered at Google.
  - name: MS_CLIENT_ID
    group: Calendars
    default: ""
    description: >-
      Microsoft app client ID, to push events to Outlook.
  - name: MS_CLIENT_SECRET
    group: Calendars
    default: ""
    description: >-
      Microsoft app client secret.
  - name: MS_REDIRECT_URI
    group: Calendars
    default: ""
    description: >-
      Your Yuvomi address plus /api/v1/calendar/outlook/callback.
  - name: APPLE_CALDAV_URL
    group: Calendars
    default: https://caldav.icloud.com
    description: >-
      The CalDAV server for Apple Calendar.
  - name: APPLE_USERNAME
    group: Calendars
    default: ""
    description: >-
      Your Apple ID email, for Apple Calendar sync.
  - name: APPLE_APP_SPECIFIC_PASSWORD
    group: Calendars
    default: ""
    description: >-
      An app-specific password from appleid.apple.com.
  - name: SYNC_INTERVAL_MINUTES
    group: Calendars
    default: "15"
    description: >-
      How often calendars and contacts sync, in minutes.
  - name: ICS_SUBSCRIPTION_ALLOW_PRIVATE_NETWORK
    group: Calendars
    default: "false"
    description: >-
      Set to true to allow calendar feeds from your home network (Sonarr,
      Home Assistant...).
  - name: WEATHER_LAT
    group: Weather
    default: ""
    description: >-
      Your latitude for the weather widget (Open-Meteo, no key needed), like
      52.52.
  - name: WEATHER_LON
    group: Weather
    default: ""
    description: >-
      Your longitude, like 13.41.
  - name: WEATHER_CITY
    group: Weather
    default: ""
    description: >-
      The city name shown on the widget.
  - name: WEATHER_UNITS
    group: Weather
    default: metric
    description: >-
      metric or imperial.
  - name: BACKUP_ENABLED
    group: Backups
    default: "true"
    description: >-
      Set to false to turn off scheduled backups.
  - name: BACKUP_SCHEDULE
    group: Backups
    default: 0 2 * * *
    description: >-
      When backups run, as a cron line. The default is 2 AM every day.
  - name: BACKUP_KEEP
    group: Backups
    default: "7"
    description: >-
      How many backups to keep.
  - name: WEBDAV_BACKUP_ENABLED
    group: Backups
    default: "false"
    description: >-
      Set to true to also upload each backup to a WebDAV server (Nextcloud,
      Hetzner Storage Box...).
  - name: WEBDAV_BACKUP_URL
    group: Backups
    default: ""
    description: >-
      The WebDAV address, like https://cloud.example.com/remote.php/dav/files/you/.
  - name: WEBDAV_BACKUP_USERNAME
    group: Backups
    default: ""
    description: >-
      The WebDAV user name.
  - name: WEBDAV_BACKUP_PASSWORD
    group: Backups
    default: ""
    description: >-
      The WebDAV password.
  - name: WEBDAV_BACKUP_PATH
    group: Backups
    default: /yuvomi/backups/
    description: >-
      The folder on the WebDAV server.
  - name: NOTIFICATION_ALLOW_PRIVATE_NETWORK
    group: Features
    default: "false"
    description: >-
      Set to true for Gotify, ntfy or webhook targets on your home network.
  - name: MODULES_ALLOW_WEB_INSTALL
    group: Features
    default: "false"
    description: >-
      Set to true to let admins install extra modules from Settings.
  - name: IMMICH_URL
    group: Features
    default: ""
    description: >-
      Your Immich server, for the photo screensaver.
  - name: IMMICH_API_KEY
    group: Features
    default: ""
    description: >-
      An Immich API key with asset.read and asset.view.
  - name: FIXER_API_KEY
    group: Features
    default: ""
    description: >-
      A Fixer API key, for live currency conversion in Budget.
  - name: ENABLE_API_DOCS
    group: Features
    default: ""
    description: >-
      Set to true to show the API docs (/docs) to signed-in admins.
---

# Yuvomi

Yuvomi is a self-hosted family planner that replaces a dozen separate apps (tasks, calendar, budget, shopping, meals and more) with one private place on your own server. Each install makes its own session secret and database key on first start, and the database is encrypted.

## Features

- Modules for Tasks, Shopping, Meals, Recipes, Pantry, Calendar, Documents, Inventory, Budget, Housekeeping, Rewards, Health, Schedule, Notes and Contacts, Birthdays, Family, Reminders and Backup. Turn on only what your household needs.
- Modules work together: a meal plan fills the shopping list, a done chore pays reward points
- Two-way Google, Outlook and CalDAV calendar sync, sign-in with OIDC, two-factor sign-in and invite links for family members
- Encrypted database (SQLCipher), no telemetry, scheduled backups and a REST and MCP API

## How to use

1. Open Yuvomi from your dashboard.
2. Make your household's admin account on the first screen.
3. Turn on the modules you want in Settings.
4. Invite the rest of the family with an invite link. Each person picks their own password.
5. Calendar sync, weather, sign-in with OIDC and WebDAV backups can be added later in Settings or from the Variables tab.

## Before you install

You don't need to change anything. On first start the app makes its own session secret and database key and keeps them in the data folder (`.session_secret` and `.db_encryption_key`). Back up the whole app folder: without the key, nobody can open the database. Email, weather, calendar sync, sign-in with OIDC and the other settings are in the Variables tab; add them in the app settings. Set `BASE_URL` to the address you open Yuvomi at if you want links in emails.
