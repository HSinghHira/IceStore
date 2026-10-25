---
site: https://www.getoutline.com
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Mail Viewer, path: /mail/, icon: mail }
variables:
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Leave it out to keep emails
      (sign-in links, invites) in the built-in mail viewer at /mail.
  - name: SMTP_SERVICE
    group: Email (SMTP)
    default: ""
    description: >-
      A well-known mail service name instead of SMTP_HOST, like gmail or
      SendGrid.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server's port, like 587 or 465.
  - name: SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: SMTP_SECURE
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false for a server on port 587 or 25 that starts plain and
      switches to TLS.
  - name: SMTP_DISABLE_STARTTLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to never switch to TLS. Only for a mail server on your own
      network.
  - name: SMTP_FROM_EMAIL
    group: Email (SMTP)
    default: noreply@outline.local
    description: >-
      The sender address on emails. Most mail servers need this to be an
      address they own.
  - name: SMTP_REPLY_EMAIL
    group: Email (SMTP)
    default: ""
    description: >-
      The reply-to address on emails.
  - name: MP_UI_AUTH
    group: Email (SMTP)
    default: ""
    description: >-
      Your own login for the mail viewer, as user:password. Leave it out to
      use the one made on first start (shown in the app logs).
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your OIDC provider (Pocket ID, Authentik,
      Keycloak...). Set the callback at your provider to
      <PUBLIC_URL>/auth/oidc.callback.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your OIDC provider.
  - name: OIDC_AUTH_URI
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's authorization address, like
      https://id.example.com/authorize.
  - name: OIDC_TOKEN_URI
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's token address, like
      https://id.example.com/api/oidc/token.
  - name: OIDC_USERINFO_URI
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's userinfo address, like
      https://id.example.com/api/oidc/userinfo.
  - name: OIDC_LOGOUT_URI
    group: Sign in with OIDC
    default: ""
    description: >-
      Where to send people when they sign out, to sign them out of the
      provider too.
  - name: OIDC_USERNAME_CLAIM
    group: Sign in with OIDC
    default: preferred_username
    description: >-
      Which claim holds the user name.
  - name: OIDC_DISPLAY_NAME
    group: Sign in with OIDC
    default: OpenID Connect
    description: >-
      The name on the sign-in button, like Pocket ID.
  - name: OIDC_SCOPES
    group: Sign in with OIDC
    default: openid profile email
    description: >-
      The scopes to ask for, separated by spaces.
  - name: GOOGLE_CLIENT_ID
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The client ID of your Google OAuth app.
  - name: GOOGLE_CLIENT_SECRET
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The client secret of your Google OAuth app.
  - name: SLACK_CLIENT_ID
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The client ID of your Slack app.
  - name: SLACK_CLIENT_SECRET
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The client secret of your Slack app.
  - name: AZURE_CLIENT_ID
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The client ID of your Microsoft Entra app.
  - name: AZURE_CLIENT_SECRET
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The client secret of your Microsoft Entra app.
  - name: AZURE_RESOURCE_APP_ID
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The resource app ID of your Microsoft Entra app.
  - name: DISCORD_CLIENT_ID
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The client ID of your Discord app.
  - name: DISCORD_CLIENT_SECRET
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      The client secret of your Discord app.
  - name: DISCORD_SERVER_ID
    group: Sign in with Google, Slack, Microsoft or Discord
    default: ""
    description: >-
      Only let members of this Discord server sign in.
  - name: DEFAULT_LANGUAGE
    group: Server
    default: en_US
    description: >-
      The language for new users, like de_DE or fr_FR.
  - name: FORCE_HTTPS
    group: Server
    default: "false"
    description: >-
      Set to true to make Outline send every visitor to https. Only when
      PUBLIC_URL is https and your proxy forwards to Outline.
  - name: WEB_CONCURRENCY
    group: Server
    default: "1"
    description: >-
      How many Outline processes to run. About one per 512 MB of memory.
  - name: ENABLE_UPDATES
    group: Server
    default: "true"
    description: >-
      Set to false to stop checking for updates (this sends anonymous
      statistics to Outline).
  - name: FILE_STORAGE
    group: File storage
    default: local
    description: >-
      Where uploads are kept: local (the data folder) or s3.
  - name: FILE_STORAGE_UPLOAD_MAX_SIZE
    group: File storage
    default: "262144000"
    description: >-
      The largest file people can upload, in bytes.
  - name: FILE_STORAGE_IMPORT_MAX_SIZE
    group: File storage
    default: ""
    description: >-
      The largest document import, in bytes.
  - name: FILE_STORAGE_WORKSPACE_IMPORT_MAX_SIZE
    group: File storage
    default: ""
    description: >-
      The largest workspace import (like a Notion or Confluence export), in
      bytes.
  - name: AWS_S3_UPLOAD_BUCKET_URL
    group: File storage
    default: ""
    description: >-
      The S3 server and bucket address, when FILE_STORAGE is s3.
  - name: AWS_S3_UPLOAD_BUCKET_NAME
    group: File storage
    default: ""
    description: >-
      The S3 bucket name.
  - name: AWS_ACCESS_KEY_ID
    group: File storage
    default: ""
    description: >-
      The S3 access key.
  - name: AWS_SECRET_ACCESS_KEY
    group: File storage
    default: ""
    description: >-
      The S3 secret key.
  - name: AWS_REGION
    group: File storage
    default: ""
    description: >-
      The S3 region, like us-east-1.
  - name: AWS_S3_FORCE_PATH_STYLE
    group: File storage
    default: "true"
    description: >-
      Keep true for most self-hosted S3 servers (MinIO, Garage).
  - name: GITHUB_CLIENT_ID
    group: Integrations
    default: ""
    description: >-
      The client ID of your GitHub app, for issue and pull request previews.
  - name: GITHUB_CLIENT_SECRET
    group: Integrations
    default: ""
    description: >-
      The client secret of your GitHub app.
  - name: GITHUB_APP_NAME
    group: Integrations
    default: ""
    description: >-
      The name of your GitHub app.
  - name: GITHUB_APP_ID
    group: Integrations
    default: ""
    description: >-
      The ID of your GitHub app.
  - name: GITHUB_APP_PRIVATE_KEY
    group: Integrations
    default: ""
    description: >-
      The private key of your GitHub app.
  - name: GITLAB_CLIENT_ID
    group: Integrations
    default: ""
    description: >-
      The client ID of your GitLab app, for issue and merge request previews.
  - name: GITLAB_CLIENT_SECRET
    group: Integrations
    default: ""
    description: >-
      The client secret of your GitLab app.
  - name: LINEAR_CLIENT_ID
    group: Integrations
    default: ""
    description: >-
      The client ID of your Linear app, for issue previews.
  - name: LINEAR_CLIENT_SECRET
    group: Integrations
    default: ""
    description: >-
      The client secret of your Linear app.
  - name: FIGMA_CLIENT_ID
    group: Integrations
    default: ""
    description: >-
      The client ID of your Figma app, for design previews.
  - name: FIGMA_CLIENT_SECRET
    group: Integrations
    default: ""
    description: >-
      The client secret of your Figma app.
  - name: NOTION_CLIENT_ID
    group: Integrations
    default: ""
    description: >-
      The client ID of your Notion integration, to import Notion pages.
  - name: NOTION_CLIENT_SECRET
    group: Integrations
    default: ""
    description: >-
      The client secret of your Notion integration.
  - name: DROPBOX_APP_KEY
    group: Integrations
    default: ""
    description: >-
      Your Dropbox app key, for Dropbox embeds.
  - name: IFRAMELY_URL
    group: Integrations
    default: ""
    description: >-
      Your Iframely server, for link previews of other sites.
  - name: IFRAMELY_API_KEY
    group: Integrations
    default: ""
    description: >-
      Your Iframely API key.
  - name: RATE_LIMITER_ENABLED
    group: Security
    default: "true"
    description: >-
      Set to false to turn off the request rate limits.
  - name: RATE_LIMITER_REQUESTS
    group: Security
    default: "1000"
    description: >-
      How many requests one visitor may make per time window.
  - name: RATE_LIMITER_DURATION_WINDOW
    group: Security
    default: "60"
    description: >-
      The rate limit time window, in seconds.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much to log: error, warn, info, http, verbose or debug.
  - name: DEBUG
    group: Logs
    default: ""
    description: >-
      Extra debug categories to log, like http.
---

# Outline

Outline is a fast, beautifully designed wiki and knowledge base for teams, with real-time collaborative editing, nested collections and powerful search. This is Outline in a single container, with PostgreSQL, Redis and a mail viewer inside, one port and one data folder. The secret keys and database passwords are made for you on first start, and you can sign in with email right away: no Google, Slack or OIDC app needed.

## Features

- Real-time collaborative editing with a clean Markdown editor
- Nested collections and documents, full-text search and a keyboard-first interface
- Sign in with email links, or add Google, Slack, Microsoft, Discord or any OIDC provider (Pocket ID, Authentik...)
- API and integrations (GitHub, GitLab, Linear, Figma, Notion import)
- Works without an email server: sign-in links and invites go to the built-in mail viewer at `/mail` until you set up SMTP

## How to use

1. Open Outline from your dashboard.
2. On the first visit, Outline asks for a workspace name, your name and your email. That makes you the admin.
3. Create a collection and start writing.
4. To sign in again later, type your email. Until you set up SMTP, the sign-in link is in the mail viewer at `http://your-zimaos-ip:6155/mail/`. Its login is in the app logs.
5. Invite people from Settings, Members.
6. To send real emails or add Google, Slack or OIDC sign-in, add the settings from the Variables tab.

## Before you install

`PUBLIC_URL` starts as `http://localhost:6155`. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6155`; Outline only works at this exact address, so use your own `https://` domain if you put it behind a reverse proxy. The first start takes about three minutes. Until you add an SMTP server, emails go to the mail viewer at `/mail/`; its login is in the app logs on the line that says "mail viewer (/mail) login is", and in `mail-password.txt` in the data folder. SMTP, OIDC (Pocket ID, Authentik...), Google, Slack and the other settings are in the Variables tab; add them in the app settings. For OIDC, set the callback at your provider to `<PUBLIC_URL>/auth/oidc.callback`.
