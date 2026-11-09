---
name: Kith
source: https://github.com/dreed47/kith
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Home, A person, Chart, Census]
variables:
  - name: KITH_SITE_URL
    group: Server
    default: ""
    description: >-
      The site's address, like https://tree.example.org, for links in email.
  - name: KITH_SECURE_COOKIES
    group: Server
    default: ""
    description: >-
      Set to 1 once Kith is behind HTTPS, so the login cookie is only sent
      over HTTPS.
  - name: KITH_TRUSTED_PROXIES
    group: Server
    default: ""
    description: >-
      Set to 1 behind a reverse proxy, so login throttling sees each
      visitor's address.
  - name: KITH_THEME
    group: Server
    default: default
    description: >-
      The site's theme. Each person can still pick their own.
  - name: KITH_MAX_UPLOAD_MB
    group: Server
    default: "50"
    description: >-
      The largest photo or document upload, in MB.
  - name: KITH_UPDATE_CHECK
    group: Server
    default: ""
    description: >-
      Set to 0 to never check kithgenealogy.org for new versions.
  - name: KITH_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for account confirmations, password resets and
      invitations.
  - name: KITH_SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port.
  - name: KITH_SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server. Email is off until this is set.
  - name: KITH_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: KITH_MAIL_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The address email comes from.
  - name: KITH_ADMIN_USER
    group: First start
    default: admin
    description: >-
      The first admin's user name. Only used on the very first start.
---

# Kith

Kith is a private family history website you host yourself: your family tree, people's stories, photos and documents, for your family to see and add to. Built here from upstream's source, with MariaDB and the scheduled jobs inside one container.

## Features

- Family tree with people, families, events, places and sources
- Charts, a family hourglass, census and timeline views
- Photos and documents (PDF thumbnails), and a map of places
- Accounts for family members with their own rights, invitations and "what's new"
- GEDCOM and TNG import, five themes including large print

## How to use

1. Copy the admin password from the app's logs (CREDENTIALS box).
2. Open Kith from your dashboard and log in as `admin`.
3. Add people, or import a GEDCOM file from another program.
4. Invite your family from the admin page.

## Before you install

Nothing to set first. On the first start the container creates the database and an `admin` account with a password made for this install; both are in the app's logs, in the box marked CREDENTIALS, on every start. Change the password after you log in.

Upstream's scheduled jobs run inside the container: place coordinates nightly at 02:30, the version check at 04:00 and the weekly email on Mondays at 13:00 (your time zone). Before your family uses it from outside your home, put Kith behind HTTPS and set `KITH_SECURE_COOKIES=1` and `KITH_TRUSTED_PROXIES=1`. More settings are in the Variables tab.
