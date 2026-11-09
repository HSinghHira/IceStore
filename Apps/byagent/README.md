---
name: byagent
site: https://byagent.dev
source: https://github.com/anup-a/byagent
services:
  - { name: Dashboard, path: /app/login, icon: globe }
  - { name: Health, path: /healthz, icon: info }
screenshots: [Dashboard, A page with comments]
variables:
  - name: EMAIL_PROVIDER
    group: Dashboard sign-in
    default: log
    description: >-
      How sign-in codes reach you. log prints them in the app's logs (only
      people who can read the logs can sign in); resend sends real email.
  - name: RESEND_API_KEY
    group: Dashboard sign-in
    default: ""
    description: >-
      Your Resend API key, with EMAIL_PROVIDER=resend.
  - name: EMAIL_FROM
    group: Dashboard sign-in
    default: ""
    description: >-
      The sender for sign-in email, like byagent <login@example.com>.
  - name: GITHUB_CLIENT_ID
    group: Dashboard sign-in
    default: ""
    description: >-
      A GitHub OAuth app's client ID, for "Sign in with GitHub". Its callback
      is your PUBLIC_URL followed by /app/login/github/callback.
  - name: GITHUB_CLIENT_SECRET
    group: Dashboard sign-in
    default: ""
    description: >-
      The GitHub OAuth app's client secret.
  - name: ADMIN_TOKEN
    group: Keys
    default: ""
    description: >-
      The API key of the admin workspace. Made on first start and kept in
      .admin-token in the data folder when left out.
  - name: KEY_SIGNING_SECRET
    group: Keys
    default: ""
    description: >-
      Signs sessions and portal links. Made on first start when left out;
      changing it ends every portal link.
  - name: PUBLIC_SHARE_ORIGIN
    group: Addresses
    default: ""
    description: >-
      A separate address for published pages, like https://pages.example.com.
      Left out, it is PUBLIC_URL. Upstream advises a separate one when the
      dashboard is used.
  - name: PUBLIC_API_ORIGIN
    group: Addresses
    default: ""
    description: >-
      The address of the API and dashboard. Left out, it is PUBLIC_URL.
  - name: CONTENT_DOMAIN
    group: Addresses
    default: ""
    description: >-
      Give every page its own origin, https://<slug>.<this domain>/ (needs
      wildcard DNS and HTTPS). Left out, pages live under /a/<id>/.
  - name: TRUST_PROXY_HEADERS
    group: Addresses
    default: "false"
    description: >-
      Set to true only when byagent is reachable only through your reverse
      proxy, so rate limits use the visitor's address.
  - name: VARIABLES_KEY
    group: Features
    default: ""
    description: >-
      Turns on account variables and proxy routes (pages that call an API
      without showing the key). Base64 of 32 random bytes (openssl rand
      -base64 32). Losing it loses every stored value.
  - name: LIMIT_VERSION_BYTES
    group: Limits
    default: "26214400"
    description: >-
      The largest version you can publish, in bytes (25 MB).
  - name: LIMIT_VERSIONS_KEPT
    group: Limits
    default: "20"
    description: >-
      How many old versions of each page are kept.
  - name: LIMIT_ARTIFACTS_PER_TENANT
    group: Limits
    default: "200"
    description: >-
      How many live pages each workspace may have.
---

# byagent

byagent gives everything your AI agents make a shareable link. Agents publish HTML or Markdown from the command line; readers comment on any line without an account; the agent reads the comments, fixes the page and republishes to the same link. Works with Claude Code, Codex, Cursor and any agent with a shell.

## Features

- One link per piece of work; republishing keeps the link and the old versions, with diff and rollback
- Comments and suggested edits on any line, no account needed
- Markdown becomes a styled page; a folder with `index.html` ships as is
- Projects, page passwords, share codes, expiry and view counts
- Dashboard, API keys and an MCP server

## How to use

1. Set `PUBLIC_URL` to your ZimaOS IP before you install.
2. Copy the admin token from the app's logs (CREDENTIALS box).
3. On your computer, run `npx byagent login --key <token> --server http://[ZIMAOS-IP-ADDRESS]:6699`.
4. Publish: `npx byagent publish ./plan.md`, and share the link.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6699`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6699`. Every link byagent hands out starts with it. To share pages with people outside your home, put byagent behind a reverse proxy and use your https domain instead.

This install's admin token (an API key) and signing key are made on first start and kept in the data folder. The token is shown in the app's logs, in the box marked CREDENTIALS, on every start. For the dashboard, open `/app/login`, type any email, and copy the sign-in code from the logs; set `EMAIL_PROVIDER=resend` for real email. More settings are in the Variables tab; add them in the app settings. It starts in a few seconds.
