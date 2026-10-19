---
site: __HOMEPAGE_URL__
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [__CAPTION_1__, __CAPTION_2__, __CAPTION_3__]
variables:
  - name: __APP_PREFIX___DISABLE_SIGNUP
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so only people you invite can join.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com. Leave it out and no emails are
      sent.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "465"
    description: >-
      Your email server port, usually 465 or 587.
---

# __TITLE__

__PITCH__ This is __TITLE__ in a single container, with one port and one data folder. Secret keys are made for you on first start.

## Features

- __FEATURE__
- __FEATURE__
- PostgreSQL and Redis inside

## How to use

1. Open __TITLE__ from your dashboard.
2. Sign in with the admin email and password.
3. __FIRST_ACTION__

## Before you install

Set `ADMIN_EMAIL` to your own email. Leave `ADMIN_PASSWORD` blank to get a random one, shown in the app log as "admin password is". To use __TITLE__ from other devices, change `localhost` in `PUBLIC_URL` to your server's IP address. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. The first start takes a few minutes.
