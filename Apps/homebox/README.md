---
site: https://homebox.software/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API, path: /api/v1/status, icon: code }
screenshots: [Locations]
variables:
  - name: HBOX_AUTH_API_KEY_PEPPER
    group: Server
    default: ""
    description: >-
      The secret API keys are hashed with, at least 32 characters. It is made
      on first start and kept in /data/secrets.env. Changing it voids every
      API key.
  - name: HBOX_LOG_LEVEL
    group: Server
    default: "info"
    description: >-
      How much goes in the log: trace, debug, info, warn or error.
  - name: HBOX_OPTIONS_HOSTNAME
    group: Server
    default: ""
    description: >-
      Your address, like homebox.example.com, for single sign-on links.
  - name: HBOX_OPTIONS_TRUST_PROXY
    group: Server
    default: "false"
    description: >-
      Set to true behind a reverse proxy.
  - name: HBOX_OPTIONS_GITHUB_RELEASE_CHECK
    group: Server
    default: "true"
    description: >-
      Set to false to stop checking for new versions.
  - name: HBOX_OPTIONS_AUTO_INCREMENT_ASSET_ID
    group: Items
    default: "true"
    description: >-
      Give every new item the next asset ID.
  - name: HBOX_MAILER_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: HBOX_MAILER_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server port, usually 587.
  - name: HBOX_MAILER_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: HBOX_MAILER_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: HBOX_MAILER_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: HBOX_OIDC_ENABLED
    group: Single sign-on (OIDC)
    default: "false"
    description: >-
      Set to true to sign in with your own provider.
  - name: HBOX_OIDC_ISSUER_URL
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      Your provider's issuer address, like https://auth.example.com.
  - name: HBOX_OIDC_CLIENT_ID
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client ID from your provider.
  - name: HBOX_OIDC_CLIENT_SECRET
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client secret from your provider.
  - name: HBOX_OIDC_ALLOWED_GROUPS
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      Groups allowed to sign in, comma separated.
  - name: HBOX_OIDC_AUTO_REDIRECT
    group: Single sign-on (OIDC)
    default: "false"
    description: >-
      Set to true to go straight to your provider.
  - name: HBOX_OPTIONS_ALLOW_LOCAL_LOGIN
    group: Single sign-on (OIDC)
    default: "true"
    description: >-
      Set to false to allow only single sign-on.
---

# HomeBox

HomeBox keeps a list of everything in your home: what it is, where it is, what you paid and when its warranty ends. Sort things by room and shelf, print QR labels, and find anything with a quick search. It uses a built-in SQLite database, so it is one container with nothing else to set up.

## Features

- Items with photos, receipts, manuals and custom fields
- Locations inside locations, like room, cupboard, shelf
- Labels, and QR codes you can print and scan
- Purchase prices, warranties and maintenance logs
- Search, CSV import and export, and reports
- Shared with your household, with single sign-on (OIDC)

## How to use

1. Open HomeBox from your dashboard.
2. Click Register and make your account.
3. Add your rooms and places under Locations.
4. Click Create to add an item, with a photo and its receipt.
5. Invite your household from your home's settings.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6781`. There is no account yet: click Register. When everyone has an account, set `HBOX_OPTIONS_ALLOW_REGISTRATION` to `false`. The secret HomeBox needs to start is made for you on first start and kept in `/DATA/AppData/homebox/data`. Email, single sign-on and the other settings are in the Variables tab and are added in the app settings. It is ready in under a minute.
