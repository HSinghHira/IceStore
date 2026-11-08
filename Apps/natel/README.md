---
site: https://natel.app
source: https://github.com/KewinDousse/natel
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Contacts]
variables:
  - name: NATEL_UPDATE_CHECKS
    group: Server
    default: "true"
    description: >-
      Set to false to stop Natel checking for new releases. No contacts or
      passwords are ever sent.
  - name: NATEL_HTTPS_ONLY_COOKIE
    group: Server
    default: "false"
    description: >-
      Set to true when you open Natel only through an https address (a
      reverse proxy). Sign-in over plain http then stops working.
  - name: NATEL_TRUSTED_PROXIES
    group: Server
    default: ""
    description: >-
      The address of your reverse proxy, like 172.16.0.0/12, so your CardDAV
      server sees each person's own address.
---

# Natel

Natel is a web editor for the contacts on your CardDAV server, like Radicale, Baikal or Xandikos. The server keeps your contacts in sync across your phones and computers; Natel lets you edit them in a browser. It stores nothing itself: you sign in with your CardDAV account.

## Features

- Search contacts and browse several address books
- Create, edit and delete contacts; add and crop photos
- Groups that work with Apple, DAVx5 and Nextcloud
- Import and export .vcf files
- Phone and desktop layouts, light and dark themes
- Keeps every field it doesn't show, and warns when a contact changed on another device

## How to use

1. Open Natel from your dashboard.
2. Sign in with your CardDAV user name and password.
3. Pick an address book and edit your contacts.

## Before you install

**You must set `CARDDAV_URL` first.** It starts as the example `https://dav.example.com`: put in your CardDAV server's address and port, without a path, like `http://192.168.1.20:5232` for Radicale or `https://dav.example.com` for Baikal. Natel doesn't host address books, so you need a CardDAV server already. Natel is beta software: export each address book from its address-book menu, or back up your CardDAV server, before your first edit. Natel has no accounts of its own and checks every sign-in with your CardDAV server; Xandikos checks no password by default, so protect it first. The other settings are in the Variables tab.
