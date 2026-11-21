---
site: https://js.wiki/
services:
  - { name: Wiki, path: /, icon: globe }
  - { name: Administration, path: /_admin, icon: server }
variables:
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much Wiki.js writes to the log: error, warn, info or debug.
  - name: LOG_FORMAT
    group: Logs
    default: default
    description: >-
      Set to json for log lines a log collector can read.
  - name: OFFLINE
    group: Server
    default: "false"
    description: >-
      Set to true when the server has no internet, so Wiki.js doesn't try to
      download updates and icons.
  - name: ICONIFY_API_URL
    group: Server
    default: https://api.iconify.design
    description: >-
      Where the icon picker loads icons from. Change it only if you run your
      own Iconify server.
---

# Wiki.js

Wiki.js is a fast, modern wiki for your team or your home. Write pages in a visual editor or in Markdown, find them with search, and keep a copy in Git. PostgreSQL is built in, so it is one container with nothing else to set up.

## Features

- Visual editor, Markdown editor and diagrams in one wiki
- Full-text search, tags and a page tree
- Page history, comments and live editing together
- Users, groups and rights per page or folder, with passkeys and two-factor sign-in
- Sign in with OIDC, Google, GitHub, LDAP and more
- Sync pages to a Git repository or a folder on disk

## How to use

1. Open Wiki.js from your dashboard.
2. Sign in as admin@example.com with the password from the app's logs (the box marked CREDENTIALS).
3. Change your email and password in your profile.
4. Make your first page: pick a path, an editor and start writing.
5. In Administration, add users and groups, and turn on sign-in providers or Git sync.

## Before you install

You can install it as it is. Set `ADMIN_EMAIL` to your own email if you like; it and `ADMIN_PASS` are only read on the very first start. Leave `ADMIN_PASS` empty and a password is made for you, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/wikijs/data/.admin_password`. Open it at `http://[ZIMAOS-IP-ADDRESS]:6760`. Sign-in providers, email, Git sync and almost every other setting are in Wiki.js under Administration; the few server settings are in the Variables tab. The first start takes about 3 minutes while the database is made.
