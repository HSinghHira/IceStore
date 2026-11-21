---
site: https://www.firefly-iii.org/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API, path: /api/v1/about, icon: code }
screenshots: [Dashboard]
variables:
  - name: APP_URL
    group: Server
    default: "http://localhost:6771"
    description: >-
      The address you open Firefly III at, like http://192.168.1.20:6771.
      Used in email links.
  - name: TRUSTED_PROXIES
    group: Server
    default: ""
    description: >-
      Set to ** when a reverse proxy is in front of Firefly III, so it sees
      https and the real visitor address.
  - name: DEFAULT_LOCALE
    group: Server
    default: "equal"
    description: >-
      How numbers and dates look, like en_US or de_DE. equal follows
      DEFAULT_LANGUAGE.
  - name: APP_LOG_LEVEL
    group: Server
    default: "notice"
    description: >-
      How much goes in the log: debug, info, notice, warning or error.
  - name: AUDIT_LOG_LEVEL
    group: Server
    default: "emergency"
    description: >-
      Set to info to log every change to your data.
  - name: APP_KEY
    group: Server
    default: ""
    description: >-
      The key your data is encrypted with, exactly 32 characters. It is made
      on first start and kept in the database folder. Only set it to move an
      old install.
  - name: STATIC_CRON_TOKEN
    group: Server
    default: ""
    description: >-
      The 32-character token for the daily job URL. It is made on first
      start; only set it to call the job from outside.
  - name: COOKIE_SECURE
    group: Server
    default: "false"
    description: >-
      Set to true when you only open Firefly III over https.
  - name: AUTHENTICATION_GUARD
    group: Sign-in
    default: "web"
    description: >-
      Set to remote_user_guard to sign in through a proxy like Authelia.
  - name: AUTHENTICATION_GUARD_HEADER
    group: Sign-in
    default: "REMOTE_USER"
    description: >-
      The header that proxy puts the user in.
  - name: AUTHENTICATION_GUARD_EMAIL
    group: Sign-in
    default: ""
    description: >-
      The header that proxy puts the email in.
  - name: CUSTOM_LOGOUT_URL
    group: Sign-in
    default: ""
    description: >-
      Where to go after signing out, for proxy sign-in.
  - name: MAIL_MAILER
    group: Email
    default: "log"
    description: >-
      Set to smtp to send email (password resets, bill reminders).
  - name: MAIL_HOST
    group: Email
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: MAIL_PORT
    group: Email
    default: "2525"
    description: >-
      Your email server port, usually 587 or 465.
  - name: MAIL_FROM
    group: Email
    default: "changeme@example.com"
    description: >-
      The address emails are sent from.
  - name: MAIL_USERNAME
    group: Email
    default: ""
    description: >-
      The user name for your email server.
  - name: MAIL_PASSWORD
    group: Email
    default: ""
    description: >-
      The password for your email server.
  - name: MAIL_ENCRYPTION
    group: Email
    default: ""
    description: >-
      tls for STARTTLS (587) or ssl (465).
  - name: SEND_ERROR_MESSAGE
    group: Email
    default: "true"
    description: >-
      Send errors to SITE_OWNER by email.
  - name: MAP_DEFAULT_LAT
    group: Maps
    default: "51.983333"
    description: >-
      Where maps start, latitude.
  - name: MAP_DEFAULT_LONG
    group: Maps
    default: "5.916667"
    description: >-
      Where maps start, longitude.
  - name: MAP_DEFAULT_ZOOM
    group: Maps
    default: "6"
    description: >-
      How far maps are zoomed in at the start.
  - name: PHP_MEMORY_LIMIT
    group: Server
    default: "512M"
    description: >-
      Memory PHP may use. Raise it for big imports.
---

# Firefly III

Firefly III helps you keep track of your money. Add your bank accounts, credit cards and cash, record what you spend and earn, and see where your money goes. Budgets, bills and piggy banks help you plan ahead. It uses a built-in SQLite database, so it is one container with nothing else to set up.

## Features

- Accounts, transactions, transfers and split transactions
- Budgets, categories, tags and bills
- Piggy banks to save for something
- Rules that sort new transactions for you
- Recurring transactions, run every day by the built-in job
- Reports and charts, in many currencies
- Import from your bank with the Data Importer, and a full API

## How to use

1. Open Firefly III from your dashboard.
2. Click Register and make your account. The first account is the admin.
3. Follow the first steps: add your main bank account and its balance.
4. Add transactions, or import them from your bank.
5. Make budgets and look at the reports.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6771`. There is no account yet: click Register, and the first account you make is the admin. Set `DEFAULT_LANGUAGE` if you want another language. The app key and the cron token are made for you on first start and kept in `/DATA/AppData/firefly-iii/database`, and the daily jobs (recurring transactions, bill reminders) run inside the container. Email, proxy sign-in and the other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
