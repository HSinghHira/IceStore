---
site: https://planka.app/
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Boards in action]
variables:
  - name: DEFAULT_ADMIN_USERNAME
    group: Sign-up and accounts
    default: admin
    description: >-
      The admin's user name, for signing in without the email.
  - name: DEFAULT_ADMIN_NAME
    group: Sign-up and accounts
    default: Admin
    description: >-
      The name shown for the admin.
  - name: SECRET_KEY
    group: Server
    default: ""
    description: >-
      The key that signs sign-ins. It is made on first start and kept in
      /data/secrets.env. Only set it to use your own.
  - name: TOKEN_EXPIRES_IN
    group: Server
    default: "365"
    description: >-
      How many days people stay signed in.
  - name: TRUST_PROXY
    group: Server
    default: "false"
    description: >-
      Set to true when PLANKA is behind a reverse proxy.
  - name: DEFAULT_LANGUAGE
    group: Server
    default: en-US
    description: >-
      The language for new users and notifications, like de-DE or fr-FR.
  - name: MAX_UPLOAD_FILE_SIZE
    group: Server
    default: ""
    description: >-
      The biggest attachment people can upload, in bytes. Leave it out for
      no limit.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com. Set it to send notification
      emails; leave it out to set email up in the app instead.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: SMTP_SECURE
    group: Email (SMTP)
    default: "true"
    description: >-
      true for port 465. Set to false for port 587.
  - name: SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      Who emails come from, like PLANKA <boards@example.com>.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much PLANKA writes to the log: error, warn, info or debug.
---

# PLANKA

PLANKA is a kanban board app like Trello. Make projects and boards, drag cards between lists, and see what others change right away. PostgreSQL is built in, so it is one container with nothing else to set up.

## Features

- Projects, boards, lists and cards with drag and drop
- Live updates: everyone sees changes at once
- Due dates, labels, checklists, attachments and comments
- Card members, stopwatch and notifications
- Markdown in descriptions and comments
- Users with roles, in many languages

## How to use

1. Set `BASE_URL` to your server's address before you install.
2. Open PLANKA from your dashboard.
3. Sign in with the admin email and the password from the app's logs (the box marked CREDENTIALS).
4. Make a project, then a board, then add lists and cards.
5. Under Administration, add the people who should work with you.

## Before you install

**You must set `BASE_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6762`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6762`. PLANKA only accepts browsers at that exact address; at any other address the page loads and the boards don't. For a domain, use `https://boards.example.com`, or list both with a comma. The admin account is `DEFAULT_ADMIN_EMAIL` (`admin@example.com` unless you change it) with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/planka/data/.admin_password`. To change it, set `DEFAULT_ADMIN_PASSWORD`. Email and the other settings are in the Variables tab and are added in the app settings. The first start takes about 2 minutes.
