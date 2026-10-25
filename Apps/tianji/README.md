---
site: https://tianji.dev
services:
  - { name: Dashboard, path: /, icon: monitor }
screenshots: [Website analytics, Monitors, Server status, Status page, Surveys]
variables:
  - name: ALLOW_REGISTER
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let people make their own accounts on the sign-in page.
  - name: REGISTER_AUTO_JOIN_WORKSPACE_ID
    group: Sign-up and accounts
    default: ""
    description: >-
      A workspace ID that new accounts join by themselves.
  - name: DISABLE_ACCOUNT
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to turn off user name and password sign-in, when you use
      only GitHub, Google or OIDC.
  - name: AUTH_RESTRICT_EMAIL
    group: Sign-up and accounts
    default: ""
    description: >-
      Only allow sign-up with emails ending in this, like @example.com.
  - name: AUTH_USE_SECURE_COOKIES
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true when you open Tianji over HTTPS.
  - name: EMAIL_SERVER
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server as one address, like
      smtp://user:password@smtp.example.com:587. Turns on email sign-in and
      email invites.
  - name: EMAIL_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address on emails, like tianji@example.com.
  - name: AUTH_GITHUB_ID
    group: Sign in with GitHub
    default: ""
    description: >-
      Your GitHub OAuth app's client ID. The callback is your PUBLIC_URL plus
      /api/auth/callback/github.
  - name: AUTH_GITHUB_SECRET
    group: Sign in with GitHub
    default: ""
    description: >-
      Your GitHub OAuth app's client secret.
  - name: AUTH_GOOGLE_ID
    group: Sign in with Google
    default: ""
    description: >-
      Your Google OAuth client ID. The callback is your PUBLIC_URL plus
      /api/auth/callback/google.
  - name: AUTH_GOOGLE_SECRET
    group: Sign in with Google
    default: ""
    description: >-
      Your Google OAuth client secret.
  - name: AUTH_CUSTOM_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your OIDC provider (Pocket ID, Authentik...). The
      callback is your PUBLIC_URL plus /api/auth/callback/custom.
  - name: AUTH_CUSTOM_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your OIDC provider.
  - name: AUTH_CUSTOM_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      Your OIDC provider's issuer address, like https://auth.example.com.
  - name: AUTH_CUSTOM_NAME
    group: Sign in with OIDC
    default: Custom
    description: >-
      The name on the sign-in button.
  - name: AUTH_CUSTOM_TYPE
    group: Sign in with OIDC
    default: oidc
    description: >-
      oidc or oauth.
  - name: ALLOW_OPENAPI
    group: Features
    default: "true"
    description: >-
      Set to false to turn off the OpenAPI for scripts and tools.
  - name: ENABLE_FUNCTION_WORKER
    group: Features
    default: "false"
    description: >-
      Set to true to turn on function workers (your own code that runs in
      Tianji).
  - name: ALPHA_MODE
    group: Features
    default: "false"
    description: >-
      Set to true to try features that are not finished yet.
  - name: MAPBOX_TOKEN
    group: Features
    default: ""
    description: >-
      A Mapbox token, for the visitor map.
  - name: AMAP_TOKEN
    group: Features
    default: ""
    description: >-
      An AMap (Gaode) token, for the visitor map in China.
  - name: CUSTOM_TRACKER_SCRIPT_NAME
    group: Features
    default: ""
    description: >-
      Another name for the tracker script, like stats.js, so ad blockers
      don't catch it.
  - name: SHARED_OPENAI_API_KEY
    group: AI
    default: ""
    description: >-
      An OpenAI API key for Tianji's own AI features.
  - name: SHARED_OPENAI_BASE_URL
    group: AI
    default: ""
    description: >-
      Another OpenAI-compatible API address, like a local Ollama.
  - name: SHARED_OPENAI_MODEL_NAME
    group: AI
    default: gpt-4o
    description: >-
      The model to use.
  - name: DISABLE_AUTO_CLEAR
    group: Data
    default: "false"
    description: >-
      Set to true to keep old analytics and monitor data forever.
  - name: AUDIT_LOG_RETENTION_DAYS
    group: Data
    default: "30"
    description: >-
      How many days to keep the audit log.
  - name: REDIS_URL
    group: Data
    default: ""
    description: >-
      A Redis server for the cache, like redis://192.168.1.20:6379. Leave it
      out to cache in memory and the database.
  - name: CLICKHOUSE_URL
    group: Data
    default: ""
    description: >-
      A ClickHouse server for large analytics data, like
      http://192.168.1.20:8123.
  - name: CLICKHOUSE_USER
    group: Data
    default: ""
    description: >-
      The ClickHouse user name.
  - name: CLICKHOUSE_PASSWORD
    group: Data
    default: ""
    description: >-
      The ClickHouse password.
  - name: CLICKHOUSE_DATABASE
    group: Data
    default: ""
    description: >-
      The ClickHouse database name.
  - name: DISABLE_ANONYMOUS_TELEMETRY
    group: Privacy
    default: "false"
    description: >-
      Set to true to stop sending Tianji anonymous usage data.
  - name: DISABLE_ACCESS_LOGS
    group: Logs
    default: "false"
    description: >-
      Set to true to stop logging every request.
  - name: DB_DEBUG
    group: Logs
    default: "false"
    description: >-
      Set to true to log every database query.
---

# Tianji

Tianji is an all-in-one insight hub: website analytics like Umami or Google Analytics, uptime checks like Uptime Kuma and a server status page, in one light self-hosted app. This is Tianji in a single container, with PostgreSQL inside, one port and one data folder. The secret key, the database passwords and the admin password are made for you on first start.

## Features

- Cookie-free, privacy-friendly website analytics with one small tracking script
- Uptime monitors for websites and services, with notifications
- Server and Docker status from a small reporter you run on each server
- Public status pages to share with your users
- Surveys, event feeds, short links and an AI gateway with cost tracking

## How to use

1. Find the admin password in the app log, on the line that says "Tianji login is".
2. Open Tianji from your dashboard and sign in as `admin`.
3. Change the password in Settings.
4. Add a website, a monitor or a server.
5. For website analytics, copy the tracking script from the website's page and add it to your site.
6. For server status, run the `tianji-reporter` on that server and point it at `http://your-zimaos-ip:6163`.

## Before you install

`PUBLIC_URL` starts as `http://localhost:6163`. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6163`, so tracking scripts and status pages work from other devices. Leave `ADMIN_PASSWORD` blank to get a random one: it is in the app log on the line that says "Tianji login is", and in `admin-password.txt` in the app folder. It replaces upstream's default admin / admin login, and is only used until you change the password in Tianji. The first start takes about two minutes. Sign-up, email, sign in with GitHub, Google or OIDC and the other settings are in the Variables tab; add them in the app settings.
