---
site: https://appflowy.com
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Console, path: /console, icon: server }
  - { name: Mail Viewer, path: /mail, icon: mail }
variables:
  - name: GOTRUE_DISABLE_SIGNUP
    group: Sign-up and accounts
    default: 'false'
    description: >-
      Set to true so only people you invite can join. Default: anyone who can
      open the page can sign up.
  - name: GOTRUE_MAILER_AUTOCONFIRM
    group: Sign-up and accounts
    default: 'true'
    description: >-
      Set to false to make new users click a link in an email before they can
      sign in. Needs a real email server (SMTP_HOST). Default: no email check.
  - name: GOTRUE_JWT_EXP
    group: Sign-up and accounts
    default: '604800'
    description: >-
      How long people stay signed in, in seconds. Default: 7 days.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com. AppFlowy uses email for sign-in
      links, invites and password resets. Leave it out and emails go to the
      built-in mail viewer at /mail and never leave your server.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: '465'
    description: >-
      Your email server port, usually 465 or 587.
  - name: SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The username for your email server.
  - name: SMTP_PASS
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server. For Gmail, use an app password.
  - name: SMTP_EMAIL
    group: Email (SMTP)
    default: ""
    description: >-
      The "from" address on emails. Leave it out to use SMTP_USER.
  - name: SMTP_TLS
    group: Email (SMTP)
    default: ""
    description: >-
      How AppFlowy talks to your email server: wrapper (port 465), required
      (STARTTLS, port 587), opportunistic or none. Leave it out to use wrapper
      on port 465 and required on any other port.
  - name: APPFLOWY_NOTIFICATION_ENABLE_EMAIL
    group: Email (SMTP)
    default: 'false'
    description: >-
      Set to true to send people email notifications (mentions, invites).
      Needs SMTP_HOST.
  - name: GOTRUE_EXTERNAL_GOOGLE_ENABLED
    group: Sign in with Google, GitHub or Discord
    default: 'false'
    description: >-
      Set to true to turn on "Sign in with Google". In Google Cloud, set the
      redirect URL to your PUBLIC_URL followed by /gotrue/callback.
  - name: GOTRUE_EXTERNAL_GOOGLE_CLIENT_ID
    group: Sign in with Google, GitHub or Discord
    default: ""
    description: >-
      Client ID for Google sign-in.
  - name: GOTRUE_EXTERNAL_GOOGLE_SECRET
    group: Sign in with Google, GitHub or Discord
    default: ""
    description: >-
      Client secret for Google sign-in.
  - name: GOTRUE_EXTERNAL_GITHUB_ENABLED
    group: Sign in with Google, GitHub or Discord
    default: 'false'
    description: >-
      Set to true to turn on "Sign in with GitHub". In GitHub, set the
      callback URL to your PUBLIC_URL followed by /gotrue/callback.
  - name: GOTRUE_EXTERNAL_GITHUB_CLIENT_ID
    group: Sign in with Google, GitHub or Discord
    default: ""
    description: >-
      Client ID for GitHub sign-in.
  - name: GOTRUE_EXTERNAL_GITHUB_SECRET
    group: Sign in with Google, GitHub or Discord
    default: ""
    description: >-
      Client secret for GitHub sign-in.
  - name: GOTRUE_EXTERNAL_DISCORD_ENABLED
    group: Sign in with Google, GitHub or Discord
    default: 'false'
    description: >-
      Set to true to turn on "Sign in with Discord". In Discord, set the
      redirect URL to your PUBLIC_URL followed by /gotrue/callback.
  - name: GOTRUE_EXTERNAL_DISCORD_CLIENT_ID
    group: Sign in with Google, GitHub or Discord
    default: ""
    description: >-
      Client ID for Discord sign-in.
  - name: GOTRUE_EXTERNAL_DISCORD_SECRET
    group: Sign in with Google, GitHub or Discord
    default: ""
    description: >-
      Client secret for Discord sign-in.
  - name: RUST_LOG
    group: Logs
    default: info
    description: >-
      How much the app writes to its log: error, warn, info or debug.
---

# AppFlowy

AppFlowy is an open-source workspace for notes, docs, wikis and projects. This is the self-hosted AppFlowy Cloud in a single container, with one port and one data folder. Secret keys are made for you on first start.

## Features

- Docs, databases, boards, calendars and wikis in one workspace
- Real-time sync and teamwork across web, desktop and mobile apps
- Workspaces, members, guests and sharing with access control
- Publish pages to the web
- Built-in keyword search
- PostgreSQL with pgvector, Redis and Silo file storage inside
- Admin console to manage users and workspaces
- Bundled Mailpit catches all email, such as invites and password resets, or use your own email server
- Sign in with Google, GitHub or Discord
- Change sign-up rules, email and more by adding a setting in the app settings

## How to use

1. Open AppFlowy from your dashboard.
2. Sign up with your email and password.
3. Create your first workspace and page.
4. To use the AppFlowy desktop or mobile app, choose the self-hosted server option and enter your address with port `6101`.
5. Manage users at `/console`. Sign in with the admin email and password.
6. Read the email AppFlowy sends at `/mail`. Sign in with the username and password from `MP_UI_AUTH`.
