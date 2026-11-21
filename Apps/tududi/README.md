---
site: https://tududi.com/
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Light mode, Dark mode]
variables:
  - name: BASE_URL
    group: Server
    default: ""
    description: >-
      The address people open tududi at, like http://192.168.1.20:6763 or
      https://tasks.example.com. Needed for sign-in with OIDC and for links
      in emails.
  - name: TUDUDI_ALLOWED_ORIGINS
    group: Server
    default: ""
    description: >-
      Other sites allowed to call tududi's API from a browser, comma
      separated. Not needed for tududi itself.
  - name: TUDUDI_TRUST_PROXY
    group: Server
    default: "false"
    description: >-
      Set to true when tududi is behind a reverse proxy.
  - name: TUDUDI_SESSION_SECRET
    group: Server
    default: ""
    description: >-
      The key that signs sign-in cookies. It is made on first start and kept
      in /data/secrets.env. Only set it to use your own.
  - name: FILE_UPLOAD_LIMIT_MB
    group: Server
    default: "10"
    description: >-
      The biggest attachment people can upload, in MB.
  - name: PASSWORD_AUTH_ENABLED
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn off email and password sign-in, so people only
      sign in with OIDC.
  - name: ENABLE_EMAIL
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to send emails: password resets and invites.
  - name: EMAIL_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: EMAIL_SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: EMAIL_SMTP_SECURE
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for port 465.
  - name: EMAIL_SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: EMAIL_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: EMAIL_FROM_ADDRESS
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: EMAIL_FROM_NAME
    group: Email (SMTP)
    default: Tududi
    description: >-
      The name emails are sent from.
  - name: OIDC_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to sign in with Pocket ID, Authentik, Google or another
      OIDC provider. Also set BASE_URL. You can set providers up in Profile
      instead.
  - name: OIDC_PROVIDER_NAME
    group: Sign in with OIDC
    default: ""
    description: >-
      The name on the sign-in button, like Pocket ID.
  - name: OIDC_PROVIDER_SLUG
    group: Sign in with OIDC
    default: ""
    description: >-
      A short id for the provider, like pocketid.
  - name: OIDC_ISSUER_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's address, like https://id.example.com.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your provider.
  - name: OIDC_SCOPE
    group: Sign in with OIDC
    default: openid profile email
    description: >-
      The scopes to ask for.
  - name: OIDC_AUTO_PROVISION
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false so only people who already have an account can sign in
      with OIDC.
  - name: TELEGRAM_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to show the Telegram bot settings, so people can add tasks
      from Telegram.
  - name: CALDAV_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to sync tasks with CalDAV apps and servers.
  - name: CALDAV_ALLOW_PRIVATE_HOSTS
    group: Features
    default: "false"
    description: >-
      Set to true to sync with CalDAV servers on your own network, like
      Nextcloud or Radicale on your ZimaOS.
  - name: LLM_API_KEY
    group: AI
    default: ""
    description: >-
      An OpenAI (or compatible) API key for the daily brief and task
      insights. Each user can also set their own in Profile.
  - name: LLM_BASE_URL
    group: AI
    default: https://api.openai.com/v1
    description: >-
      The API address, for example your Ollama server's /v1.
  - name: LLM_MODEL
    group: AI
    default: gpt-4o-mini
    description: >-
      The model to use.
---

# tududi

tududi keeps your tasks, projects and notes in one place. Group projects into areas of your life, see what is due today, and add tasks from your phone. PostgreSQL is built in, so it is one container with nothing else to set up.

## Features

- Tasks with due dates, priorities, repeats and subtasks
- Projects with tasks and notes, grouped into areas
- Today view and a daily overview of what is due
- Add tasks from Telegram, and sync with CalDAV apps
- Installable on your phone, works offline
- Sign in with OIDC (Pocket ID, Authentik), in 26 languages

## How to use

1. Open tududi from your dashboard.
2. Sign in with the email and the password from the app's logs (the box marked CREDENTIALS).
3. Change your password under Profile.
4. Make an area, a project, and add your first tasks.
5. Check the Today view each morning.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6763`. The first account is `TUDUDI_USER_EMAIL` (`admin@example.com` unless you change it) with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/tududi/data/.admin_password`. Both are only used while tududi has no users yet. Set `BASE_URL` to the address you use when you turn on email or sign-in with OIDC. Those and the other settings are in the Variables tab and are added in the app settings. The first start takes about 2 minutes.
