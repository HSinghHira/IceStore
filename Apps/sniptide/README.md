---
name: Sniptide
site: https://sniptide.com
source: https://github.com/Dino-Kupinic/sniptide
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Compare revisions]
variables:
  - name: ALLOW_SIGN_UP
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false once your account exists, so nobody else can sign up.
  - name: ALLOWED_EMAILS
    group: Sign-up and accounts
    default: ""
    description: >-
      Only these email addresses may sign up, comma separated.
  - name: GITHUB_CLIENT_ID
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      A GitHub OAuth app's client ID, for "Sign in with GitHub".
  - name: GITHUB_CLIENT_SECRET
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The GitHub OAuth app's client secret.
  - name: GOOGLE_CLIENT_ID
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      A Google OAuth client ID, for "Sign in with Google".
  - name: GOOGLE_CLIENT_SECRET
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The Google OAuth client secret.
  - name: BETTER_AUTH_TRUSTED_ORIGINS
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      Extra addresses sign-in accepts, comma separated (for example a second
      domain).
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for account email.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server's port.
  - name: SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The address email comes from.
  - name: SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: SHARE_URL
    group: Pastes
    default: ""
    description: >-
      A separate address for share links. Left out, it is PUBLIC_URL.
  - name: MAX_PASTE_SIZE
    group: Pastes
    default: ""
    description: >-
      The largest paste, in bytes.
  - name: ACCOUNT_STORAGE_BYTES
    group: Pastes
    default: ""
    description: >-
      Storage per account, in bytes.
  - name: VIEW_HISTORY_RETENTION_DAYS
    group: Pastes
    default: "90"
    description: >-
      How many days view history is kept.
  - name: SLACK_WEBHOOK_URL
    group: Notifications
    default: ""
    description: >-
      A Slack webhook for notifications.
  - name: DISCORD_WEBHOOK_URL
    group: Notifications
    default: ""
    description: >-
      A Discord webhook for notifications.
---

# Sniptide

Sniptide is a self-hostable pastebin for code snippets, configs and secrets. Share multi-file pastes with passwords, expiry or burn-after-read links, keep reusable snippets in collections, sync `.env` files, and connect coding agents through the CLI or the MCP server. PostgreSQL is inside this one container.

## Features

- Multi-file pastes with syntax highlighting and revisions you can compare
- Passwords, expiry and burn-after-read links
- Collections of reusable snippets and `.env` file sync
- A CLI and an MCP server for coding agents
- GitHub and Google sign-in, email, Slack and Discord webhooks

## How to use

1. Set `PUBLIC_URL` to your ZimaOS IP before you install.
2. Open Sniptide and sign up to make your account.
3. Close sign-up with `ALLOW_SIGN_UP=false` in the app settings.
4. Create a paste, or connect your coding agent to the MCP server.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6716`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6716`. Sign-in only works on this address; until it is set, the app shows a "set PUBLIC_URL" page.

Sign-up is open at first so you can make your account; then add `ALLOW_SIGN_UP=false` in the app settings. Every secret is made on first start and kept in the data folder. More settings (OAuth sign-in, email, limits) are in the Variables tab.
