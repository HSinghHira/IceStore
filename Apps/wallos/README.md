---
site: https://wallosapp.com
source: https://github.com/ellite/Wallos
screenshots: [Dashboard, Calendar, Statistics]
variables:
  - name: OIDC_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to add a sign-in button for your OIDC provider (Authentik, Pocket ID, Authelia and others).
  - name: OIDC_PROVIDER_NAME
    group: Sign in with OIDC
    default: ""
    description: >-
      The name shown on the sign-in button, like Authentik.
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
  - name: OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's issuer address, like https://auth.example.com.
  - name: OIDC_AUTH_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's authorize address.
  - name: OIDC_TOKEN_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's token address.
  - name: OIDC_USERINFO_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's userinfo address.
  - name: OIDC_REDIRECT_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      Wallos's return address, like http://192.168.1.20:6735/index.php. Add the same in your provider.
  - name: OIDC_LOGOUT_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's logout address.
  - name: OIDC_USER_IDENTIFIER
    group: Sign in with OIDC
    default: "sub"
    description: >-
      Which claim identifies a user.
  - name: OIDC_SCOPES
    group: Sign in with OIDC
    default: "openid email profile"
    description: >-
      The scopes to ask for.
  - name: OIDC_AUTO_CREATE_USER
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false so only people who already have a Wallos account can sign in with OIDC.
  - name: OIDC_DISABLE_PASSWORD_LOGIN
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to hide the password login, so only OIDC works.
  - name: SSRF_ALLOWLIST
    group: Server
    default: ""
    description: >-
      Addresses on your network Wallos may call, like your OIDC provider or ntfy, comma separated, like 192.168.1.20:6730.
---

# Wallos

Wallos keeps all your subscriptions in one list: streaming, software, phone plans, memberships. It shows what you spend each month and year, reminds you before each payment, and turns prices into your own currency.

## Features

- Subscriptions with price, cycle, next payment, category and logo
- Monthly and yearly totals, a calendar and statistics
- Many currencies, with live exchange rates
- Reminders by email, Discord, Telegram, ntfy, Gotify and more
- Several household members and payment methods
- Optional sign-in with OIDC, and a mobile-friendly page

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6735` in your browser.
2. Make your account. The first account is the admin.
3. Add your subscriptions with the + button.

## Before you install

Nothing needs to be set first, and it starts in a few seconds. Make your account right after installing: the first account becomes the admin. If reminders go to an app on your own network (ntfy, Gotify), add its address to `SSRF_ALLOWLIST` or allow it in Wallos's admin settings. Sign-in with OIDC is in the Variables tab; add it in the app settings.
