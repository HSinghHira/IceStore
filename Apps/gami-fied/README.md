---
name: Gami.Fied
source: https://github.com/gami-fied/gami.fied
services:
  - { name: Dashboard, path: /, icon: globe }
  - { name: Platform admin, path: /admin, icon: server }
  - { name: API, path: /v1/, icon: code }
variables:
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for email notifications and account email.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port.
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
  - name: SMTP_FROM_EMAIL
    group: Email (SMTP)
    default: ""
    description: >-
      The address email comes from.
  - name: SMTP_FROM_NAME
    group: Email (SMTP)
    default: ""
    description: >-
      The sender name on email.
  - name: SMTP_SECURE
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for TLS from the start (port 465).
  - name: SMTP_ALLOW_SELF_SIGNED
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for a mail server with a self-signed certificate.
  - name: TRUSTED_ORIGINS
    group: API
    default: ""
    description: >-
      Extra websites allowed to call the API from a browser, comma
      separated, like https://www.example.com.
  - name: RATE_LIMIT_IP_MAX
    group: API
    default: "600"
    description: >-
      Requests per minute allowed from one IP address.
  - name: METRICS_BEARER_TOKEN
    group: API
    default: ""
    description: >-
      A token for Prometheus to read /metrics. Without it only platform
      admins can.
  - name: WORKER_CONCURRENCY
    group: Performance
    default: "4"
    description: >-
      How many jobs the worker runs at once.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      debug, info, warn or error.
---

# Gami.Fied

Gami.Fied is a self-hosted gamification engine. Your app sends it events, and rules you set up turn them into XP, levels, achievements, challenges and leaderboards, with notifications and webhooks included. Your users' data stays on your server. PostgreSQL and Redis are inside this one container.

## Features

- Rules engine with conditions, a simulator and a trace of why a rule fired
- XP, levels, achievements, challenges and daily, weekly, monthly and all-time leaderboards
- In-app notifications, email, signed webhooks and Discord
- Dashboard with analytics, audit logs and roles; scoped API keys
- A stable `/v1` API and a TypeScript SDK

## How to use

1. Set `PUBLIC_URL` to your ZimaOS IP before you install.
2. Open Gami.Fied and sign up.
3. Open `/admin` and enter the bootstrap secret from the app's logs to become the platform admin.
4. Make a project, create an API key and send events from your app to the `/v1` API.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6709`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6709`. Sign-in only works on this address; until it is set, the app shows a "set PUBLIC_URL" page.

Every secret is made on first start. The platform bootstrap secret is in the app's logs, in the box marked CREDENTIALS: sign up, open `/admin` and enter it. The first start takes about two minutes. More settings (email, API limits) are in the Variables tab; add them in the app settings.
