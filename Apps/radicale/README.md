---
site: https://radicale.org
source: https://github.com/Kozea/Radicale
services:
  - { name: Web Page, path: /.web/, icon: globe }
  - { name: CalDAV / CardDAV, path: /, icon: server }
variables:
  - name: RADICALE_CONFIG_AUTH_TYPE
    group: Sign-in
    default: ""
    description: >-
      Leave blank for the IceStore login. Set none (no login), htpasswd, ldap or http_x_remote_user to manage sign-in yourself.
  - name: RADICALE_CONFIG_AUTH_DELAY
    group: Sign-in
    default: "1"
    description: >-
      Seconds to wait after a wrong password, to slow down guessing.
  - name: RADICALE_CONFIG_RIGHTS_TYPE
    group: Sharing
    default: "owner_only"
    description: >-
      Who sees what: owner_only, owner_write, authenticated or from_file.
  - name: RADICALE_CONFIG_STORAGE_MAX_SYNC_TOKEN_AGE
    group: Storage
    default: "2592000"
    description: >-
      How long sync tokens are kept, in seconds.
  - name: RADICALE_CONFIG_SERVER_MAX_CONTENT_LENGTH
    group: Server
    default: "100000000"
    description: >-
      Largest upload in bytes, for big calendar or contact imports.
  - name: RADICALE_CONFIG_LOGGING_LEVEL
    group: Advanced
    default: "info"
    description: >-
      Log detail: debug, info, warning, error or critical.
  - name: UID
    group: Files
    default: "2999"
    description: >-
      User id the files in the data folder belong to.
  - name: GID
    group: Files
    default: "2999"
    description: >-
      Group id the files in the data folder belong to.
---

# Radicale

Radicale is a small server that keeps your calendars, to-do lists and contacts, and syncs them with your phone and computer using the standard CalDAV and CardDAV protocols.

## Features

- Calendars, to-do lists and address books
- Works with Thunderbird, DAVx5, iOS, macOS and Evolution
- Plain files on disk, easy to back up
- Simple web page to make, import and share collections
- Login made for each IceStore install

## How to use

1. Open the app's log and find the password under CREDENTIALS.
2. Open Radicale, sign in with admin and that password, and make a calendar or address book.
3. In your phone or mail app, add a CalDAV or CardDAV account with the server http://[ZIMAOS-IP-ADDRESS]:6886 and the same login.

## Before you install

Upstream's image has no login, so this IceStore image turns one on: leave RADICALE_PASSWORD blank and the password is in the app's log under CREDENTIALS, or type your own. Other users can be added as htpasswd lines to the users file in AppData/radicale/data. Phones and computers must use http://[ZIMAOS-IP-ADDRESS]:6886, not localhost. iOS and macOS work over plain http on your home network; to sync from outside, put a reverse proxy with https in front. Any RADICALE_CONFIG_SECTION_KEY variable sets that Radicale setting (see the Radicale docs).
