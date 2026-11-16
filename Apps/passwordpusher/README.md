---
site: https://pwpush.com
source: https://github.com/pglombardo/PasswordPusher
screenshots: [New push]
variables:
  - name: PWP__ALLOW_ANONYMOUS
    group: Accounts
    default: "true"
    description: >-
      Set to false so only signed-in users can make pushes.
  - name: PWP__DISABLE_SIGNUPS
    group: Accounts
    default: "false"
    description: >-
      Set to true to stop new sign-ups once your accounts exist.
  - name: PWP__ENABLE_FILE_PUSHES
    group: Features
    default: "true"
    description: >-
      Set to false to turn off sharing files.
  - name: PWP__ENABLE_URL_PUSHES
    group: Features
    default: "true"
    description: >-
      Set to false to turn off sharing links.
  - name: PWP__ENABLE_QR_PUSHES
    group: Features
    default: "true"
    description: >-
      Set to false to turn off QR code pushes.
  - name: PWP__PW__EXPIRE_AFTER_DAYS_DEFAULT
    group: Features
    default: "7"
    description: >-
      How many days a text push lasts, unless the person picks another.
  - name: PWP__PW__EXPIRE_AFTER_VIEWS_DEFAULT
    group: Features
    default: "5"
    description: >-
      How many views a text push lasts, unless the person picks another.
  - name: PWP__DEFAULT_LOCALE
    group: Features
    default: "en"
    description: >-
      The language of the web page, like de, fr or es.
  - name: PWP__HOST_DOMAIN
    group: Server
    default: ""
    description: >-
      The address people open Password Pusher at, without http://, like 192.168.1.20:6747. Used for links in emails.
  - name: PWP__HOST_PROTOCOL
    group: Server
    default: "https"
    description: >-
      http or https, for links in emails. Set to http if you open it without a domain.
  - name: PWP__MAIL__SMTP_ADDRESS
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for sign-up confirmations and password resets.
  - name: PWP__MAIL__SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      The mail server's port.
  - name: PWP__MAIL__SMTP_USER_NAME
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server user name.
  - name: PWP__MAIL__SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server password.
  - name: PWP__MAIL__MAILER_SENDER
    group: Email (SMTP)
    default: ""
    description: >-
      The sender, like Password Pusher <pwpush@example.com>.
  - name: SECRET_KEY_BASE
    group: Security
    default: ""
    description: >-
      Made on first start and kept in the storage folder. Only set it to move an existing install; it must not change afterwards.
---

# Password Pusher

Password Pusher shares passwords, notes, files and links the safe way. Paste a secret, and you get a link that stops working after a few views or days, so the secret doesn't sit in an email or chat forever.

## Features

- Links that expire after a number of days or views
- Text, files, URLs and QR codes
- Optional unlock phrase the reader must type
- Encrypted in the database, deleted when it expires
- Accounts with an audit log of who opened what
- A JSON API and command-line tool

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6747` in your browser.
2. Paste a password or note, pick how long it lasts, and press Push It.
3. Send the link. It stops working after the views or days you chose.

## Before you install

Nothing needs to be set first. The first start sets up the database and makes this install's secret key, which is kept in the storage folder; back that folder up. Anyone who can reach the page can make pushes; to limit that, turn off anonymous pushes or sign-ups in the Variables tab. This image is for amd64 (Intel and AMD) boxes only. Email and the other settings are in the Variables tab; add them in the app settings.
