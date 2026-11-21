---
site: https://www.grampsweb.org/
services:
  - { name: Web app, path: /, icon: globe }
  - { name: API, path: /api/, icon: code }
screenshots: [People, Fan chart, Map]
variables:
  - name: GRAMPSWEB_BASE_URL
    group: Server
    default: "http://localhost:6789"
    description: >-
      The address you open Gramps Web at, like http://192.168.1.20:6789.
      Used in links in emails.
  - name: GRAMPSWEB_REGISTRATION_DISABLED
    group: Server
    default: "False"
    description: >-
      Set to True so people can only join when you invite them.
  - name: GRAMPSWEB_PROXY_FIX_X_FOR
    group: Server
    default: ""
    description: >-
      Set to 1 when one reverse proxy is in front of Gramps Web.
  - name: GRAMPSWEB_DISABLE_TELEMETRY
    group: Server
    default: "False"
    description: >-
      Set to True to stop sending anonymous usage counts.
  - name: GUNICORN_NUM_WORKERS
    group: Server
    default: "2"
    description: >-
      How many web server processes to run. More is faster but uses more
      memory.
  - name: CELERY_CONCURRENCY
    group: Server
    default: "2"
    description: >-
      How many background jobs (imports, reports) may run at once.
  - name: GRAMPSWEB_BACKUP_KEEP
    group: Server
    default: "5"
    description: >-
      How many backups to keep for each tree.
  - name: GRAMPSWEB_EMAIL_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com, for invites and password
      resets.
  - name: GRAMPSWEB_EMAIL_PORT
    group: Email (SMTP)
    default: "465"
    description: >-
      Your email server port, usually 465 or 587.
  - name: GRAMPSWEB_EMAIL_HOST_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: GRAMPSWEB_EMAIL_HOST_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: GRAMPSWEB_EMAIL_USE_STARTTLS
    group: Email (SMTP)
    default: "False"
    description: >-
      Set to True for port 587 (STARTTLS).
  - name: GRAMPSWEB_DEFAULT_FROM_EMAIL
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: GRAMPSWEB_OIDC_ENABLED
    group: Single sign-on (OIDC)
    default: "False"
    description: >-
      Set to True to sign in with your own provider.
  - name: GRAMPSWEB_OIDC_ISSUER
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      Your provider's issuer address, like https://auth.example.com.
  - name: GRAMPSWEB_OIDC_CLIENT_ID
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client ID from your provider.
  - name: GRAMPSWEB_OIDC_CLIENT_SECRET
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client secret from your provider.
  - name: GRAMPSWEB_OIDC_NAME
    group: Single sign-on (OIDC)
    default: "OIDC"
    description: >-
      The name on the sign-in button.
---

# Gramps Web

Gramps Web is a genealogy app for building your family tree together. Add people, families, events, places and sources, attach photos and documents, and look at your tree as charts and maps. It works with Gramps on the desktop. The background worker and Redis are built in, so it is one container with nothing else to set up.

## Features

- People, families, events, places, sources and notes
- Photos and documents, with face tagging
- Family tree charts, fan charts, timelines and maps
- Import and export GEDCOM and Gramps files
- Users with roles, so family can view or edit
- Search, reports, DNA matches and an AI chat about your tree

## How to use

1. Open Gramps Web from your dashboard.
2. Make the owner account on the first page.
3. Import a GEDCOM or Gramps file under Import, or start adding people.
4. Invite your family from Settings and give them a role.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6789`. There is no account yet: the first page asks you to make the owner account. Your tree, media, users and the secret key are all kept in `/DATA/AppData/gramps-web/data`. Email for invites and password resets, single sign-on and the other settings are in the Variables tab and are added in the app settings. The first start takes a few minutes.
