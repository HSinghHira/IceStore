---
site: https://github.com/iamspido/github-release-monitor
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Test Page, path: /en/test, icon: check }
screenshots: [Home, Repository settings, Settings, Test page]
variables:
  - name: HTTPS
    group: Server
    default: "false"
    description: >-
      Set to true when you open the app through https (a reverse proxy).
      IceStore keeps it false so sign-in works over plain http.
  - name: GRM_TRUST_LAN
    group: Server
    default: "true"
    description: >-
      IceStore setting. Set to false to only allow sign-in from
      BETTER_AUTH_URL, not from every home-network address on port 6182.
  - name: BETTER_AUTH_TRUSTED_ORIGINS
    group: Server
    default: ""
    description: >-
      More addresses people may sign in from, comma-separated, like
      https://releases.example.com.
  - name: AUTHENTICATION_METHOD
    group: Sign-in
    default: Basic
    description: >-
      Basic (sign-in needed), AllowUnauthenticated (anyone can look, sign-in
      to change things) or External (no sign-in, only behind another login
      like Authelia or Authentik).
  - name: AUTH_ENABLE_SIGNUP
    group: Sign-in
    default: "false"
    description: >-
      Set to true to let other people make their own accounts.
  - name: AUTH_ENABLE_PASSKEY
    group: Sign-in
    default: "true"
    description: >-
      Set to false to turn off passkey sign-in.
  - name: AUTH_MAX_LOGIN_ATTEMPTS
    group: Sign-in
    default: "5"
    description: >-
      Wrong passwords allowed before a short lockout.
  - name: AUTH_LOGIN_LOCKOUT_SECONDS
    group: Sign-in
    default: "900"
    description: >-
      How long the lockout lasts, in seconds.
  - name: AUTH_LOGIN_WINDOW_SECONDS
    group: Sign-in
    default: "900"
    description: >-
      The time window wrong passwords are counted in, in seconds.
  - name: AUTH_TRUST_PROXY_HEADERS
    group: Sign-in
    default: "true"
    description: >-
      Set to false when the app is not behind a reverse proxy, so visitors
      can't fake their address.
  - name: AUTH_TRUSTED_PROXY_HOPS
    group: Sign-in
    default: "1"
    description: >-
      How many reverse proxies are in front of the app.
  - name: AUTH_PASSWORD_RESET_TOKEN_TTL_SECONDS
    group: Sign-in
    default: "900"
    description: >-
      How long a password reset link works, in seconds (60 to 86400).
  - name: BETTER_AUTH_SECRET
    group: Sign-in
    default: ""
    description: >-
      Your own sign-in key, 32 characters or more. Leave it out: each install
      makes its own on first start and keeps it in the data folder as
      .better_auth_secret. Changing it signs everyone out.
  - name: AUTH_SETUP_TOKEN
    group: Sign-in
    default: ""
    description: >-
      Your own one-time token for making the first account, 32 characters or
      more. Leave it out: one is made on first start and shown in the app log.
  - name: AUTH_GITHUB_CLIENT_ID
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The client ID of a GitHub OAuth app, to sign in with GitHub.
  - name: AUTH_GITHUB_CLIENT_SECRET
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The client secret of that GitHub OAuth app.
  - name: AUTH_GOOGLE_CLIENT_ID
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The client ID of a Google OAuth client, to sign in with Google.
  - name: AUTH_GOOGLE_CLIENT_SECRET
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The client secret of that Google OAuth client.
  - name: AUTH_TRUST_SOCIAL_LINKING
    group: Sign in with GitHub or Google
    default: "true"
    description: >-
      Set to false so GitHub or Google sign-ins are not linked to accounts by
      email by themselves.
  - name: GITLAB_ADDITIONAL_HOSTS
    group: Git hosts
    default: ""
    description: >-
      Other GitLab servers besides gitlab.com, comma-separated, like
      gitlab.example.com.
  - name: GITLAB_ACCESS_TOKENS
    group: Git hosts
    default: ""
    description: >-
      GitLab tokens for private repositories, as host=token pairs,
      comma-separated.
  - name: GITLAB_DEPLOY_TOKENS
    group: Git hosts
    default: ""
    description: >-
      GitLab deploy tokens, as host=username:token pairs, comma-separated.
  - name: CODEBERG_ACCESS_TOKEN
    group: Git hosts
    default: ""
    description: >-
      A Codeberg token, for private repositories.
  - name: FORGEJO_ADDITIONAL_BASE_URLS
    group: Git hosts
    default: ""
    description: >-
      Your Forgejo servers, comma-separated, like
      http://192.168.1.20:3000.
  - name: FORGEJO_ACCESS_TOKENS
    group: Git hosts
    default: ""
    description: >-
      Forgejo tokens for private repositories, as base-url=token pairs,
      comma-separated.
  - name: MAIL_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your SMTP server, for release emails and password resets.
  - name: MAIL_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      The SMTP port, like 587 or 465.
  - name: MAIL_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The SMTP user name.
  - name: MAIL_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The SMTP password or app password.
  - name: MAIL_FROM_ADDRESS
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: MAIL_FROM_NAME
    group: Email (SMTP)
    default: GitHub Release Monitor
    description: >-
      The name emails are sent from.
  - name: MAIL_TO_ADDRESS
    group: Email (SMTP)
    default: ""
    description: >-
      The address that gets the release emails.
  - name: MAIL_TLS_REJECT_UNAUTHORIZED
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false to accept a mail server with a self-signed certificate.
  - name: APPRISE_URL
    group: Notifications
    default: ""
    description: >-
      Your Apprise server's notify address, like
      http://192.168.1.20:8000/notify/your_key.
  - name: LOG_LEVEL
    group: Logs
    default: warn
    description: >-
      error, warn, info, debug or silent.
---

# GitHub Release Monitor

GitHub Release Monitor watches the repositories you pick and tells you by email or Apprise (Discord, Telegram, Slack and 70 more) as soon as a new release comes out. No more checking by hand. Every install makes its own secret keys on first start.

## Features

- Watches GitHub, GitLab, Codeberg and self-hosted Forgejo repositories
- Email and Apprise notifications, one per release or grouped
- Pick stable, pre-release or draft releases, for all repositories or one at a time
- Include and exclude rules for tags, and alpha, beta or rc choices
- Import and export your list as JSON
- A test page to check the GitHub connection, email and Apprise
- Passkeys, two-factor sign-in, dark mode and 19 languages

## How to use

1. Open the app log and copy the setup token.
2. Open `http://[ZIMAOS-IP-ADDRESS]:6182` and make your account with the setup token.
3. Add the repositories you want to watch, like `https://github.com/owner/repo`.
4. Open Settings to pick which releases you want and how often to check.
5. Set up email or Apprise to get notifications, then try them on the Test page.

## Before you install

Set `GITHUB_ACCESS_TOKEN` to a GitHub token with no scopes; without it GitHub only allows 60 checks an hour. You can leave `BETTER_AUTH_URL` as it is: sign-in works from `http://[ZIMAOS-IP-ADDRESS]:6182` on your home network. Change `localhost` to your ZimaOS IP for working links in emails. The app is ready in about half a minute. Then open the app log, copy the code after "Setup token:" and use it to make your account. Email, Apprise and the other settings are in the Variables tab; add them in the app settings.
