---
site: https://github.com/PhiTux/DailyTxT
source: https://github.com/PhiTux/DailyTxT
screenshots: [Journal]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: LOGOUT_AFTER_DAYS
    group: Sign-in
    default: "30"
    description: >-
      Days before you have to sign in again.
  - name: SECRET_TOKEN
    group: Sign-in
    default: ""
    description: >-
      Secret that signs sign-ins. Leave blank and IceStore makes one and keeps it.
  - name: INDENT
    group: Files
    default: "0"
    description: >-
      Spaces to pretty-print the saved JSON files with, like 4. 0 keeps them compact.
  - name: ALLOWED_HOSTS
    group: Web
    default: ""
    description: >-
      Extra web origins allowed to call the API, comma separated. Not needed for the normal web page.
  - name: BASE_PATH
    group: Web
    default: ""
    description: >-
      Serve DailyTxT under a sub path, like /dailytxt, behind a reverse proxy.
---

# DailyTxT

DailyTxT is a private diary. Write one entry for each day, add tags and files, and find old days again with search and the calendar. Every entry is encrypted with your password.

## Features

- One entry a day, with Markdown and a calendar
- Everything encrypted with a key from your password
- Tags, file uploads, templates and full search
- Read your entries from this day in past years
- Export to HTML and backups, and installs as a phone app

## How to use

1. Open DailyTxT and register your account.
2. Write today's entry. It saves as you type.
3. Set ALLOW_REGISTRATION to false so nobody else can sign up.

## Before you install

DailyTxT has no default account: open http://[ZIMAOS-IP-ADDRESS]:7007 and register, then set ALLOW_REGISTRATION to false. Your entries are encrypted with a key from your password, so a lost password means lost entries unless you saved the backup keys DailyTxT offers. The admin panel (users, registration) uses ADMIN_PASSWORD; leave it blank and the password is in the app's log under CREDENTIALS. Upstream makes a new secret token on every start, which signs everyone out; this IceStore image keeps one per install.
