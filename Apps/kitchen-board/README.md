---
site: https://gitlab.com/g33kphr33k/kitchen-board
source: https://gitlab.com/g33kphr33k/kitchen-board
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Board, Calendar, Stock, Meals, Chores, Themes]
variables:
  - name: SECRET_KEY
    group: Server
    default: ""
    description: >-
      Your own sign-in key, at least 32 characters (openssl rand -hex 32).
      Leave it out: each install makes its own on first start and keeps it in
      the data folder as .secret_key. Changing it signs everyone out.
  - name: KB_LANGUAGE
    group: Server
    default: en-GB
    description: >-
      The starting language: en-GB, en-001, de, fr, it or es. The language
      picked in Admin wins once it is saved.
  - name: ALLOWED_HOSTS
    group: Server
    default: ""
    description: >-
      Comma-separated host names Kitchen Board answers to, like
      192.168.1.20,kitchen.local. Leave it out to answer on any address. If
      you set it, add every address you open it by.
  - name: APP_BASE_URL
    group: Server
    default: ""
    description: >-
      The address used in password reset and magic sign-in emails, like
      http://192.168.1.20:6179. Leave it out to use the address in the
      browser.
  - name: SECURE_COOKIES
    group: Server
    default: "false"
    description: >-
      Set to true when you open Kitchen Board through https.
  - name: TRUSTED_PROXY_IPS
    group: Server
    default: 127.0.0.1,::1
    description: >-
      Reverse proxy IPs whose forwarded visitor address is trusted for the
      sign-in rate limit.
  - name: FORWARDED_ALLOW_IPS
    group: Server
    default: 127.0.0.1
    description: >-
      Reverse proxy IPs whose proxy headers are trusted.
  - name: NIGHTLY_BACKUP_KEEP
    group: Server
    default: "7"
    description: >-
      Nightly database copies kept in data/backups. 0 turns them off.
  - name: DB_WATCHDOG_EXIT_MINUTES
    group: Server
    default: "10"
    description: >-
      Minutes the database may stop answering before the app restarts itself.
      0 only logs it.
  - name: ACCESS_TOKEN_EXPIRE_MINUTES
    group: Sign-in
    default: "525600"
    description: >-
      How long a sign-in lasts, in minutes. The default is one year.
  - name: PASSWORD_RESET_EXPIRE_MINUTES
    group: Sign-in
    default: "60"
    description: >-
      How long a password reset link works, in minutes.
  - name: MAGIC_LOGIN_EXPIRE_MINUTES
    group: Sign-in
    default: "15"
    description: >-
      How long a magic sign-in link works, in minutes.
  - name: OIDC_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to show a single sign-on button. The Admin page setting wins
      once saved.
  - name: OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's address, like https://id.example.com.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret. Leave it out for a public client.
  - name: OIDC_DISPLAY_NAME
    group: Sign in with OIDC
    default: ""
    description: >-
      The name on the sign-in button, like Pocket ID.
  - name: OIDC_SCOPES
    group: Sign in with OIDC
    default: openid email profile
    description: >-
      The scopes asked for.
  - name: OIDC_REDIRECT_URI
    group: Sign in with OIDC
    default: ""
    description: >-
      Your own callback address. Leave it out to build it from APP_BASE_URL.
  - name: OIDC_AUTO_PROVISION
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to make an account the first time someone signs in.
  - name: OIDC_ENFORCE_LOCAL_MFA
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to also ask for the Kitchen Board authenticator code.
  - name: OIDC_ALLOW_PRIVATE_NETWORK
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true when your provider runs on your home network.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your SMTP server, for password resets and magic sign-in links.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      The SMTP port.
  - name: SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The SMTP user name, often the sending mailbox.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The SMTP password or app password.
  - name: SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The From address. Leave it out to use SMTP_USERNAME.
  - name: SMTP_ENCRYPTION
    group: Email (SMTP)
    default: starttls
    description: >-
      starttls (port 587), ssl (port 465) or none.
  - name: SMTP_AUTH_MODE
    group: Email (SMTP)
    default: password
    description: >-
      password, or oauth2 with the SMTP_OAUTH_* settings below.
  - name: SMTP_OAUTH_PROVIDER
    group: Email (SMTP)
    default: custom
    description: >-
      google, microsoft or custom, for oauth2 email.
  - name: SMTP_OAUTH_TOKEN_URL
    group: Email (SMTP)
    default: ""
    description: >-
      The token address, for a custom OAuth provider.
  - name: SMTP_OAUTH_CLIENT_ID
    group: Email (SMTP)
    default: ""
    description: >-
      The OAuth client ID for email.
  - name: SMTP_OAUTH_CLIENT_SECRET
    group: Email (SMTP)
    default: ""
    description: >-
      The OAuth client secret for email.
  - name: SMTP_OAUTH_REFRESH_TOKEN
    group: Email (SMTP)
    default: ""
    description: >-
      The refresh token used to get email access tokens.
  - name: SMTP_OAUTH_SCOPE
    group: Email (SMTP)
    default: ""
    description: >-
      An optional scope, like https://mail.google.com/.
  - name: SMTP_OAUTH_REDIRECT_URI
    group: Email (SMTP)
    default: ""
    description: >-
      The OAuth callback address. Leave it out to use
      /admin/email-oauth/callback.
  - name: VAPID_PUBLIC_KEY
    group: Notifications
    default: ""
    description: >-
      The public key for web push notifications. Push stays off without a key
      pair. Keys made in the Admin page win.
  - name: VAPID_PRIVATE_KEY
    group: Notifications
    default: ""
    description: >-
      The private key paired with VAPID_PUBLIC_KEY.
  - name: VAPID_EMAIL
    group: Notifications
    default: admin@example.com
    description: >-
      The contact email sent with push notifications.
  - name: APPRISE_URLS
    group: Notifications
    default: ""
    description: >-
      Apprise notification URLs, one per line.
---

# Kitchen Board

Kitchen Board is a household organiser made to live on a kitchen tablet and on everyone's phone. It looks like a paper wall calendar with a shopping list pinned to it, and keeps every screen in sync as people tick things off. Every install makes its own sign-in key on first start.

## Features

- Shared shopping lists with a focused Shopping Trip mode
- Stock, meal planning and Mealie recipe import
- A shared calendar with recurring events, `.ics` feeds and Google Calendar overlays
- Chores, rewards, routines, countdowns and kitchen timers
- Notes, weather and simple statistics
- A photo-frame screensaver, with an optional Immich album
- Push, email and Apprise notifications, OIDC single sign-on, and six languages
- Installs as an app on phones (PWA)

## How to use

1. Open Kitchen Board at `http://[ZIMAOS-IP-ADDRESS]:6179`.
2. Sign in with your `ADMIN_EMAIL` and password.
3. Open Admin to add the people in your household.
4. Add shopping items, events and chores. Every screen updates by itself.
5. On a phone, use "Add to Home Screen" to install it like an app.

## Before you install

Change `ADMIN_EMAIL` from `CHANGEME@example.com` to your email. Set `ADMIN_PASSWORD` (8 characters or more), or leave it empty and Kitchen Board prints one in the app log on the line with `Password:`. Both are only read on the very first start. It is ready in about half a minute. The sign-in key is made on first start and kept in the data folder as `.secret_key`. Email, push notifications, OIDC and more are in the Variables tab; add them in the app settings, or set most of them in the Admin page.
