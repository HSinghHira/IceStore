---
site: https://www.metabase.com
source: https://github.com/metabase/metabase
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: MB_DB_TYPE
    group: App database
    default: ""
    description: >-
      postgres or mysql to keep Metabase's own data in a real database
      instead of the H2 file (recommended for many users).
  - name: MB_DB_CONNECTION_URI
    group: App database
    default: ""
    description: >-
      That database's address, like
      postgres://user:pass@192.168.1.20:5432/metabase.
  - name: MB_SITE_URL
    group: Server
    default: ""
    description: >-
      The address people open Metabase at, used in emails and links.
  - name: MB_ENCRYPTION_SECRET_KEY
    group: Security
    default: ""
    description: >-
      A random text of 16 characters or more that encrypts the saved
      database passwords. Set it before you add databases and keep it.
  - name: JAVA_OPTS
    group: Server
    default: ""
    description: >-
      Java options, like -Xmx1g to limit memory.
  - name: MB_ANON_TRACKING_ENABLED
    group: Server
    default: "true"
    description: >-
      Set to false to stop sending usage statistics.
---

# Metabase

Metabase connects to your databases and lets anyone ask questions about the data with a simple editor or SQL, then turns the answers into charts and dashboards to share.

## Features

- Question builder for people who do not write SQL, plus a full SQL editor
- Charts, maps, pivot tables and dashboards with filters
- Works with PostgreSQL, MySQL, MariaDB, SQLite, SQL Server, MongoDB, BigQuery and more
- Scheduled email and Slack reports, and alerts
- Users, groups and data permissions

## How to use

1. Open Metabase right away and make the admin account.
2. Add your database with its host, port and login.
3. Ask a question, save it and add it to a dashboard.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6840 and make the admin account; until you do, anyone on your network can. The first start takes a few minutes. Metabase keeps its own data in an H2 file, which is fine for home use; for many users point MB_DB_TYPE and MB_DB_CONNECTION_URI at a PostgreSQL. Set MB_ENCRYPTION_SECRET_KEY before adding databases so their passwords are stored encrypted.
