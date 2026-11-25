---
source: https://github.com/caronc/apprise-api
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: APPRISE_DEFAULT_THEME
    group: Web page
    default: "auto"
    description: >-
      light, dark or auto (follows your device).
  - name: APPRISE_DEFAULT_CONFIG_ID
    group: Web page
    default: "apprise"
    description: >-
      The key the web page opens with.
  - name: APPRISE_CONFIG_LOCK
    group: Security
    default: "no"
    description: >-
      Set to yes to hide the saved URLs (with their tokens) from the web
      page and API.
  - name: APPRISE_ADMIN
    group: Security
    default: "n"
    description: >-
      Set to y to show the admin pages that list every saved key.
  - name: APPRISE_DENY_SERVICES
    group: Security
    default: ""
    description: >-
      Services to block, comma separated, like windows, dbus.
  - name: APPRISE_ALLOW_SERVICES
    group: Security
    default: ""
    description: >-
      Only allow these services, comma separated.
  - name: APPRISE_RECURSION_MAX
    group: Server
    default: "1"
    description: >-
      How many times Apprise may call another Apprise server in a row.
  - name: APPRISE_WORKER_COUNT
    group: Server
    default: ""
    description: >-
      How many web workers to run. Left out
  - name: APPRISE_REMINDER_ENABLED
    group: Reminders
    default: "yes"
    description: >-
      Set to no to turn off reminders.
  - name: APPRISE_STORAGE_PRUNE_DAYS
    group: Storage
    default: "30"
    description: >-
      Days before saved notification state is cleaned up.
---

# Apprise

Apprise sends notifications to Telegram, Discord, Slack, email, ntfy, Gotify, Pushover, Matrix, Home Assistant and over 100 other services through one simple API. Save your services once under a key, and every app or script on your ZimaOS can notify you with a single call.

## Features

- Over 100 services, each written as one URL, like tgram://token/chat
- Web page to save, test and organize your notification setups under keys
- Tags to send a message to only some of your services
- Attachments, Markdown and HTML messages
- Reminders that send a message later or on a repeat
- Works with apps that speak the Apprise API, like changedetection.io and Uptime Kuma

## How to use

1. Open Apprise and make a configuration key, like home.
2. Add your service URLs (see the Apprise wiki for each service) and press Test.
3. Have your apps post to http://[ZIMAOS-IP-ADDRESS]:6821/notify/home with a title and body.

## Before you install

Apprise has no login: anyone on your network can open the web page, see the saved service URLs (which hold your tokens) and send messages through it. Keep it off the internet, set APPRISE_CONFIG_LOCK=yes to hide the URLs, or put it behind a reverse proxy with a password. Each service's URL format is in the Apprise wiki (https://github.com/caronc/apprise/wiki).
