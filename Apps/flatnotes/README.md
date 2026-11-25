---
source: https://github.com/dullage/flatnotes
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: FLATNOTES_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The password. Made on first start and kept in the data folder when
      left out.
  - name: FLATNOTES_SECRET_KEY
    group: Security
    default: ""
    description: >-
      The key that signs sign-ins. Made on first start; changing it
      signs you out.
  - name: FLATNOTES_AUTH_TYPE
    group: Sign-in
    default: "password"
    description: >-
      password, totp (password plus two-factor codes, needs
      FLATNOTES_TOTP_KEY), read_only or none.
  - name: FLATNOTES_TOTP_KEY
    group: Sign-in
    default: ""
    description: >-
      A base32 key for two-factor codes when FLATNOTES_AUTH_TYPE is
      totp.
  - name: FLATNOTES_SESSION_EXPIRY_DAYS
    group: Sign-in
    default: "30"
    description: >-
      How many days a sign-in lasts.
  - name: FLATNOTES_QUICK_ACCESS_HIDE
    group: Home page
    default: "false"
    description: >-
      Set to true to hide the recent notes on the home page.
  - name: FLATNOTES_PATH_PREFIX
    group: Server
    default: ""
    description: >-
      Serve flatnotes under a sub-path, like /notes.
---

# flatnotes

flatnotes is a calm, distraction-free note app. Every note is a Markdown file in one folder, with no database, so you can open, sync and back them up with any tool. Fast full-text search and tags help you find them again.

## Features

- Notes saved as plain .md files in one folder
- Rich or Markdown editor, with images and attachments
- Full-text search, tags and wiki-style links
- Dark mode and a clean, mobile-friendly page
- Optional login with a password and two-factor codes

## How to use

1. Open flatnotes and sign in as admin with the password from the CREDENTIALS box in the app's logs.
2. Press New Note and start writing.

## Before you install

The password is made on first start and shown in the app's logs, in the box marked CREDENTIALS; to choose your own, add FLATNOTES_PASSWORD in the app settings. Your notes are plain Markdown files in /DATA/AppData/flatnotes/data, so you can also edit them with other apps.
