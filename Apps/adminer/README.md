---
site: https://www.adminer.org
source: https://github.com/vrana/adminer
screenshots: [Table data, Table structure]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: ADMINER_DEFAULT_SERVER
    group: Defaults
    default: ""
    description: >-
      The server filled in on the login page, like 192.168.1.20:5432.
  - name: ADMINER_PLUGINS
    group: Plugins
    default: ""
    description: >-
      Plugins to load, space separated, like tables-filter tinymce.
---

# Adminer

Adminer manages your databases from one simple page: browse and edit tables, run SQL, import and export, and change structure, for MySQL, MariaDB, PostgreSQL, SQLite, SQL Server and more.

## Features

- MySQL, MariaDB, PostgreSQL, SQLite, SQL Server, Oracle and more
- Browse, search, edit and insert rows
- SQL command window with history
- Create and change tables, indexes, foreign keys and users
- Import and export SQL and CSV

## How to use

1. Open Adminer, pick the database type and type the server, user and password.
2. For a database app on your ZimaOS, the server is your ZimaOS IP and its published port, like 192.168.1.20:5432.

## Before you install

Adminer stores nothing: you sign in with each database's own user and password. Anyone on your network who knows a database password can use it from here, so do not open Adminer to the internet. Databases in other ZimaOS apps are reached at your ZimaOS IP and their published port. SQLite files need a plugin and a mounted folder.
