---
site: https://www.goatcounter.com
source: https://github.com/arp242/goatcounter
services:
  - { name: Dashboard, path: /, icon: globe }
  - { name: API, path: /api/v0, icon: code }
variables:
  - name: GOATCOUNTER_DB
    group: Database
    default: "sqlite+goatcounter-data/db.sqlite3"
    description: >-
      Database to use. Default is SQLite in the data folder; use postgresql+host=... user=... dbname=... for your own PostgreSQL.
  - name: GOATCOUNTER_SMTP
    group: Email
    default: "stdout"
    description: >-
      Mail server for password resets and reports, like smtp://user:pass@mail.example.com:587. stdout only writes emails to the log.
  - name: GOATCOUNTER_EMAIL_FROM
    group: Email
    default: ""
    description: >-
      The sender address on emails GoatCounter sends.
  - name: GOATCOUNTER_BASE_PATH
    group: Web
    default: ""
    description: >-
      Serve GoatCounter under a sub path, like /stats, behind a reverse proxy.
  - name: GOATCOUNTER_GEODB
    group: Location
    default: ""
    description: >-
      GeoIP database for regions and cities, or maxmind:account_id:license_key to download one. Countries work without it.
  - name: GOATCOUNTER_RATELIMIT
    group: Advanced
    default: ""
    description: >-
      Request limits, like count:4/1,api:4/1. Blank uses the defaults.
  - name: GOATCOUNTER_STORE_EVERY
    group: Advanced
    default: "10"
    description: >-
      Seconds between saving new pageviews to the database.
  - name: GOATCOUNTER_ERRORS
    group: Advanced
    default: ""
    description: >-
      mailto:you@example.com sends errors to you by email.
---

# GoatCounter

GoatCounter counts the visitors on your websites without tracking people: no cookies, no personal data, and a small script. It shows pages, referrers, browsers, screen sizes and countries on a clean dashboard.

## Features

- No cookies and no personal data, so no cookie banner needed
- Tiny tracking script, or count from your server logs
- Pages, referrers, campaigns, browsers, systems and countries
- Several sites and users in one install
- Export to CSV and a full API

## How to use

1. Open GoatCounter. The setup page asks for a domain, your email and a password.
2. For the domain, type your ZimaOS IP address (or the domain you will use), then sign in.
3. Copy the tracking script from Settings into your website.

## Before you install

GoatCounter finds the right site by the address you open it with, so on the setup page type the same host you use in the browser: your ZimaOS IP address at home (http://[ZIMAOS-IP-ADDRESS]:6891), or your domain if you put a reverse proxy in front. The first person to open GoatCounter fills in that page, so do it right after installing. Visitors of a public website can only be counted when their browsers can reach GoatCounter, which needs a reverse proxy or tunnel with your own domain and https; then set GOATCOUNTER_PUBLIC_PORT to 443.
