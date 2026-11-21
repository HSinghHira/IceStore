---
site: https://ghostfol.io/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API, path: /api/v1/health, icon: code }
screenshots: [Portfolio]
variables:
  - name: ROOT_URL
    group: Server
    default: "http://localhost:6772"
    description: >-
      The address you open Ghostfolio at, like http://192.168.1.20:6772.
      Used for links and the sign-in callback.
  - name: TRUST_PROXY
    group: Server
    default: ""
    description: >-
      Set to 1 when one reverse proxy is in front of Ghostfolio.
  - name: REQUEST_TIMEOUT
    group: Server
    default: "3000"
    description: >-
      How long to wait for a price provider, in milliseconds.
  - name: LOG_LEVELS
    group: Server
    default: ""
    description: >-
      What goes in the log, like ["error","log","warn"].
  - name: JWT_SECRET_KEY
    group: Server
    default: ""
    description: >-
      The key sign-ins are signed with. It is made on first start and kept in
      /data/secrets.env. Only set it to use your own.
  - name: ACCESS_TOKEN_SALT
    group: Server
    default: ""
    description: >-
      The salt for security tokens. It is made on first start; changing it
      makes every saved token stop working.
  - name: ENABLE_FEATURE_SECURITY_HEADERS
    group: Features
    default: "false"
    description: >-
      Set to true to send security headers (experimental).
  - name: ENABLE_FEATURE_MCP
    group: Features
    default: "false"
    description: >-
      Set to true to serve an MCP server for AI tools at /mcp
      (experimental).
  - name: API_KEY_COINGECKO_DEMO
    group: Price data
    default: ""
    description: >-
      Your CoinGecko Demo API key, for crypto prices.
  - name: API_KEY_COINGECKO_PRO
    group: Price data
    default: ""
    description: >-
      Your CoinGecko Pro API key.
  - name: ENABLE_FEATURE_AUTH_TOKEN
    group: Sign-in
    default: "true"
    description: >-
      Sign in with a security token. Set to false when you only use OIDC.
  - name: ENABLE_FEATURE_AUTH_OIDC
    group: Sign-in
    default: "false"
    description: >-
      Set to true to sign in with your own provider (OpenID Connect,
      experimental).
  - name: OIDC_ISSUER
    group: Sign-in
    default: ""
    description: >-
      Your provider's issuer address, like https://auth.example.com.
  - name: OIDC_CLIENT_ID
    group: Sign-in
    default: ""
    description: >-
      The client ID from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign-in
    default: ""
    description: >-
      The client secret from your provider.
  - name: OIDC_SCOPE
    group: Sign-in
    default: "[\"openid\"]"
    description: >-
      The scopes to ask for, like ["email","openid","profile"].
  - name: OIDC_CALLBACK_URL
    group: Sign-in
    default: ""
    description: >-
      The callback address. Leave it out to use ROOT_URL/api/auth/oidc/callback.
---

# Ghostfolio

Ghostfolio shows all your investments in one place: stocks, ETFs, crypto, cash and more, across every broker and account. See how your portfolio does over time, what you hold and where the risk is. PostgreSQL and Redis are built in, so it is one container with nothing else to set up.

## Features

- Buys, sells, dividends and fees across many accounts
- Performance today, this year and since the start
- Holdings by asset class, region, sector and currency
- Checks of your portfolio against simple rules (X-ray)
- Many currencies, with exchange rates
- Import and export of your activities as CSV or JSON
- Works on your phone, and in dark mode

## How to use

1. Open Ghostfolio from your dashboard.
2. Click Get Started. Ghostfolio makes your account and shows a security token. Save it: it is how you sign in.
3. Open Admin Control and pick how prices are fetched (data providers).
4. Add your accounts, then your activities (buys, sells, dividends), or import them.
5. Look at your portfolio, its performance and the X-ray.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6772`. There is no account yet: click Get Started, and the first account is the admin. Ghostfolio signs you in with a security token it shows once, so save it somewhere safe. The secrets and the database and Redis passwords are made for you on first start and kept in `/DATA/AppData/ghostfolio/data`. Single sign-on, price API keys and the other settings are in the Variables tab and are added in the app settings. The first start takes a few minutes while it sets up the database.
