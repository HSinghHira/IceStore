---
site: https://docs.paperless-ngx.com/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API, path: /api/, icon: code }
screenshots: [Dashboard, Documents, Editing a document, Search results, Dark mode]
variables:
  - name: PAPERLESS_URL
    group: Server
    default: ""
    description: >-
      The address you open Paperless at from outside, like
      https://paperless.example.com. Set it when you put Paperless behind a
      domain, or sign-in fails with a CSRF error.
  - name: PAPERLESS_TIME_ZONE
    group: Server
    default: ""
    description: >-
      The time zone for document dates, like Europe/Berlin. Leave it out to
      use TZ.
  - name: PAPERLESS_SECRET_KEY
    group: Server
    default: ""
    description: >-
      The key that signs sign-in sessions. It is made on first start and kept
      in the data folder as .secret_key. Only set it to use your own.
  - name: PAPERLESS_WEBSERVER_WORKERS
    group: Server
    default: "1"
    description: >-
      How many web server processes to run. Raise it for many users.
  - name: PAPERLESS_TASK_WORKERS
    group: Server
    default: "1"
    description: >-
      How many documents are processed at the same time.
  - name: PAPERLESS_ADMIN_MAIL
    group: Sign-up and accounts
    default: root@localhost
    description: >-
      The email address of the first admin account.
  - name: PAPERLESS_ACCOUNT_ALLOW_SIGNUPS
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone make an account on the sign-in page.
  - name: PAPERLESS_DISABLE_REGULAR_LOGIN
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to hide the password form, so people only sign in with a
      provider from PAPERLESS_SOCIALACCOUNT_PROVIDERS.
  - name: PAPERLESS_APPS
    group: Sign in with OIDC or Google
    default: ""
    description: >-
      Sign-in providers to turn on, like
      allauth.socialaccount.providers.openid_connect for OIDC (Pocket ID,
      Authentik) or allauth.socialaccount.providers.google.
  - name: PAPERLESS_SOCIALACCOUNT_PROVIDERS
    group: Sign in with OIDC or Google
    default: ""
    description: >-
      The provider settings as JSON, with your client ID, secret and server
      address. See the Paperless docs, section "OpenID Connect".
  - name: PAPERLESS_SOCIAL_AUTO_SIGNUP
    group: Sign in with OIDC or Google
    default: "false"
    description: >-
      Set to true to make an account on the first sign-in with a provider.
  - name: PAPERLESS_OCR_LANGUAGES
    group: Text recognition (OCR)
    default: ""
    description: >-
      Extra languages to install on start, separated by spaces, like tur ces.
      English, German, Italian, Spanish and French are already there.
  - name: PAPERLESS_OCR_MODE
    group: Text recognition (OCR)
    default: auto
    description: >-
      auto reads pages that have no text yet; force reads every page again;
      skip only reads pages without text and keeps the original.
  - name: PAPERLESS_OCR_SKIP_ARCHIVE_FILE
    group: Text recognition (OCR)
    default: never
    description: >-
      Set to with_text or always to skip making the searchable PDF copy and
      save disk space.
  - name: PAPERLESS_FILENAME_FORMAT
    group: Files and inbox
    default: ""
    description: >-
      How stored files are named and put in folders, like
      {{ created_year }}/{{ correspondent }}/{{ title }}. Leave it out to
      number them.
  - name: PAPERLESS_CONSUMER_RECURSIVE
    group: Files and inbox
    default: "false"
    description: >-
      Set to true to also pick up files in folders inside the consume folder.
  - name: PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS
    group: Files and inbox
    default: "false"
    description: >-
      Set to true (with PAPERLESS_CONSUMER_RECURSIVE) to tag each document
      with the names of the folders it was in.
  - name: PAPERLESS_CONSUMER_POLLING_INTERVAL
    group: Files and inbox
    default: "0"
    description: >-
      Check the consume folder every this many seconds instead of watching
      it. Set to 60 if new files on a network share are not noticed.
  - name: PAPERLESS_EMPTY_TRASH_DELAY
    group: Files and inbox
    default: "30"
    description: >-
      Days before deleted documents are removed from the trash for good.
  - name: PAPERLESS_EMAIL_HOST
    group: Email (SMTP)
    default: localhost
    description: >-
      Your email server, for password resets and workflow emails, like
      smtp.gmail.com.
  - name: PAPERLESS_EMAIL_PORT
    group: Email (SMTP)
    default: "25"
    description: >-
      Your email server port, usually 587 (with TLS) or 465 (with SSL).
  - name: PAPERLESS_EMAIL_HOST_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: PAPERLESS_EMAIL_HOST_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: PAPERLESS_EMAIL_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address on emails. Leave it out to use
      PAPERLESS_EMAIL_HOST_USER.
  - name: PAPERLESS_EMAIL_USE_TLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for port 587 (STARTTLS).
  - name: PAPERLESS_EMAIL_USE_SSL
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for port 465.
  - name: PAPERLESS_AI_ENABLED
    group: AI
    default: "false"
    description: >-
      Set to true for AI suggestions and the document chat. Also set
      PAPERLESS_AI_LLM_BACKEND and PAPERLESS_AI_LLM_MODEL.
  - name: PAPERLESS_AI_LLM_BACKEND
    group: AI
    default: ""
    description: >-
      openai or ollama.
  - name: PAPERLESS_AI_LLM_MODEL
    group: AI
    default: ""
    description: >-
      The model to use, like gpt-4o-mini or llama3.1.
  - name: PAPERLESS_AI_LLM_API_KEY
    group: AI
    default: ""
    description: >-
      Your OpenAI (or compatible) API key.
  - name: PAPERLESS_AI_LLM_ENDPOINT
    group: AI
    default: ""
    description: >-
      The address of your Ollama or OpenAI-compatible server, like
      http://192.168.1.20:11434.
  - name: PAPERLESS_LOGROTATE_MAX_BACKUPS
    group: Logs
    default: "20"
    description: >-
      How many old log files to keep in the data folder.
---

# Paperless-ngx

Paperless-ngx turns your pile of paper into a searchable online archive. Scan a letter or drop in a PDF, and it reads the text, files it and tags it for you. Redis and a SQLite database are built in, so it is one container with nothing else to set up.

## Features

- Reads the text of every scan (OCR) in over 100 languages and makes a searchable PDF copy
- Learns how you file things and adds tags, correspondents and document types on its own
- Full-text search, saved views and a dashboard of your newest documents
- Picks up files from its inbox folder, from email accounts, from the upload button or from the mobile apps
- Users, groups and sharing rights, plus two-factor sign-in
- Workflows that run on new documents, and a REST API

## How to use

1. Open Paperless-ngx from your dashboard.
2. Sign in as `admin` with the password from the app's logs (the box marked CREDENTIALS).
3. Drag a PDF or a photo of a letter onto the page to upload it.
4. Or put files in `/DATA/AppData/paperless-ngx/consume` with the Files app. Paperless picks them up within a minute.
5. Open a document to check its title, date and tags. Paperless gets better at guessing them the more you correct it.

Office files (Word, Excel) and emails as `.eml` need two more services (Tika and Gotenberg) that are not inside this app; PDFs and images work. For those, install [Paperless-ngx Full](https://icestore.hsinghhira.me/app/paperless-ngx-full/), which has Tika, Gotenberg and PostgreSQL inside.

## Before you install

Set `PAPERLESS_OCR_LANGUAGE` to the language of your documents (`eng`, `deu`, `fra`...). Leave `PAPERLESS_ADMIN_PASSWORD` empty and a password is made for you on first start; it is shown in the app's logs in the box marked CREDENTIALS, and saved in `/DATA/AppData/paperless-ngx/data/.admin_password`. Open it from other devices at `http://[ZIMAOS-IP-ADDRESS]:6748`. If you put it behind a domain, set `PAPERLESS_URL`. More settings (email, sign-in with OIDC or Google, file naming, AI) are in the Variables tab; add them in the app settings. The first start takes about 3 minutes.
