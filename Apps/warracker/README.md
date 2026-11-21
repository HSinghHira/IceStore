---
site: https://github.com/sassanix/Warracker
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Dashboard, Status dashboard, Table view]
variables:
  - name: FRONTEND_URL
    group: Server
    default: "http://localhost:6769"
    description: >-
      The address you open Warracker at, like http://192.168.1.20:6769. Used
      in email links and for single sign-on redirects.
  - name: TRUST_PROXY_HEADERS
    group: Server
    default: "false"
    description: >-
      Set to true only when a reverse proxy on a public IP is in front of
      Warracker. Proxies on your own network are trusted already.
  - name: WARRACKER_MEMORY_MODE
    group: Server
    default: "optimized"
    description: >-
      optimized, or ultra-light for small machines with little memory.
  - name: JWT_EXPIRATION_HOURS
    group: Server
    default: "24"
    description: >-
      How many hours people stay signed in.
  - name: PHOTO_FETCH_TIMEOUT_SECONDS
    group: Server
    default: "60"
    description: >-
      How long to wait when fetching a product photo from a link, in seconds.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com, for password resets and
      reminders.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: SMTP_FROM_ADDRESS
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: SMTP_USE_TLS
    group: Email (SMTP)
    default: "true"
    description: >-
      Use STARTTLS. Set to false for a server without it.
  - name: APPRISE_ENABLED
    group: Apprise reminders
    default: "false"
    description: >-
      Set to true to send reminders through Apprise.
  - name: APPRISE_URLS
    group: Apprise reminders
    default: ""
    description: >-
      Where to send reminders, comma separated Apprise links like
      ntfy://topic or discord://webhook_id/webhook_token.
  - name: APPRISE_EXPIRATION_DAYS
    group: Apprise reminders
    default: "7,30"
    description: >-
      How many days before a warranty ends to remind you, comma separated.
  - name: APPRISE_NOTIFICATION_TIME
    group: Apprise reminders
    default: "09:00"
    description: >-
      The time of day reminders are sent, as HH:MM.
  - name: APPRISE_TITLE_PREFIX
    group: Apprise reminders
    default: "[Warracker]"
    description: >-
      Text at the start of every reminder title.
  - name: OIDC_PROVIDER_NAME
    group: Single sign-on (OIDC)
    default: "oidc"
    description: >-
      The name shown on the sign-in button.
  - name: OIDC_CLIENT_ID
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client ID from your sign-in provider.
  - name: OIDC_CLIENT_SECRET
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client secret from your sign-in provider.
  - name: OIDC_ISSUER_URL
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      Your provider's issuer address, like
      https://auth.example.com/realms/home.
  - name: OIDC_SCOPE
    group: Single sign-on (OIDC)
    default: "openid email profile"
    description: >-
      The scopes Warracker asks for.
  - name: OIDC_ADMIN_GROUP
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      People in this group become admins (needs the groups scope).
---

# Warracker

Warracker keeps every warranty in one place: what you bought, when, the receipt and manual, and when the warranty runs out. It reminds you before a warranty ends. The PostgreSQL database is built in, so it is one container with nothing else to set up.

## Features

- Warranties with purchase date, length, price, serial numbers and notes
- Receipts, invoices, manuals and photos attached to each item
- Reminders by email or Apprise (Discord, Telegram, ntfy and more)
- Dashboard of what is active, ending soon and expired
- Tags, search, CSV import and export
- Several users, with an admin, and single sign-on (OIDC)
- Paperless-ngx link for your documents

## How to use

1. Open Warracker from your dashboard.
2. Click Register and make your account. The first account is the admin.
3. Click Add Warranty and fill in the product, the dates and the receipt.
4. Turn on reminders in Settings.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6769`. There is no account yet: click Register, and the first account you make is the admin. The database password and the secret key are made for you on first start and kept in `/DATA/AppData/warracker/data`. Email, Apprise reminders, single sign-on and the address used in email links (`FRONTEND_URL`) are in the Variables tab and are added in the app settings. It is ready in about a minute.
