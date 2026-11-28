---
site: https://papra.app
source: https://github.com/papra-hq/papra
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: AUTH_IS_PASSWORD_RESET_ENABLED
    group: Sign-in
    default: "true"
    description: >-
      Show the forgot-password link. Needs email set up below.
  - name: AUTH_IS_EMAIL_VERIFICATION_REQUIRED
    group: Sign-in
    default: "false"
    description: >-
      true makes new users confirm their email address. Needs email set up below.
  - name: AUTH_FIRST_USER_AS_ADMIN
    group: Sign-in
    default: "true"
    description: >-
      Give the admin role to the first account made.
  - name: AUTH_ALLOWED_EMAIL_DOMAINS
    group: Sign-in
    default: ""
    description: >-
      Only these email domains may sign up, comma separated, like example.com.
  - name: AUTH_PROVIDERS_GITHUB_IS_ENABLED
    group: Sign-in
    default: "false"
    description: >-
      Sign in with GitHub. Needs AUTH_PROVIDERS_GITHUB_CLIENT_ID and AUTH_PROVIDERS_GITHUB_CLIENT_SECRET.
  - name: AUTH_PROVIDERS_GOOGLE_IS_ENABLED
    group: Sign-in
    default: "false"
    description: >-
      Sign in with Google. Needs AUTH_PROVIDERS_GOOGLE_CLIENT_ID and AUTH_PROVIDERS_GOOGLE_CLIENT_SECRET.
  - name: AUTH_PROVIDERS_CUSTOMS
    group: Sign-in
    default: ""
    description: >-
      Your own OAuth/OIDC providers (like Authentik or Pocket ID), as a JSON list. See the Papra docs.
  - name: AUTH_SECRET
    group: Sign-in
    default: ""
    description: >-
      Secret that signs sign-in sessions (32+ characters). Leave blank and IceStore makes one.
  - name: EMAILS_DRIVER
    group: Email
    default: "logger"
    description: >-
      logger only writes emails to the log. smtp sends them with the settings below; resend uses Resend.
  - name: EMAILS_FROM_ADDRESS
    group: Email
    default: "Papra <auth@mail.papra.app>"
    description: >-
      The sender shown on emails Papra sends.
  - name: SMTP_HOST
    group: Email
    default: ""
    description: >-
      Your mail server, when EMAILS_DRIVER is smtp.
  - name: SMTP_PORT
    group: Email
    default: "587"
    description: >-
      Your mail server's port.
  - name: SMTP_USER
    group: Email
    default: ""
    description: >-
      Mail server user name.
  - name: SMTP_PASSWORD
    group: Email
    default: ""
    description: >-
      Mail server password.
  - name: SMTP_SECURE
    group: Email
    default: "false"
    description: >-
      true for port 465 (TLS from the start).
  - name: INGESTION_FOLDER_IS_ENABLED
    group: Ingestion
    default: "false"
    description: >-
      Watch a folder and import every file put in it. The folder is ingestion inside the data folder.
  - name: INGESTION_FOLDER_POST_PROCESSING_STRATEGY
    group: Ingestion
    default: "delete"
    description: >-
      What to do with a file after import: delete or move.
  - name: DOCUMENTS_OCR_LANGUAGES
    group: Documents
    default: "eng"
    description: >-
      OCR languages, comma separated (Tesseract codes like eng,deu,fra).
  - name: DOCUMENTS_DELETED_DOCUMENTS_RETENTION_DAYS
    group: Documents
    default: "30"
    description: >-
      Days a deleted document stays in the trash.
  - name: TRUSTED_ORIGINS
    group: Web
    default: ""
    description: >-
      Other addresses allowed to sign in, comma separated, when you reach Papra by more than one address.
---

# Papra

Papra is a minimal document archive. Upload or email your receipts, bills, contracts and letters, and find them again later with full-text search and tags.

## Features

- Upload by drag and drop, by email or from a watched folder
- Text from PDFs and images (OCR) for full-text search
- Tags and rules that tag new documents for you
- Organizations to share documents with your family or team
- API, SDK and a phone app

## How to use

1. Set APP_BASE_URL to your ZimaOS IP address before you start.
2. Open Papra and create an account. The first account is the admin.
3. Set AUTH_IS_REGISTRATION_ENABLED to false so nobody else can sign up, then drop your first documents in.

## Before you install

Change APP_BASE_URL first: put your ZimaOS IP address in place of [ZIMAOS-IP-ADDRESS], so it reads like http://192.168.1.20:6890. Papra only accepts sign-ins from that address, so a wrong one means you can't sign in. Papra has no default login: the first account made becomes the admin, so make yours right after installing, then set AUTH_IS_REGISTRATION_ENABLED to false. Emails (password reset, invites) only go to the log until you set EMAILS_DRIVER to smtp with your mail server. This IceStore image makes the AUTH_SECRET for each install and keeps it in the data folder.
