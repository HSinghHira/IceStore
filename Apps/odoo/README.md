---
site: https://www.odoo.com
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Database Manager, path: /web/database/manager, icon: server }
screenshots: [Apps, Inventory, CRM]
variables:
  - name: ODOO_SMTP_SERVER
    group: Email (SMTP)
    default: localhost
    description: >-
      Your mail server, like smtp.gmail.com. Odoo only uses these settings
      when no outgoing mail server is set up in Settings, Technical, Outgoing
      Mail Servers.
  - name: ODOO_SMTP_PORT
    group: Email (SMTP)
    default: "25"
    description: >-
      Your mail server's port. Usually 587, or 465 with ODOO_SMTP_SSL.
  - name: ODOO_SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: ODOO_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: ODOO_SMTP_SSL
    group: Email (SMTP)
    default: "False"
    description: >-
      Set to True to use an encrypted (STARTTLS) connection to the mail
      server.
  - name: ODOO_EMAIL_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address on emails Odoo sends, like odoo@example.com.
  - name: ODOO_LIST_DB
    group: Databases
    default: "True"
    description: >-
      Set to False to hide the database list and the database manager page.
      Only do this once your database exists.
  - name: ODOO_DBFILTER
    group: Databases
    default: ""
    description: >-
      Only show databases whose name matches this pattern, like ^mycompany$.
      Useful when you keep one database for real use and others for tests.
  - name: ODOO_WORKERS
    group: Performance
    default: "0"
    description: >-
      How many worker processes Odoo runs. 0 runs everything in one process,
      which is fine for a few users. For more users, try 2 to 4 and raise the
      memory limit of the app.
  - name: ODOO_MAX_CRON_THREADS
    group: Performance
    default: "2"
    description: >-
      How many scheduled jobs (like sending emails) can run at the same time.
  - name: ODOO_LIMIT_TIME_CPU
    group: Performance
    default: "60"
    description: >-
      Seconds of CPU time one request may use before Odoo stops it. Only used
      when ODOO_WORKERS is above 0.
  - name: ODOO_LIMIT_TIME_REAL
    group: Performance
    default: "120"
    description: >-
      Seconds one request may take in total before Odoo stops it. Raise it if
      big imports or reports time out. Only used when ODOO_WORKERS is above 0.
  - name: ODOO_LIMIT_MEMORY_SOFT
    group: Performance
    default: "2147483648"
    description: >-
      Memory in bytes a worker may use before Odoo restarts it after the
      current request. Only used when ODOO_WORKERS is above 0.
  - name: ODOO_LIMIT_MEMORY_HARD
    group: Performance
    default: "2684354560"
    description: >-
      Memory in bytes at which Odoo stops a worker right away. Only used when
      ODOO_WORKERS is above 0.
  - name: ODOO_LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much Odoo writes to the app log: debug, info, warn, error or
      critical.
---

# Odoo

Odoo is a suite of open source business apps that run your company in one place, including CRM, sales, accounting, inventory, projects, and a website builder. This is Odoo in a single container, with one port and one data folder. The database passwords and the master password are made for you on first start.

## Features

- CRM, sales, invoicing, accounting, inventory, and purchasing apps
- Website, eCommerce, and project management apps
- Install only the apps you need and add more later
- Your own add-on modules in the addons folder
- PostgreSQL 16 inside, nothing else to set up

## How to use

1. Open Odoo from your dashboard.
2. On the first screen, create a database. Type the master password from the app log, a database name, your email, and a password for your admin account.
3. Sign in and pick the apps you want to install.
4. Put your own add-on modules in the addons folder, then update the app list in Odoo.
5. Manage databases later at the `/web/database/manager` page.

## Before you install

There is nothing you must set. Leave `ODOO_MASTER_PASSWORD` blank to get a random one, or type your own. The first start takes about three minutes. If you left it blank, find the line "master password is" in the app log; you need it to create, back up, restore and delete databases. Then open `http://your-zimaos-ip:6156` and create your first database and admin account. Your own modules go in `addons/` inside the app's data folder. Email, worker and log settings are in the Variables tab; add them in the app settings.
