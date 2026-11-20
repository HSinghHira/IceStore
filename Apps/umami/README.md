---
site: https://umami.is
services:
  - { name: Dashboard, path: /, icon: globe }
  - { name: Tracker script, path: /script.js, icon: file-code }
screenshots: [Dashboard, Funnel report]
variables:
  - name: DISABLE_TELEMETRY
    group: Server
    default: "1"
    description: >-
      Set to 0 to send anonymous usage numbers to the Umami team.
  - name: DISABLE_UPDATES
    group: Server
    default: ""
    description: >-
      Set to 1 to stop checking for new Umami versions.
  - name: DISABLE_LOGIN
    group: Server
    default: ""
    description: >-
      Set to 1 to turn off the sign-in page, so only share links work.
  - name: PRIVATE_MODE
    group: Server
    default: ""
    description: >-
      Set to 1 to hide Umami's own links and branding.
  - name: FORCE_SSL
    group: Server
    default: ""
    description: >-
      Set to 1 to send the Strict-Transport-Security header, when Umami is
      only reached over https.
  - name: DEFAULT_LOCALE
    group: Server
    default: ""
    description: >-
      The language of the dashboard for new users, like de-DE or fr-FR.
  - name: DEFAULT_CURRENCY
    group: Server
    default: ""
    description: >-
      The currency for revenue reports, like EUR.
  - name: TRACKER_SCRIPT_NAME
    group: Tracking
    default: ""
    description: >-
      Other names for the tracker script, like stats.js, so ad blockers miss
      it. Separate several with commas.
  - name: COLLECT_API_ENDPOINT
    group: Tracking
    default: ""
    description: >-
      Another path for the collect API instead of /api/send, like
      /api/collect.
  - name: CLIENT_IP_HEADER
    group: Tracking
    default: ""
    description: >-
      The header your reverse proxy puts the visitor's IP in, like
      CF-Connecting-IP for Cloudflare.
  - name: IGNORE_IP
    group: Tracking
    default: ""
    description: >-
      IP addresses or ranges not to count, separated by commas, like
      192.168.1.0/24.
  - name: DISABLE_BOT_CHECK
    group: Tracking
    default: ""
    description: >-
      Set to 1 to count visits from bots too.
  - name: CORS_MAX_AGE
    group: Tracking
    default: "86400"
    description: >-
      How long browsers may cache the CORS answer, in seconds.
  - name: LOG_QUERY
    group: Logs
    default: ""
    description: >-
      Set to 1 to log every database query.
  - name: DEBUG
    group: Logs
    default: ""
    description: >-
      Parts to log in detail, like umami:*.
---

# Umami

Umami shows you who visits your websites, where they come from and what they do, without cookies and without tracking people across the web. PostgreSQL is built in, so it is one container.

## Features

- Visitors, page views, bounce rate and visit time on one simple dashboard
- Where people come from: referrers, countries, browsers and devices
- Custom events, funnels, user journeys and retention reports
- No cookies and no personal data, so most sites need no cookie banner
- As many websites, users and teams as you like, plus share links
- A small tracker script (about 2 KB) and a full API

## How to use

1. Open Umami from your dashboard.
2. Sign in as `admin` with the password from the app's logs (the box marked CREDENTIALS).
3. Go to Settings, Websites and add your website.
4. Copy its tracking code and paste it into the `<head>` of your site.
5. Open your site once, then watch the visit show up on the dashboard.

## Before you install

You can leave `ADMIN_PASSWORD` empty: on first start Umami's built-in `admin`/`umami` login is replaced with a password made for this install, shown in the app's logs in the box marked CREDENTIALS. Once you change it in Umami, yours is kept. Open it from other devices at `http://[ZIMAOS-IP-ADDRESS]:6750`. Your websites must be able to reach that address to send visits, so for sites on the internet put a domain with https in front of it. More settings are in the Variables tab; add them in the app settings. The first start takes about 2 minutes.
