---
name: n8n (OIDC)
site: https://n8n.io/
source: https://github.com/cweagans/n8n-oidc
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: N8N_PROTOCOL
    group: Server
    default: http
    description: >-
      Set to https when you open n8n through an HTTPS address. Also set
      N8N_SECURE_COOKIE to true.
  - name: N8N_HOST
    group: Server
    default: localhost
    description: >-
      The host name people use to reach n8n, like n8n.example.com.
  - name: WEBHOOK_URL
    group: Server
    default: ""
    description: >-
      The public address for webhooks, like https://n8n.example.com/. Set it
      when n8n is behind a reverse proxy so webhook links are right.
  - name: OIDC_SCOPES
    group: Sign in with OIDC
    default: openid email profile
    description: >-
      The scopes n8n asks your login provider for, separated by spaces.
  - name: N8N_LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much detail goes in the log. One of error, warn, info or debug.
  - name: N8N_DIAGNOSTICS_ENABLED
    group: Privacy
    default: "true"
    description: >-
      Set to false to stop n8n sending anonymous usage data.
---

# n8n (OIDC)

n8n with a bolt-on OIDC login, so you can sign in through Pocket ID, Authentik, Keycloak or any other OIDC provider. It uses the community [n8n-oidc](https://github.com/cweagans/n8n-oidc) hook. It is not an official n8n feature.

## Features

- "Sign in with SSO" button on the n8n sign-in page
- Accounts are created on first login
- The first person to sign in becomes the owner
- SQLite database and settings kept in the app data folder
- The hook file is downloaded and checked against a fixed SHA-256 hash on every start

## How to use

1. Open n8n from your dashboard.
2. Click **Sign in with SSO** and log in with your provider.
3. Build your first workflow.

## Before you install

In your login provider, make a new OIDC client for n8n with the redirect URI `http://your-server-ip:6111/auth/oidc/callback`. Then fill in `OIDC_ISSUER_URL`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET` and `OIDC_REDIRECT_URI` in place of the `CHANGEME` values. Everyone who can sign in through that client gets an n8n account, and the first one becomes the owner, so only let people you trust use it. If you use an HTTPS address, set `N8N_SECURE_COOKIE` to `true` and add `N8N_PROTOCOL=https` from the Variables tab.
