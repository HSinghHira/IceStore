---
site: https://nextcloud.com
source: https://github.com/nextcloud/server
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: NEXTCLOUD_TRUSTED_DOMAINS
    group: Setup
    default: ""
    description: >-
      Extra addresses Nextcloud answers on, space separated, like
      cloud.example.com 192.168.1.20:6850 (only read on the first
      install).
  - name: NEXTCLOUD_ADMIN_USER
    group: Setup
    default: ""
    description: >-
      Install automatically with this admin user (with
      NEXTCLOUD_ADMIN_PASSWORD and SQLITE_DATABASE).
  - name: NEXTCLOUD_ADMIN_PASSWORD
    group: Setup
    default: ""
    description: >-
      The admin password for the automatic install.
  - name: SQLITE_DATABASE
    group: Setup
    default: ""
    description: >-
      The SQLite database name for the automatic install, like
      nextcloud.
  - name: OVERWRITEPROTOCOL
    group: Reverse proxy
    default: ""
    description: >-
      Set to https when Nextcloud is behind an https reverse proxy.
  - name: OVERWRITECLIURL
    group: Reverse proxy
    default: ""
    description: >-
      Your public address, like https://cloud.example.com.
  - name: TRUSTED_PROXIES
    group: Reverse proxy
    default: ""
    description: >-
      Your reverse proxy's IP address or range.
  - name: APACHE_DISABLE_REWRITE_IP
    group: Reverse proxy
    default: ""
    description: >-
      Set to 1 when using TRUSTED_PROXIES.
  - name: REDIS_HOST
    group: Performance
    default: ""
    description: >-
      A Redis server for caching and file locking, like 192.168.1.20.
  - name: SMTP_HOST
    group: Email
    default: ""
    description: >-
      Your mail server for Nextcloud's emails (with SMTP_PORT,
      SMTP_NAME, SMTP_PASSWORD, MAIL_FROM_ADDRESS and MAIL_DOMAIN).
---

# Nextcloud

Nextcloud is your own cloud: sync files between your devices, share them with links, and add calendars, contacts, notes, photos, office documents and hundreds more apps from its app store. Desktop and phone apps keep everything in sync.

## Features

- File sync for Windows, macOS, Linux, Android and iOS, with WebDAV
- Share links with passwords and expiry, and shared folders
- Calendar, Contacts, Notes, Deck, Photos, Talk and more from the app store
- Office documents with Nextcloud Office or OnlyOffice
- Users, groups, quotas and two-factor sign-in

## How to use

1. Open Nextcloud right away, make the admin account and press Install (SQLite is fine for a few users).
2. Install the desktop or phone app and sign in at http://[ZIMAOS-IP-ADDRESS]:6850.
3. Add apps like Calendar and Contacts from the Apps page.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6850, make the admin account and press Install; until you do, anyone on your network can. SQLite is fine for a few users; for more, point it at a MariaDB or PostgreSQL in the setup page. Nextcloud only answers on the address you set it up with: to add another (a domain behind a reverse proxy, say), edit trusted_domains in /DATA/AppData/nextcloud/html/config/config.php. Your files are in /DATA/AppData/nextcloud/html/data; to show other ZimaOS folders, use the External storage app. Background jobs run while someone uses the site; for cron, run docker exec -u www-data nextcloud php cron.php on a schedule.
