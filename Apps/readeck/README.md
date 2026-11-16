---
site: https://readeck.org
source: https://codeberg.org/readeck/readeck
screenshots: [Bookmarks]
variables:
  - name: READECK_SERVER_BASE_URL
    group: Server
    default: ""
    description: >-
      The address people open Readeck at, like http://192.168.1.20:6741. Used for links in emails and shares.
  - name: READECK_ALLOWED_HOSTS
    group: Server
    default: ""
    description: >-
      The only host names Readeck answers to, comma separated, like 192.168.1.20,readeck.example.com. Leave it out to answer to any.
  - name: READECK_TRUSTED_PROXIES
    group: Server
    default: ""
    description: >-
      Addresses of reverse proxies in front of Readeck, comma separated, like 172.17.0.0/16.
  - name: READECK_PUBLIC_SHARE_TTL
    group: Server
    default: "24"
    description: >-
      How many hours a public share link works.
  - name: READECK_WORKER_NUMBER
    group: Server
    default: ""
    description: >-
      How many pages are saved at the same time. Leave it out for one per CPU core.
  - name: READECK_MAIL_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for password resets and sending articles to an e-reader.
  - name: READECK_MAIL_PORT
    group: Email (SMTP)
    default: "25"
    description: >-
      The mail server's port.
  - name: READECK_MAIL_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server user name.
  - name: READECK_MAIL_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server password.
  - name: READECK_MAIL_ENCRYPTION
    group: Email (SMTP)
    default: ""
    description: >-
      starttls or ssltls, or leave it out for none.
  - name: READECK_MAIL_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender, like Readeck <readeck@example.com>.
  - name: READECK_LOG_LEVEL
    group: Logs
    default: "info"
    description: >-
      debug, info, warn or error.
---

# Readeck

Readeck saves the web pages you want to keep. It stores a clean copy of each article, with its pictures, so you can read it later, even after the original is gone. Highlight what matters, add labels and collections, and export to an e-book.

## Features

- A clean, readable copy of every article, kept forever
- Pictures and videos saved with the page
- Highlights, labels, favourites and collections
- Full-text search
- Export to EPUB for your e-reader, and an OPDS feed
- Browser extensions and mobile apps

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6741` and make your account. The first account is the admin.
2. Paste a web address into Save link.
3. Install the Readeck browser extension to save pages in one click.

## Before you install

Nothing needs to be set first, and it starts in a few seconds. Make your account right after installing: the first account becomes the admin. Readeck makes its own secret key on first start and keeps it in `config.toml` in the app folder. Email and the other settings are in the Variables tab; add them in the app settings.
