---
site: https://affine.pro
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Panel, path: /admin, icon: server }
screenshots: [Whiteboard, Brainstorm with AI, Documents, Admin panel]
variables:
  - name: AFFINE_SERVER_NAME
    group: Server
    default: AFFiNE Self Hosted Server
    description: >-
      The name shown when you connect from the AFFiNE desktop or mobile app.
  - name: AFFINE_ALLOW_SIGNUP
    group: Sign-up and accounts
    default: 'true'
    description: >-
      Set to false so only people you invite can join. Default: anyone who can
      open the page can sign up.
  - name: AFFINE_ALLOW_SIGNUP_FOR_OAUTH
    group: Sign-up and accounts
    default: 'true'
    description: >-
      Set to false to stop new accounts made with Google, GitHub or OIDC sign-in.
  - name: AFFINE_PASSWORD_MIN_LENGTH
    group: Sign-up and accounts
    default: '8'
    description: >-
      The shortest password people may choose.
  - name: AFFINE_PASSWORD_MAX_LENGTH
    group: Sign-up and accounts
    default: '32'
    description: >-
      The longest password people may choose.
  - name: AFFINE_ALLOW_GUEST_DEMO_WORKSPACE
    group: Sign-up and accounts
    default: 'true'
    description: >-
      Set to false so visitors who are not signed in can't make a demo
      workspace.
  - name: MAILER_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com. AFFiNE uses email for invites,
      sign-in links and password resets. Leave it out and AFFiNE sends no
      emails.
  - name: MAILER_PORT
    group: Email (SMTP)
    default: '465'
    description: >-
      Your email server port, usually 465 or 587.
  - name: MAILER_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The username for your email server.
  - name: MAILER_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server. For Gmail, use an app password.
  - name: MAILER_SENDER
    group: Email (SMTP)
    default: AFFiNE Self Hosted <noreply@example.com>
    description: >-
      The "from" address on emails, like AFFiNE <you@example.com>.
  - name: MAILER_IGNORE_TLS
    group: Email (SMTP)
    default: 'false'
    description: >-
      Set to true if your email server uses a self-signed certificate.
  - name: MAILER_SERVERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The name AFFiNE gives itself when it talks to the email server (HELO),
      like mail.example.com. Leave it out to use the container hostname.
  - name: AFFINE_OAUTH_GOOGLE_CLIENT_ID
    group: Sign in with Google, GitHub or OIDC
    default: ""
    description: >-
      Client ID for "Sign in with Google". In Google Cloud, set the redirect
      URL to your PUBLIC_URL followed by /oauth/callback. Leave it out to keep
      Google sign-in off.
  - name: AFFINE_OAUTH_GOOGLE_CLIENT_SECRET
    group: Sign in with Google, GitHub or OIDC
    default: ""
    description: >-
      Client secret for "Sign in with Google".
  - name: AFFINE_OAUTH_GITHUB_CLIENT_ID
    group: Sign in with Google, GitHub or OIDC
    default: ""
    description: >-
      Client ID for "Sign in with GitHub". In GitHub, set the callback URL to
      your PUBLIC_URL followed by /oauth/callback. Leave it out to keep GitHub
      sign-in off.
  - name: AFFINE_OAUTH_GITHUB_CLIENT_SECRET
    group: Sign in with Google, GitHub or OIDC
    default: ""
    description: >-
      Client secret for "Sign in with GitHub".
  - name: AFFINE_OAUTH_OIDC_ISSUER
    group: Sign in with Google, GitHub or OIDC
    default: ""
    description: >-
      The issuer URL of your own sign-in service (Authentik, Keycloak, Pocket
      ID...), like https://auth.example.com/application/o/affine/. Leave it
      out to keep OIDC sign-in off.
  - name: AFFINE_OAUTH_OIDC_CLIENT_ID
    group: Sign in with Google, GitHub or OIDC
    default: ""
    description: >-
      Client ID from your OIDC sign-in service. Set its redirect URL to your
      PUBLIC_URL followed by /oauth/callback.
  - name: AFFINE_OAUTH_OIDC_CLIENT_SECRET
    group: Sign in with Google, GitHub or OIDC
    default: ""
    description: >-
      Client secret from your OIDC sign-in service.
  - name: AFFINE_COPILOT_ENABLED
    group: AI and search
    default: 'false'
    description: >-
      Set to true to turn on AI features. Each workspace owner then adds their
      own AI provider key in Workspace Settings, Integrations, AI BYOK.
  - name: AFFINE_COPILOT_ALLOW_CUSTOM_ENDPOINT
    group: AI and search
    default: 'false'
    description: >-
      Set to true to let workspace owners use a custom AI endpoint (like a
      local Ollama or an OpenAI-compatible server).
  - name: AFFINE_INDEXER_ENABLED
    group: AI and search
    default: 'true'
    description: >-
      Set to false to turn off full-text search across documents.
---

# AFFiNE

AFFiNE is an open-source workspace that puts documents, an endless whiteboard and databases in one editor, like Notion and Miro together. This is AFFiNE in a single container, with one port and one data folder. Database passwords and the server key are made for you on first start.

## Features

- Rich documents for notes, wikis and knowledge bases
- An endless canvas for whiteboards, brainstorming and planning
- Databases with table and kanban views
- Real-time collaboration and sharing
- Built-in search across all your workspaces
- Sign in with Google, GitHub or your own OIDC service (Authentik, Keycloak...)
- Change sign-up rules, email and more by adding a setting in the app settings
- Admin panel for users, settings, email and AI (bring your own key)
- PostgreSQL with pgvector and Redis inside, nothing else to install

## How to use

1. Open AFFiNE from your dashboard.
2. The first time, AFFiNE asks you to create the admin account. Fill in your name, email and a password.
3. Sign in and create your first workspace.
4. Change server settings, email and AI any time in the admin panel at `http://your-server-ip:6102/admin`.

## Before you install

To use AFFiNE from other devices, change `localhost` in `PUBLIC_URL` to your server's IP address. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. Add the `MAILER_` settings if you want AFFiNE to send emails, and add `AFFINE_ALLOW_SIGNUP=false` after you made your account if only invited people should join. The first start takes about 5 minutes while the database is set up. There is no default password: you make the admin account the first time you open AFFiNE.
