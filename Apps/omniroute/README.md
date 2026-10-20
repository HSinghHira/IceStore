---
site: https://github.com/diegosouzapw/OmniRoute
services:
  - { name: Dashboard, path: /, icon: globe }
variables:
  - name: REQUIRE_API_KEY
    group: Security
    default: "false"
    description: >-
      Set to true so every call to the /v1 API needs an OmniRoute API key.
      Do this if anyone else can reach the server.
  - name: AUTH_COOKIE_SECURE
    group: Security
    default: "false"
    description: >-
      Set to true when OmniRoute is behind HTTPS.
  - name: STORAGE_ENCRYPTION_KEY
    group: Security
    default: ""
    description: >-
      Encrypts the whole database with this key. Keep a copy; without it the
      data can't be read.
  - name: JWT_SECRET
    group: Security
    default: ""
    description: >-
      Signs dashboard logins. Set a long random value to keep logins the same
      across reinstalls.
  - name: API_KEY_SECRET
    group: Security
    default: ""
    description: >-
      Encrypts the provider API keys you save. Set a long random value and
      keep a copy.
  - name: NEXT_PUBLIC_BASE_URL
    group: Server
    default: http://localhost:20128
    description: >-
      The address people use to reach OmniRoute, like
      http://192.168.1.10:6114. Used for OAuth sign-in links.
  - name: CORS_ALLOWED_ORIGINS
    group: Server
    default: ""
    description: >-
      Web pages allowed to call the API from a browser, separated by commas.
  - name: REDIS_URL
    group: Server
    default: ""
    description: >-
      An optional Redis server for rate limits, like redis://192.168.1.10:6379.
  - name: DISABLE_SQLITE_AUTO_BACKUP
    group: Storage
    default: "false"
    description: >-
      Set to true to stop the automatic database backups.
  - name: PII_REDACTION_ENABLED
    group: Privacy
    default: "false"
    description: >-
      Set to true to hide personal details in requests before they reach a
      provider.
---

# OmniRoute

OmniRoute is a self-hosted AI gateway that puts one OpenAI-compatible endpoint in front of 290+ providers and 500+ models, including Claude, GPT, Gemini, DeepSeek and many free-tier options.

## Features

- One OpenAI-compatible endpoint for 290+ providers and 500+ models
- Smart routing, load balancing and automatic fallback, so tools like Claude Code, Cursor, Cline and Copilot keep working when a provider is down or out of quota
- Dashboard for provider keys and routing rules
- Settings, keys and routing data kept in the app data folder

## How to use

1. Open OmniRoute from your dashboard.
2. Sign in with the password you set in `INITIAL_PASSWORD`, then change it from the dashboard.
3. Add your provider API keys.
4. Point your tools at OmniRoute's OpenAI-compatible endpoint.
5. Set routing rules and fallback order from the dashboard.

## Before you install

Replace `CHANGEME` in `INITIAL_PASSWORD` with your own password. It is only used for the first sign-in, so change it again from the dashboard afterwards. If other people can reach the server, add `REQUIRE_API_KEY=true` from the Variables tab. Back up the app data folder to keep your keys and routing setup.
