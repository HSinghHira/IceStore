---
site: https://mailpit.axllent.org
services:
  - { name: Web UI, path: /, icon: mail }
variables:
  - name: MP_UI_AUTH
    group: Security
    default: ""
    description: >-
      Turns on a login for the web UI. Write it as user:password, like
      admin:mypassword. Use this if other people share your network.
  - name: MP_MAX_MESSAGES
    group: Storage
    default: "500"
    description: >-
      How many of the newest emails to keep. Older ones are deleted. Set to 0
      to keep everything.
  - name: MP_MAX_AGE
    group: Storage
    default: ""
    description: >-
      Delete emails older than this, like 7d for seven days or 12h for twelve
      hours.
  - name: MP_SMTP_AUTH
    group: SMTP
    default: ""
    description: >-
      Ask apps for a username and password when they send mail. Write it as
      user:password.
  - name: MP_SMTP_AUTH_ACCEPT_ANY
    group: SMTP
    default: "false"
    description: >-
      Set to true to accept any username and password apps send.
  - name: MP_SMTP_AUTH_ALLOW_INSECURE
    group: SMTP
    default: "false"
    description: >-
      Set to true to allow SMTP login without TLS. Many apps need this when
      they send a username and password to Mailpit.
---

# Mailpit

Mailpit is a small, fast SMTP testing tool. It catches every email your apps and scripts send, so nothing reaches a real inbox, and shows them in a web UI.

## Features

- An SMTP server for any app, script or self-hosted service on your network
- Web UI to search and read captured emails: HTML, raw source, headers and attachments
- HTML checker and link checker to test emails before sending for real
- REST API for automated testing
- Optional web UI login
- Captured mail is kept across restarts

## How to use

1. Open Mailpit from your dashboard.
2. Point any app's SMTP settings at your server's IP and port 6110. No username or password is needed.
3. Send a test email from that app. It shows up in Mailpit.
4. Use search, the HTML checker and the link checker to inspect it.

## Before you install

Nothing needs to be set first. The web UI is on port 6109 and has no login, so anyone on your network can read captured emails. To add a login, add `MP_UI_AUTH` (like `admin:mypassword`) in the app settings. If an app insists on sending a username and password, add `MP_SMTP_AUTH_ACCEPT_ANY` and `MP_SMTP_AUTH_ALLOW_INSECURE` set to `true`. All settings are in the Variables tab.
