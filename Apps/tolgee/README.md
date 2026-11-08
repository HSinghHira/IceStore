---
site: https://tolgee.io
source: https://github.com/tolgee/tolgee-platform
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API docs, path: /swagger-ui.html, icon: code }
screenshots: [Translations, Machine translation, Suggestions, QA checks, Translation memory]
variables:
  - name: TOLGEE_AUTHENTICATION_INITIAL_USERNAME
    group: Sign-up and accounts
    default: "admin"
    description: >-
      The admin user name, made on the first start. Set it before the first
      start.
  - name: TOLGEE_AUTHENTICATION_REGISTRATIONS_ALLOWED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone make an account. Otherwise the admin invites
      people.
  - name: TOLGEE_AUTHENTICATION_NEEDS_EMAIL_VERIFICATION
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so new accounts must confirm their email. Needs email
      (SMTP).
  - name: TOLGEE_AUTHENTICATION_USER_CAN_CREATE_ORGANIZATIONS
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false so only the admin can create organizations.
  - name: TOLGEE_AUTHENTICATION_CREATE_DEMO_FOR_INITIAL_USER
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to skip the demo project for the admin.
  - name: TOLGEE_AUTHENTICATION_ENABLED
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn sign-in off: everyone who opens Tolgee is the
      admin. Only for a computer nobody else can reach.
  - name: TOLGEE_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com. Leave it out and no emails are
      sent.
  - name: TOLGEE_SMTP_PORT
    group: Email (SMTP)
    default: "25"
    description: >-
      Your email server port, usually 587 or 465.
  - name: TOLGEE_SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: TOLGEE_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: TOLGEE_SMTP_AUTH
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true when your email server needs a user name and password.
  - name: TOLGEE_SMTP_TLS_ENABLED
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for STARTTLS (port 587).
  - name: TOLGEE_SMTP_SSL_ENABLED
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for TLS from the start (port 465).
  - name: TOLGEE_SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender, like Tolgee <no-reply@example.com>.
  - name: TOLGEE_AUTHENTICATION_GITHUB_CLIENT_ID
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      GitHub OAuth app client ID. Its callback is
      PUBLIC_URL/login/auth_callback/github.
  - name: TOLGEE_AUTHENTICATION_GITHUB_CLIENT_SECRET
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      GitHub OAuth app client secret.
  - name: TOLGEE_AUTHENTICATION_GOOGLE_CLIENT_ID
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      Google OAuth client ID. Its redirect URI is
      PUBLIC_URL/login/auth_callback/google.
  - name: TOLGEE_AUTHENTICATION_GOOGLE_CLIENT_SECRET
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      Google OAuth client secret.
  - name: TOLGEE_MACHINE_TRANSLATION_GOOGLE_API_KEY
    group: Machine translation
    default: ""
    description: >-
      Your Google Cloud Translation API key.
  - name: TOLGEE_MACHINE_TRANSLATION_DEEPL_AUTH_KEY
    group: Machine translation
    default: ""
    description: >-
      Your DeepL API key.
  - name: TOLGEE_MAX_UPLOAD_FILE_SIZE
    group: Server
    default: "51200"
    description: >-
      The largest file you can import or upload, in kilobytes.
  - name: JAVA_OPTS
    group: Server
    default: ""
    description: >-
      Extra Java options, like -Xmx2g to give Tolgee more memory.
---

# Tolgee

Tolgee is a localization platform: keep every translation of your app in one place, translate in context and ship new texts without a new release. This is Tolgee in a single container, with PostgreSQL inside, one port and one data folder. The admin password is made for you on first start.

## Features

- Translation editor with keys, languages, tags, comments and screenshots
- In-context translating: change texts right inside your running app with the Tolgee SDKs
- Machine translation (Google, DeepL, AWS, Azure or an LLM) and translation memory
- Import and export JSON, XLIFF, PO, Android, iOS and more; CLI and REST API
- Teams, organizations, permissions, tasks and review states
- Glossaries, QA checks and branching
- PostgreSQL inside

## How to use

1. Open Tolgee from your dashboard.
2. Sign in as `admin` with the password from the app log.
3. Open the demo project, or create your own and add languages.

## Before you install

Leave `ADMIN_PASSWORD` blank to get a random one, shown in the app log in the box marked CREDENTIALS. Tolgee works from every device with `PUBLIC_URL` left as it is; for links in emails and sign-in with GitHub or Google, set it to `http://[ZIMAOS-IP-ADDRESS]:6192`, like `http://192.168.1.20:6192`. Sign-up is off: invite people from your organization's Members page, or turn on `TOLGEE_AUTHENTICATION_REGISTRATIONS_ALLOWED`. Email, machine translation and the other settings are in the Variables tab; add them in the app settings. The first start takes about 3 minutes.
