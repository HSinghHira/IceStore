---
site: https://docs.speedtest-tracker.dev/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: Admin, path: /admin, icon: server }
screenshots: [Dashboard]
variables:
  - name: SPEEDTEST_SERVERS
    group: Speed tests
    default: ""
    description: >-
      Server IDs to test against, comma separated. Leave it out to let
      Speedtest pick the closest one.
  - name: SPEEDTEST_SKIP_IPS
    group: Speed tests
    default: ""
    description: >-
      Public IPs to skip tests on, comma separated, for example while a VPN
      is on.
  - name: PRUNE_RESULTS_OLDER_THAN
    group: Speed tests
    default: "0"
    description: >-
      Delete results older than this many days. 0 keeps everything.
  - name: DISPLAY_TIMEZONE
    group: Server
    default: ""
    description: >-
      The time zone for dates on the dashboard, like Europe/Berlin. Leave it
      out to use TZ.
  - name: APP_URL
    group: Server
    default: ""
    description: >-
      The address you open Speedtest Tracker at, like
      http://192.168.1.20:6768. Used for links in notifications.
  - name: PUBLIC_DASHBOARD
    group: Server
    default: "false"
    description: >-
      Set to true to show the results dashboard without signing in.
  - name: APP_KEY
    group: Server
    default: ""
    description: >-
      The key stored secrets are encrypted with. It is made on first start
      and kept in the config folder as .app_key. Only set it to use your own.
  - name: CHART_DATETIME_FORMAT
    group: Server
    default: "j/m G:i"
    description: >-
      How dates look on the charts, in PHP date format.
  - name: MAIL_MAILER
    group: Email (SMTP)
    default: ""
    description: >-
      Set to smtp to send email alerts.
  - name: MAIL_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: MAIL_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: MAIL_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: MAIL_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: MAIL_FROM_ADDRESS
    group: Email (SMTP)
    default: ""
    description: >-
      The address alerts are sent from.
---

# Speedtest Tracker

Speedtest Tracker checks your internet speed on a schedule with Ookla's Speedtest and keeps every result, so you can see if you get the speed you pay for. The database is built in, so it is one container with nothing else to set up.

## Features

- Download, upload, ping and jitter tests on a schedule
- Charts and history of every result
- Alerts by email, Discord, Telegram, ntfy and more when speed drops
- Pick the test servers, or let it choose
- Public dashboard you can share, and an API

## How to use

1. Open Speedtest Tracker from your dashboard.
2. Sign in with the email and the password from the app's logs (the box marked CREDENTIALS).
3. Change your password in your profile.
4. Click Speedtest to run your first test.
5. Watch the dashboard fill up with the scheduled tests.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6768`. Tests run every 6 hours (`SPEEDTEST_SCHEDULE`, in cron format). The first user is `ADMIN_EMAIL` (`admin@example.com` unless you change it) with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/speedtest-tracker/config/.admin_password`. The app key is also made for you. Test servers, alerts and the other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
