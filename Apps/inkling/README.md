---
name: Inkling
source: https://github.com/PROVE1352/inkling
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Backlinks, Database board, Graph, Canvas]
variables:
  - name: SIGNUP_REQUIRE_KEY
    group: Sign-up and accounts
    default: ""
    description: >-
      Set to 0 to let anyone sign up without a signup key. Left out, a key is
      needed (make them on the Admin page).
  - name: REQUIRE_EMAIL_VERIFICATION
    group: Sign-up and accounts
    default: "0"
    description: >-
      Set to 1 so new accounts must verify their email before they can log
      in (needs email set up).
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Mail is on when this and
      MAIL_FROM are set.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port (465 with SMTP_SECURE=1).
  - name: SMTP_SECURE
    group: Email (SMTP)
    default: "0"
    description: >-
      Set to 1 for TLS from the start (port 465).
  - name: SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: SMTP_PASS
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: MAIL_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender, like Inkling <no-reply@example.com>.
  - name: OIDC_ISSUER
    group: Sign in with OpenID Connect
    default: ""
    description: >-
      Your provider, like https://accounts.google.com or your Authentik
      application's URL. Register the redirect URI PUBLIC_URL followed by
      /api/auth/oidc/callback.
  - name: OIDC_CLIENT_ID
    group: Sign in with OpenID Connect
    default: ""
    description: >-
      The client ID from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OpenID Connect
    default: ""
    description: >-
      The client secret from your provider.
  - name: OIDC_NAME
    group: Sign in with OpenID Connect
    default: SSO
    description: >-
      The button label: "Sign in with <name>".
  - name: OIDC_ALLOWED_DOMAINS
    group: Sign in with OpenID Connect
    default: ""
    description: >-
      Only these email domains may sign in, like example.com.
  - name: OIDC_AUTO_CREATE
    group: Sign in with OpenID Connect
    default: "0"
    description: >-
      Set to 1 to create an account on someone's first sign-in.
  - name: DELEGATED_AUTH_URL
    group: Sign in with OpenID Connect
    default: ""
    description: >-
      An external auth server that checks logins Inkling doesn't know (see
      upstream's DEPLOY.md for the contract).
  - name: TRUST_PROXY
    group: Security
    default: loopback,uniquelocal
    description: >-
      Proxies whose X-Forwarded-For is trusted. Add your reverse proxy's
      address if it is not on a private network.
  - name: AUTH_GUARD_MAX_FAILURES
    group: Security
    default: "10"
    description: >-
      Failed logins from one address before it is banned for a while.
  - name: ALLOWLIST_IPS
    group: Security
    default: ""
    description: >-
      Addresses that are never banned, like 192.168.1.0/24.
  - name: IMPORT_MAX_UPLOAD_MB
    group: Imports
    default: "25"
    description: >-
      The largest Notion, Markdown or zip import, in MB.
  - name: DEFAULT_LOCALE
    group: Features
    default: en
    description: >-
      Language for emails and new users: en or ko.
  - name: NOTION_TOKEN
    group: Features
    default: ""
    description: >-
      A Notion integration token, for uploading pages to Notion.
  - name: EXPERIMENTAL_FEATURES
    group: Features
    default: ""
    description: >-
      Turn on experimental features, comma-separated: plugins, vault-sync,
      sheets-sync.
  - name: UPDATE_CHECK
    group: Features
    default: ""
    description: >-
      Set to github to tell admins when a newer Inkling is out.
---

# Inkling

Inkling puts Notion-style databases and Obsidian-style links, graph and JSON Canvas in one self-hosted notes app, with real-time collaboration and a built-in MCP server for AI agents. PostgreSQL is inside this one container.

## Features

- Block editor with tables, code, checklists, math, wikilinks, tags and daily notes
- Databases with table, board, calendar, gallery and timeline views
- Backlinks, a link graph and an infinite canvas (JSON Canvas)
- Live co-editing, workspaces, roles, comments and share links
- MCP server for Claude and other agents; Markdown, Notion and Obsidian import

## How to use

1. Copy the sign-up link from the app's logs (CREDENTIALS box).
2. Open it and create your account. You become the admin.
3. Make a workspace and start writing.
4. Invite others with signup keys from the Admin page.

## Before you install

Set `PUBLIC_URL` to the address you open Inkling at, like `http://192.168.1.20:6703`; email links, share previews and AI agent (MCP) sign-in use it, and Inkling opens from any address either way.

Accounts need a signup key. On the first start a key is made for you and shown in the app's logs, in the box marked CREDENTIALS, as a ready sign-up link. The first person to use it becomes the admin, who makes keys for everyone else on the Admin page. The first start takes about a minute. More settings (email, single sign-on, security) are in the Variables tab; add them in the app settings. Upstream's backup sidecar is not included: back up `/DATA/AppData/inkling`.
