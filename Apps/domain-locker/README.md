---
site: https://domain-locker.com
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Health, path: /api/health, icon: info }
screenshots: [Home, Assets, Expirations]
variables:
  - name: DL_API_KEY
    group: Security
    default: ""
    description: >-
      A key for calling the API from scripts or cron jobs when
      DL_AUTH_PASSWORD is set.
  - name: DL_DISABLE_WRITE_METHODS
    group: Security
    default: "false"
    description: >-
      Set to true to make the app read-only, so nothing can be added or
      changed from the web page.
  - name: DL_BASE_URL
    group: Server
    default: ""
    description: >-
      The address people open Domain Locker at, like
      https://domains.example.com. Only needed when it is served on another
      hostname than people visit.
  - name: DL_ALLOWED_ORIGINS
    group: Server
    default: ""
    description: >-
      Extra web addresses allowed to call the API, comma-separated.
  - name: DL_DISABLE_SSRF_PROTECTION
    group: Server
    default: "false"
    description: >-
      Set to true to allow checks of domains that point at your home network.
  - name: DL_DISABLE_SCHEDULER
    group: Schedule
    default: "false"
    description: >-
      Set to true to stop the built-in jobs, if you run them yourself.
  - name: DL_MONITOR_INTERVAL_MINUTES
    group: Schedule
    default: "15"
    description: >-
      How often uptime is checked, in minutes.
  - name: DL_UPDATER_INTERVAL_MINUTES
    group: Schedule
    default: "1440"
    description: >-
      How often domain details are refreshed, in minutes.
  - name: DL_REMINDERS_INTERVAL_MINUTES
    group: Schedule
    default: "1440"
    description: >-
      How often expiry reminders are sent, in minutes.
  - name: DL_CLEANUP_INTERVAL_MINUTES
    group: Schedule
    default: "10080"
    description: >-
      How often old data is cleaned up, in minutes.
  - name: DL_MONITOR_CONCURRENCY
    group: Schedule
    default: "10"
    description: >-
      How many domains are checked at the same time.
  - name: DL_UPDATER_BATCH_SIZE
    group: Schedule
    default: "100"
    description: >-
      How many domains are refreshed in each run.
  - name: DL_WHOIS_PROVIDERS
    group: Lookups
    default: rdap,whois-json,who-dat,native,whoisxml
    description: >-
      The order of WHOIS sources to try.
  - name: DL_WHO_DAT_URL
    group: Lookups
    default: https://who-dat.as93.net
    description: >-
      Your own who-dat lookup server, if you run one.
  - name: DL_WHOIS_CONCURRENCY
    group: Lookups
    default: "5"
    description: >-
      How many WHOIS lookups run at once.
  - name: DL_WHOIS_DELAY_MS
    group: Lookups
    default: "0"
    description: >-
      A pause between WHOIS lookups in milliseconds, for registries that
      limit lookups (like .it and .eu).
  - name: DL_UPTIME_AGGREGATE_AFTER_DAYS
    group: History
    default: "7"
    description: >-
      Days of detailed uptime checks kept before they are averaged.
  - name: DL_UPTIME_RETENTION_DAYS
    group: History
    default: ""
    description: >-
      Days of uptime history to keep. Leave it out to keep it forever.
  - name: DL_HISTORY_RETENTION_DAYS
    group: History
    default: ""
    description: >-
      Days of domain change history to keep. Leave it out to keep it forever.
  - name: DL_NOTIFICATIONS_RETENTION_DAYS
    group: History
    default: ""
    description: >-
      Days of notifications to keep. Leave it out to keep them forever.
  - name: NOTIFY_WEBHOOK_BASE
    group: Notifications
    default: ""
    description: >-
      An ntfy server for push notifications, like https://ntfy.sh.
  - name: NOTIFY_WEBHOOK_TOPIC
    group: Notifications
    default: ""
    description: >-
      The ntfy topic to send to.
  - name: NOTIFY_WEBHOOK_TOKEN
    group: Notifications
    default: ""
    description: >-
      An ntfy access token, for a private server.
  - name: NOTIFY_WEBHOOK_USERNAME
    group: Notifications
    default: ""
    description: >-
      An ntfy user name, instead of a token.
  - name: NOTIFY_WEBHOOK_PASSWORD
    group: Notifications
    default: ""
    description: >-
      The ntfy password for that user name.
  - name: DISCORD_WEBHOOK_URL
    group: Notifications
    default: ""
    description: >-
      A Discord channel webhook URL for notifications.
  - name: APPRISE_API_URL
    group: Notifications
    default: ""
    description: >-
      An Apprise API server, like http://192.168.1.20:8000.
  - name: APPRISE_KEY
    group: Notifications
    default: ""
    description: >-
      The config key stored on that Apprise server.
  - name: APPRISE_URLS
    group: Notifications
    default: ""
    description: >-
      A comma-separated list of Apprise URLs, instead of a key.
  - name: APPRISE_TAG
    group: Notifications
    default: ""
    description: >-
      Only notify the Apprise services with this tag.
  - name: DL_PG_HOST
    group: Database
    default: ""
    description: >-
      A PostgreSQL server instead of the built-in SQLite file. DL_PG_HOST,
      DL_PG_USER, DL_PG_PASSWORD and DL_PG_NAME must all be set, or SQLite is
      used.
  - name: DL_PG_PORT
    group: Database
    default: "5432"
    description: >-
      The PostgreSQL port.
  - name: DL_PG_USER
    group: Database
    default: ""
    description: >-
      The PostgreSQL user.
  - name: DL_PG_PASSWORD
    group: Database
    default: ""
    description: >-
      The PostgreSQL password.
  - name: DL_PG_NAME
    group: Database
    default: ""
    description: >-
      The PostgreSQL database name.
---

# Domain Locker

Domain Locker is one place for your whole domain name portfolio. Add a domain and it fills in the registrar, expiry date, DNS records, SSL certificate, hosting and IP details by itself, then keeps checking them and tells you before anything expires or changes. This build keeps everything in a SQLite file and runs its own scheduled jobs.

## Features

- Automatic lookup of registrar, WHOIS, DNS, SSL, host and IP data
- Expiry reminders and alerts when a record or certificate changes
- Uptime and response-time monitoring for each domain
- Charts, a timeline, a map and a value tracker for your portfolio
- Tags, notes, subdomains and links per domain
- Import and export, plus an API
- Notifications by ntfy, Discord or Apprise

## How to use

1. Open Domain Locker at `http://[ZIMAOS-IP-ADDRESS]:6180`.
2. Type your `DL_AUTH_PASSWORD` if you set one.
3. Click Add Domain and type a domain name. The details fill in by themselves.
4. Open Settings to choose which changes you want to hear about.

## Before you install

Set `DL_AUTH_PASSWORD` so only people who know it can open the app; left empty, anyone who can reach it can see and change your domains. Keep `DL_ENV_TYPE` as `selfHosted`. The first start takes about a minute while the database is made. Notifications, check intervals and an optional PostgreSQL database are in the Variables tab; add them in the app settings. Your data is one SQLite file in the data folder.
