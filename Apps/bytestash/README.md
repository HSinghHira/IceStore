---
site: https://github.com/jordan-dalby/ByteStash
source: https://github.com/jordan-dalby/ByteStash
screenshots: [Snippet grid]
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API, path: /api, icon: code }
variables:
  - name: DISABLE_ACCOUNTS
    group: Accounts
    default: "false"
    description: >-
      true turns sign-in off: everyone shares one set of snippets, no login needed.
  - name: DISABLE_INTERNAL_ACCOUNTS
    group: Accounts
    default: "false"
    description: >-
      true allows only single sign-on (OIDC), no passwords.
  - name: ALLOW_PASSWORD_CHANGES
    group: Accounts
    default: "false"
    description: >-
      true lets users change their own password.
  - name: OIDC_ENABLED
    group: Single sign-on
    default: "false"
    description: >-
      true shows a single sign-on button (Authentik, Pocket ID and so on).
  - name: OIDC_DISPLAY_NAME
    group: Single sign-on
    default: "Single Sign-on"
    description: >-
      The text on the single sign-on button.
  - name: OIDC_ISSUER_URL
    group: Single sign-on
    default: ""
    description: >-
      Your provider's issuer URL, like https://auth.example.com/application/o/bytestash/.
  - name: OIDC_CLIENT_ID
    group: Single sign-on
    default: ""
    description: >-
      Client id from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Single sign-on
    default: ""
    description: >-
      Client secret from your provider.
  - name: OIDC_SCOPES
    group: Single sign-on
    default: "openid profile email"
    description: >-
      Scopes to ask for.
  - name: PUBLIC_URL
    group: Web
    default: ""
    description: >-
      The address you open ByteStash at, like http://192.168.1.20:7004. Needed for single sign-on redirects.
  - name: BASE_PATH
    group: Web
    default: ""
    description: >-
      Serve ByteStash under a sub path, like /bytestash, behind a reverse proxy.
  - name: DATABASE_URL
    group: Database
    default: ""
    description: >-
      postgres://user:pass@host:5432/bytestash to use your own PostgreSQL instead of the built-in SQLite.
  - name: MIGRATE_SQLITE_TO_POSTGRES
    group: Database
    default: "false"
    description: >-
      true copies the SQLite data into an empty PostgreSQL on start.
  - name: DEBUG
    group: Advanced
    default: "false"
    description: >-
      true writes more detail to the log.
---

# ByteStash

ByteStash is a home for your code snippets. Save them with syntax highlighting, sort them with categories, find them with search and share them with a link.

## Features

- Snippets with one or more files and syntax highlighting
- Categories, search and favorites
- Public or private share links, with an expiry
- Several users, with sign-in by password or your own SSO (OIDC)
- REST API and an MCP endpoint for AI assistants

## How to use

1. Open ByteStash and register your account.
2. Click New snippet, paste your code and pick the language.
3. Set ALLOW_NEW_ACCOUNTS to false so nobody else can sign up.

## Before you install

ByteStash has no default login: open http://[ZIMAOS-IP-ADDRESS]:7004 and register, then set ALLOW_NEW_ACCOUNTS to false. New accounts are never admins; to get the admin page, open the app's terminal in ZimaOS and run `node src/scripts/admin.js grant <your user name>`. ByteStash makes its own sign-in secret on first start and keeps it in the data folder.
