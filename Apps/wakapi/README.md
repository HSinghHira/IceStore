---
site: https://wakapi.dev
source: https://github.com/muety/wakapi
screenshots: [Dashboard]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: WAKAPI_PASSWORD_SALT
    group: Security
    default: ""
    description: >-
      Salt for stored passwords. Made on first start and kept in the
      data folder when left out; never change it afterwards.
  - name: WAKAPI_ALLOW_SIGNUP
    group: Sign-in
    default: "true"
    description: >-
      Set to false to stop new sign-ups.
  - name: WAKAPI_PUBLIC_URL
    group: Server
    default: ""
    description: >-
      The address people open Wakapi at, for emails and badges.
  - name: WAKAPI_LEADERBOARD_ENABLED
    group: Features
    default: "true"
    description: >-
      Set to false to turn off the leaderboard.
  - name: WAKAPI_MAIL_ENABLED
    group: Email
    default: "false"
    description: >-
      Set to true for password resets and reports (with
      WAKAPI_MAIL_SMTP_HOST, _PORT, _USER, _PASS and
      WAKAPI_MAIL_SENDER).
  - name: WAKAPI_DATA_RETENTION_MONTHS
    group: Data
    default: "-1"
    description: >-
      Delete heartbeats older than this many months (-1 keeps them).
---

# Wakapi

Wakapi counts the time you spend coding, per project, language, editor and machine, using the WakaTime plugins for VS Code, JetBrains, Vim and many more editors. Your data stays on your ZimaOS.

## Features

- Works with every WakaTime editor plugin
- Stats by project, language, editor, OS, machine and branch
- Leaderboards, badges and weekly email reports
- Import from WakaTime and relay to it
- Prometheus metrics and a WakaTime-compatible API

## How to use

1. Open Wakapi and sign up; the first account is yours.
2. Copy your API key from Settings.
3. In your editor's WakaTime plugin, set api_url to http://[ZIMAOS-IP-ADDRESS]:6865/api and your API key.

## Before you install

Open http://[ZIMAOS-IP-ADDRESS]:6865 and sign up; then set WAKAPI_ALLOW_SIGNUP=false if nobody else should. In your computer's ~/.wakatime.cfg, set api_url to http://[ZIMAOS-IP-ADDRESS]:6865/api and api_key to the key from Wakapi's Settings. WAKAPI_INSECURE_COOKIES=true is needed to sign in over plain http.
