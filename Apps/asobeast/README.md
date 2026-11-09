---
name: AsoBeast
site: https://asobeast.com
source: https://github.com/AsoBeast/asobeast
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Overview, Action Center]
variables:
  - name: AUTH_ALLOW_REGISTRATION
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to keep sign-up open after the owner account exists.
  - name: AUTH_REGISTRATION_WORKSPACE
    group: Sign-up and accounts
    default: own
    description: >-
      Where a new sign-up lands: own (their own workspace) or shared (your
      workspace, as members).
  - name: AUTH_SESSION_DAYS
    group: Sign-up and accounts
    default: "7"
    description: >-
      How many days a sign-in lasts.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com, for email alerts, password
      resets and invitations.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port (465 with SMTP_SECURE=true).
  - name: SMTP_SECURE
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for TLS from the start (port 465).
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
  - name: SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The address email comes from.
  - name: OPENAI_API_KEY
    group: AI
    default: ""
    description: >-
      An OpenAI (or compatible) API key for optional AI summaries and review
      replies. Leave it out and AsoBeast works without AI.
  - name: OPENAI_BASE_URL
    group: AI
    default: ""
    description: >-
      An OpenAI-compatible server, like your own Ollama at
      http://192.168.1.20:11434/v1.
  - name: AI_MODEL
    group: AI
    default: gpt-5.6-luna
    description: >-
      The model name as your provider spells it (needs vision and structured
      output).
  - name: AI_CALLS_PER_MONTH
    group: AI
    default: ""
    description: >-
      A monthly cap on AI calls. Left out, there is none.
  - name: SCRAPE_ITUNES_RPM
    group: Store collection
    default: "15"
    description: >-
      App Store requests per minute.
  - name: SCRAPE_GPLAY_RPM
    group: Store collection
    default: "10"
    description: >-
      Google Play jobs per minute. Halve it if you see BlockedError.
  - name: SCREENSHOT_OCR
    group: Store collection
    default: "true"
    description: >-
      Set to false to stop reading the text on store screenshots.
  - name: CRON_DAILY
    group: Schedules
    default: 0 3 * * *
    description: >-
      When the daily ranking run starts, as a cron pattern in UTC.
  - name: ALERT_DELIVERY
    group: Alerts
    default: batched
    description: >-
      batched sends up to two reports a day after the daily run; instant
      sends each event at once.
  - name: ALERT_RANK_DROP_THRESHOLD
    group: Alerts
    default: "5"
    description: >-
      How many places a keyword must move before it alerts.
  - name: WEBHOOK_ALLOW_PRIVATE_TARGETS
    group: Alerts
    default: "false"
    description: >-
      Set to true to send webhook alerts to addresses on your home network.
  - name: RETENTION_RANKINGS_DAYS
    group: Data retention
    default: "365"
    description: >-
      Delete keyword rankings older than this many days; 0 keeps them forever.
  - name: RETENTION_SERP_DAYS
    group: Data retention
    default: "90"
    description: >-
      Delete search result snapshots older than this many days; 0 keeps them
      forever.
  - name: GOOGLE_PLAY_OAUTH_CLIENT_ID
    group: Store consoles
    default: ""
    description: >-
      A Google OAuth web client ID, so owners connect Google Play by signing
      in with Google. Its redirect is your PUBLIC_URL followed by
      /integrations/google-play.
  - name: GOOGLE_PLAY_OAUTH_CLIENT_SECRET
    group: Store consoles
    default: ""
    description: >-
      The secret of that Google OAuth client.
  - name: ASOBEAST_TRUST_PROXY
    group: Reverse proxy
    default: "2"
    description: >-
      How many proxies sit in front of the API, counting the two inside this
      container. Set 3 behind your own reverse proxy, so rate limits see each
      visitor's address.
  - name: LOG_LEVEL
    group: Logs
    default: log
    description: >-
      How much the API logs: error, warn, log, debug or verbose.
---

# AsoBeast

AsoBeast is an open source App Store Optimization (ASO) tool and keyword rank tracker for the Apple App Store and Google Play. It tracks your keyword rankings daily, watches competitors, reviews and listing changes, and turns the history into a list of ASO work to do. Your keyword list never leaves your server. PostgreSQL and Redis are inside this one container.

## Features

- Import an App Store or Google Play listing and track keywords in any storefront, ranked to depth 200 every day
- Popularity and difficulty scores that show their evidence
- Competitor discovery, keyword gaps, top charts and review mining
- Action Center: a ranked queue of ASO work with the evidence for each
- Alerts by webhook or email, an API and an MCP server for AI agents

## How to use

1. Open AsoBeast from your dashboard.
2. Create the owner account. Sign-up closes after that.
3. Paste an App Store or Google Play link to import your app.
4. Add keywords and markets; rankings start right away.

## Before you install

Set `PUBLIC_URL` to the address you open AsoBeast at, like `http://192.168.1.20:6700`. It works from any address, but links in emails and alerts use this one. Open `http://[ZIMAOS-IP-ADDRESS]:6700` and create the owner account; sign-up then closes. Over plain http use Chrome or Firefox: Safari only keeps you signed in over https.

The first start takes about two minutes. Every secret is made for you and kept in the data folder. More settings (email, AI, schedules, retention) are in the Variables tab; add them in the app settings.
