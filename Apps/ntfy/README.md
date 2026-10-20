---
site: https://ntfy.sh/
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: NTFY_UPSTREAM_BASE_URL
    group: Server
    default: ""
    description: >-
      Set to https://ntfy.sh so iPhone apps get instant alerts. Only a hidden
      message ID is sent to ntfy.sh, never your message.
  - name: NTFY_BEHIND_PROXY
    group: Server
    default: "false"
    description: >-
      Set to true when ntfy sits behind a reverse proxy, so it reads the real
      visitor address.
  - name: NTFY_ENABLE_SIGNUP
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let people make their own account in the web app.
  - name: NTFY_CACHE_DURATION
    group: Messages
    default: 12h
    description: >-
      How long messages are kept for people who were offline, like 12h or 3d.
  - name: NTFY_ATTACHMENT_CACHE_DIR
    group: Messages
    default: ""
    description: >-
      Turns on file attachments. Set it to a folder like
      /var/lib/ntfy/attachments.
  - name: NTFY_SMTP_SENDER_ADDR
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server and port, like smtp.gmail.com:587. Needed to forward
      notifications by email.
  - name: NTFY_SMTP_SENDER_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The username for your email server.
  - name: NTFY_SMTP_SENDER_PASS
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: NTFY_SMTP_SENDER_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails come from, like ntfy@example.com.
  - name: NTFY_LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much detail goes in the log. One of trace, debug, info, warn or
      error.
---

# ntfy

A simple, self-hosted notification service. Send alerts from any script or app to your phone or desktop with a plain PUT or POST.

## Features

- Publish and subscribe to topics over HTTP
- Android, iOS and web apps for receiving notifications
- Users and access rules, locked down by default
- Messages and users saved in the app data folder

## How to use

1. Open ntfy from your dashboard.
2. Sign in with the default login: **admin** / **admin**.
3. Subscribe to a topic.
4. Send a test message with `curl -u admin:admin -d "Hello" http://your-server-ip:6113/mytopic`.
5. Add the same server and topic in the ntfy phone app.

## Before you install

The default login is **admin** / **admin**. Change it by replacing the hash in `NTFY_AUTH_USERS` with your own (make one at [bcrypt-generator.com](https://bcrypt-generator.com/)) and write every `$` in the hash as `$$`. Change the password there, not in the app, because the app resets it when ntfy restarts. Change `localhost` in `NTFY_BASE_URL` to your server's IP so your phone can reach ntfy. For instant iPhone alerts, add `NTFY_UPSTREAM_BASE_URL=https://ntfy.sh` from the Variables tab.
