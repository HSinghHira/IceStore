---
name: Kestello
site: https://kestello.com
source: https://github.com/kestellohq/cms
services:
  - { name: Site, path: /, icon: globe }
  - { name: Admin, path: /admin, icon: server }
---

# Kestello

Kestello is a content management system for the people who run a website and the developers who build it. Pages are written in a visual editor that shows the real page; plugins, themes, forms, media, search, backups and updates are built in. Written in PHP and Vue, with zero PHP dependencies. This container runs it with PHP-FPM and nginx, and can use SQLite, so nothing else is needed.

## Features

- Visual editor that shows the real page
- Plugins and themes, with signed updates installed from the admin
- Forms, media library, search and backups built in
- SQLite, MySQL, MariaDB or PostgreSQL

## How to use

1. Open Kestello from your dashboard.
2. Follow the installer: choose SQLite (or your own database) and make the admin account.
3. Sign in at `/admin` and build your site.

## Before you install

Nothing to set first. Open `http://[ZIMAOS-IP-ADDRESS]:6704` and follow the installer; SQLite keeps everything in the app's folder, or point it at a MySQL, MariaDB or PostgreSQL you already run. All settings (mail, storage, search) are made in the admin after that.

The whole site lives in `/DATA/AppData/kestello/site`. It is copied in on the first start, and from then on Kestello updates itself from its admin page with signed updates, so a newer IceStore image doesn't change an installed site. This is a release candidate: back up the folder before updates.
