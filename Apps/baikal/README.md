---
site: https://sabre.io/baikal/
source: https://github.com/sabre-io/Baikal
services:
  - { name: Web App, path: /, icon: globe }
---

# Baïkal

Baïkal keeps your calendars and contacts on your ZimaOS and syncs them with your phones and computers over CalDAV and CardDAV. It is small, fast and managed from a simple admin page.

## Features

- CalDAV calendars and to-dos, CardDAV address books
- Works with iOS, macOS, Thunderbird, DAVx5 on Android and more
- Several users, each with their own calendars and contacts
- SQLite by default, or MySQL
- Simple admin page for users and settings

## How to use

1. Open Baïkal right away and set the admin password, time zone and database (SQLite).
2. Add a user in the admin page.
3. On your device, add a CalDAV or CardDAV account with http://[ZIMAOS-IP-ADDRESS]:6836/dav.php and that user.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6836 and finish the setup (admin password, time zone, SQLite); until then anyone on your network can. Add users in the admin page, then add CalDAV/CardDAV accounts on your devices with http://[ZIMAOS-IP-ADDRESS]:6836/dav.php. Android with DAVx5 and Thunderbird work over plain http; Apple devices are happier with https through a reverse proxy with your own domain.
