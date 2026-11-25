---
site: https://dbeaver.com/cloudbeaver
source: https://github.com/dbeaver/cloudbeaver
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: CB_SERVER_NAME
    group: Setup
    default: ""
    description: >-
      The server name shown in the app (only read on the first setup).
  - name: CB_ADMIN_NAME
    group: Setup
    default: ""
    description: >-
      Skip the setup page with this admin name (with CB_ADMIN_PASSWORD).
  - name: CB_ADMIN_PASSWORD
    group: Setup
    default: ""
    description: >-
      The admin password for that automatic setup.
---

# CloudBeaver

CloudBeaver brings DBeaver to the browser. Connect to your databases, browse and edit data, run SQL with autocomplete, and see table relations as a diagram, from any computer.

## Features

- PostgreSQL, MySQL, MariaDB, SQLite, SQL Server, Oracle, ClickHouse and more
- Data editor with filters, sorting and export
- SQL editor with autocomplete, history and saved scripts
- ER diagrams of your tables
- Users, roles and shared connections

## How to use

1. Open CloudBeaver right away and finish the setup with an admin login.
2. Add a connection with the database's host, port and login.
3. Browse tables or open the SQL editor.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6856 and finish the setup with an admin user name and password; until then anyone on your network can. Databases in other ZimaOS apps are reached at your ZimaOS IP and their published port. Saved connection passwords are kept in /DATA/AppData/cloudbeaver/workspace; keep it private.
