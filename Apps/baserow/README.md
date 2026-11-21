---
site: https://baserow.io/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API docs, path: /api-docs, icon: code }
screenshots: [Grid view, Kanban view, Form view, Application builder, Dashboard]
variables:
  - name: BASEROW_EXTRA_ALLOWED_HOSTS
    group: Server
    default: ""
    description: >-
      Other host names Baserow may be opened at, comma separated, like
      baserow.local.
  - name: BASEROW_MAX_IMPORT_FILE_SIZE_MB
    group: Server
    default: "512"
    description: >-
      The biggest file you can import, in MB.
  - name: BASEROW_FILE_UPLOAD_SIZE_LIMIT_MB
    group: Server
    default: "1048576"
    description: >-
      The biggest file people can upload into a row, in MB.
  - name: BASEROW_AMOUNT_OF_WORKERS
    group: Server
    default: "1"
    description: >-
      How many web workers to run. Raise it for many users, if you have the
      memory.
  - name: EMAIL_SMTP
    group: Email (SMTP)
    default: ""
    description: >-
      Set to true to send emails: invites, password resets and
      notifications.
  - name: EMAIL_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: EMAIL_SMTP_PORT
    group: Email (SMTP)
    default: "25"
    description: >-
      Your email server port, usually 587 or 465.
  - name: EMAIL_SMTP_USE_TLS
    group: Email (SMTP)
    default: ""
    description: >-
      Set to true for port 587 (STARTTLS).
  - name: EMAIL_SMTP_USE_SSL
    group: Email (SMTP)
    default: ""
    description: >-
      Set to true for port 465.
  - name: EMAIL_SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: EMAIL_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: FROM_EMAIL
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: BASEROW_ENABLE_OTEL
    group: Logs
    default: "false"
    description: >-
      Set to true to send traces to an OpenTelemetry collector.
---

# Baserow

Baserow lets you build databases as easily as a spreadsheet, then turn them into forms, dashboards and small apps without writing code. This is Baserow's own all-in-one image: PostgreSQL, Redis and the web server are inside, so there is nothing else to set up.

## Features

- Tables with grid, kanban, gallery, calendar, timeline and form views
- Links between tables, lookups, formulas and filters
- Application builder for small apps and portals on your data
- Dashboards and automations
- Real-time collaboration, comments and row history
- REST API, webhooks and imports from CSV, Excel and Airtable

## How to use

1. Set `BASEROW_PUBLIC_URL` to your server's address before you install.
2. Open Baserow from your dashboard.
3. Click Sign up and make your account. The first account becomes the instance admin.
4. Make a workspace, then a database, and add your tables.
5. Invite people from the workspace menu.

## Before you install

**You must set `BASEROW_PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6766`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6766`. Your browser talks to Baserow's API at that address, so the page won't work at any other. There is no admin account yet: the first person to sign up becomes the instance admin. Baserow makes its own secret keys on first start and keeps them in the data folder. Email and the other settings are in the Variables tab and are added in the app settings. It needs about 2 GB of memory, and the first start takes about 5 minutes.
