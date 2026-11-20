---
site: https://www.bookstackapp.com/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API docs, path: /api/docs, icon: code }
screenshots: [Books, A book, Reading a page, Editing a page, Image manager]
variables:
  - name: APP_KEY
    group: Server
    default: ""
    description: >-
      The key that protects sign-in sessions. It is made on first start and
      kept in the config folder as .app_key. Only set it to use your own.
  - name: APP_TIMEZONE
    group: Server
    default: ""
    description: >-
      The time zone for dates in BookStack, like Europe/Berlin. Leave it out
      to use TZ.
  - name: APP_LANG
    group: Server
    default: en
    description: >-
      The language for new users and visitors, like de, fr or es. Each user
      can pick their own in My Account.
  - name: APP_DEFAULT_DARK_MODE
    group: Server
    default: "false"
    description: >-
      Set to true to show BookStack dark for everyone who hasn't picked a
      mode.
  - name: SESSION_LIFETIME
    group: Server
    default: "120"
    description: >-
      Minutes until people who stopped using BookStack are signed out.
  - name: QUEUE_CONNECTION
    group: Server
    default: sync
    description: >-
      Set to database so emails and webhooks are sent in the background
      instead of while you wait.
  - name: MAIL_HOST
    group: Email (SMTP)
    default: localhost
    description: >-
      Your email server, like smtp.gmail.com. Needed for password resets and
      invites.
  - name: MAIL_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: MAIL_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: MAIL_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: MAIL_ENCRYPTION
    group: Email (SMTP)
    default: ""
    description: >-
      tls for port 587, ssl for port 465. Leave it out for none.
  - name: MAIL_FROM
    group: Email (SMTP)
    default: bookstack@example.com
    description: >-
      The address emails are sent from.
  - name: MAIL_FROM_NAME
    group: Email (SMTP)
    default: BookStack
    description: >-
      The name emails are sent from.
  - name: MAIL_VERIFY_SSL
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false if your email server uses a self-signed certificate.
  - name: AUTH_METHOD
    group: Sign in with OIDC
    default: standard
    description: >-
      Set to oidc to sign in with Pocket ID, Authentik, Keycloak or another
      OIDC provider instead of email and password.
  - name: OIDC_NAME
    group: Sign in with OIDC
    default: SSO
    description: >-
      The name on the sign-in button.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your OIDC provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your OIDC provider.
  - name: OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's address, like https://id.example.com. The redirect
      address to enter there is your BookStack address plus /oidc/callback.
  - name: OIDC_ISSUER_DISCOVER
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true so BookStack finds the provider's settings on its own.
      Almost always what you want.
  - name: OIDC_DISPLAY_NAME_CLAIMS
    group: Sign in with OIDC
    default: name
    description: >-
      Which field from the provider becomes the user's name.
  - name: OIDC_USER_TO_GROUPS
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to give users BookStack roles from their provider groups.
  - name: OIDC_GROUPS_CLAIM
    group: Sign in with OIDC
    default: groups
    description: >-
      Which field from the provider lists the user's groups.
  - name: ALLOWED_IFRAME_HOSTS
    group: Embedding
    default: ""
    description: >-
      Sites allowed to show BookStack inside a frame, space separated, like
      https://dash.example.com.
  - name: ALLOWED_IFRAME_SOURCES
    group: Embedding
    default: "https://*.draw.io https://*.youtube.com https://*.youtube-nocookie.com https://*.vimeo.com"
    description: >-
      Sites whose videos and pages may be embedded in BookStack pages, space
      separated.
---

# BookStack

BookStack is a simple wiki for your notes and documentation. You write pages, group them into chapters and books, and put the books on shelves. MariaDB is built in, so it is one container with nothing else to set up.

## Features

- Easy editor that works like a word processor, or write in Markdown
- Shelves, books, chapters and pages, with search across all of them
- Images, file attachments and drawings with diagrams.net
- Page history, so you can see and undo every change
- Users, roles and rights per book, plus two-factor sign-in
- Sign in with OIDC (Pocket ID, Authentik), LDAP or SAML, and a REST API

## How to use

1. Open BookStack from your dashboard.
2. Sign in as admin@admin.com with the password from the app's logs (the box marked CREDENTIALS).
3. Open My Account and change the email and password to your own.
4. Click Books, then Create New Book, and add your first page.
5. Under Settings, Users, invite the people who should read or write.

## Before you install

You can install it as it is. A password for the first admin (admin@admin.com) is made on first start and shown in the app's logs, in the box marked CREDENTIALS; it is also saved in `/DATA/AppData/bookstack/config/.admin_password`. Open it at `http://[ZIMAOS-IP-ADDRESS]:6758`. `APP_URL` is empty, so BookStack follows the address in your browser; set it only when you use a domain, like `https://wiki.example.com`. Email, sign-in with OIDC and the other settings are in the Variables tab and are added in the app settings. The first start takes about 2 minutes while the database is made.
