---
name: AppRankly
site: https://zmsp.github.io/AppRankly/
source: https://github.com/zmsp/AppRankly
services:
  - { name: Dashboard, path: /, icon: globe }
screenshots: [Overview, App details, Retention, ASO]
variables:
  - name: ADMIN_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      A bcrypt hash of the admin password, instead of choosing it in the
      browser on the first visit.
  - name: JWT_SECRET
    group: Sign-in
    default: ""
    description: >-
      Signs sign-ins. Made on first start and kept in the data folder
      (.jwt_secret) when left out.
---

# AppRankly

AppRankly brings your iOS and Android app numbers into one self-hosted dashboard: installs, uninstalls, active devices, retention and release markers side by side, plus keyword rankings. It reads the official store reports with your own keys, so your data stays private.

## Features

- Google Play and App Store stats in one place
- Retention cohorts, survival curves and release markers
- ASO keyword tracking and app details
- Alerts and daily briefs to ntfy, Discord, Slack or Telegram
- Notes, teams with roles, and optional AI summaries

## How to use

1. Open AppRankly and choose the admin password.
2. Fill in `config/config.json` with your Google Play and App Store details, and put the key files in `config/keys/`.
3. Restart the app; your stats load on the next refresh.

## Before you install

Nothing to set first; open AppRankly and choose the admin password on the first visit. For your stats it needs your Google Play Cloud Storage and App Store Connect keys: edit `/DATA/AppData/apprankly/data/config/config.json` with the Files app (upstream's `example.config.json` shows every field and where to find each value) and put the key files in `config/keys/`, then restart the app.
