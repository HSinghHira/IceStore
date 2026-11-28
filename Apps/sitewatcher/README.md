---
site: https://monitoring.kurkov.dev/demo
source: https://github.com/NikKurkov/sitewatcher
services:
  - { name: Dashboard, path: /login/, icon: globe }
variables:
  - name: TELEGRAM_TOKEN
    group: Telegram
    default: ""
    description: >-
      Telegram bot token, for alerts in Telegram. Can also be set in the dashboard.
  - name: TELEGRAM_ALERT_CHAT_ID
    group: Telegram
    default: ""
    description: >-
      The chat or channel id alerts go to, like -1001234567890.
  - name: TELEGRAM_ALLOWED_USER_IDS
    group: Telegram
    default: ""
    description: >-
      Telegram user ids allowed to use the bot, comma separated.
  - name: TELEGRAM_PROXY
    group: Telegram
    default: ""
    description: >-
      Proxy for Telegram, like socks5://192.168.1.5:1080, where Telegram is blocked.
  - name: VIRUSTOTAL_API_KEY
    group: Checks
    default: ""
    description: >-
      VirusTotal API key for reputation checks. Reports are cached for 24 hours.
  - name: VIRUSTOTAL_PROXY
    group: Checks
    default: ""
    description: >-
      Proxy for VirusTotal requests.
  - name: SITEWATCHER_WEB_HTTPS
    group: Web
    default: "0"
    description: >-
      1 only behind a reverse proxy with https; it marks sign-in cookies as https-only.
  - name: SITEWATCHER_WEB_TRUST_PROXY
    group: Web
    default: "0"
    description: >-
      1 trusts the X-Forwarded-Proto header from your reverse proxy.
---

# SiteWatcher

SiteWatcher checks your websites from one dashboard: whether they open, how fast they answer, and when their HTTPS certificates and domain names expire. It alerts you by email or Telegram and can share public status pages.

## Features

- Uptime, HTTP status and response time for each site
- HTTPS certificate and domain registration expiry
- Expected words on a page and signs of defacement
- IP, blocklist, open port and route changes
- Alerts by email and Telegram, and public or private status pages

## How to use

1. Set SITEWATCHER_WEB_ALLOWED_HOSTS to your ZimaOS IP address.
2. Open the app's log and find the password under CREDENTIALS.
3. Sign in at http://[ZIMAOS-IP-ADDRESS]:7002/login/ with admin and that password, then click + to add a site.

## Before you install

Change SITEWATCHER_WEB_ALLOWED_HOSTS first: put your ZimaOS IP address (just the address, like 192.168.1.20) in place of [ZIMAOS-IP-ADDRESS]. SiteWatcher refuses requests for any other host name, so without it the page shows 400 Bad Request; add your domain too, comma separated, if you use a reverse proxy. Upstream creates the owner account with `sitewatcher setup` in a terminal; this IceStore image does it on the first start instead and prints the password in the app's log under CREDENTIALS (also saved in the data folder). Upstream runs the dashboard and the check worker as two containers; here both run in one. Email and most other settings are set in the dashboard.
