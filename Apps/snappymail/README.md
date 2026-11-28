---
screenshots: [Inbox, Compose]
site: https://snappymail.eu/
services:
  - { name: Webmail, path: /, icon: mail }
  - { name: Admin panel, path: "/?admin", icon: server }
variables:
  - name: MEMORY_LIMIT
    group: Server
    default: "128M"
    description: >-
      Memory PHP may use. Raise it for big mailboxes.
  - name: DEBUG
    group: Server
    default: "false"
    description: >-
      Set to true for more detail in the log.
---

# SnappyMail

SnappyMail is webmail for the email accounts you already have. Point it at any IMAP and SMTP server, like Gmail, Outlook, Fastmail or your own, and read and send mail from a clean, fast web page. It keeps no copy of your mail: it all stays on your mail server.

## Features

- Works with any IMAP and SMTP mail server
- Several accounts and identities in one place
- Threads, search, filters (Sieve) and folders
- OpenPGP and S/MIME to sign and encrypt
- Contacts with CardDAV sync
- Plugins, themes and two-step sign-in

## How to use

1. Open the app's files in /DATA/AppData/snappymail/data and find _data_/_default_/admin_password.txt for the admin password.
2. Open http://[ZIMAOS-IP-ADDRESS]:6786/?admin and sign in as admin with that password.
3. Under Domains, add your mail provider's IMAP and SMTP servers.
4. Open http://[ZIMAOS-IP-ADDRESS]:6786 and sign in with your email address and password.

## Before you install

You can install it as it is. The admin password is made on first start and saved in `/DATA/AppData/snappymail/data/_data_/_default_/admin_password.txt` (user name `admin`); open the Files app to read it, then go to `http://[ZIMAOS-IP-ADDRESS]:6786/?admin` and add your mail servers under Domains. `SECURE_COOKIES` is off so sign-in works over plain http; turn it on once you only use SnappyMail over https behind a reverse proxy. It is ready in under a minute.
