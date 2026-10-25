---
site: https://coder.com
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Workspaces, Templates, Workspace, Web terminal, VS Code in the browser, Template editor, Users, Deployment settings, Audit log]
variables:
  - name: CODER_OIDC_ISSUER_URL
    group: Sign in with Pocket ID / OIDC
    default: ""
    description: >-
      Your sign-in provider's address, like https://pocketid.example.com.
      Leave it out to use only Coder's own accounts.
  - name: CODER_OIDC_CLIENT_ID
    group: Sign in with Pocket ID / OIDC
    default: ""
    description: >-
      The Client ID of the app you made for Coder in Pocket ID (or another
      OIDC provider).
  - name: CODER_OIDC_CLIENT_SECRET
    group: Sign in with Pocket ID / OIDC
    default: ""
    description: >-
      The Client Secret of that app. In the provider, set the callback URL
      to your PUBLIC_URL followed by /api/v2/users/oidc/callback.
  - name: CODER_OIDC_SIGN_IN_TEXT
    group: Sign in with Pocket ID / OIDC
    default: OpenID Connect
    description: >-
      The text on the sign-in button, like Sign in with Pocket ID.
  - name: CODER_OIDC_ICON_URL
    group: Sign in with Pocket ID / OIDC
    default: ""
    description: >-
      A link to an icon shown on the sign-in button.
  - name: CODER_OIDC_ALLOW_SIGNUPS
    group: Sign in with Pocket ID / OIDC
    default: "true"
    description: >-
      Set to false so only people who already have a Coder account can sign
      in with OIDC.
  - name: CODER_OIDC_EMAIL_DOMAIN
    group: Sign in with Pocket ID / OIDC
    default: ""
    description: >-
      Only let people with an email at these domains sign in, like
      example.com. Separate several with commas.
  - name: CODER_OIDC_SCOPES
    group: Sign in with Pocket ID / OIDC
    default: openid,profile,email
    description: >-
      The scopes Coder asks your provider for. Add groups to sync groups.
  - name: CODER_OIDC_IGNORE_EMAIL_VERIFIED
    group: Sign in with Pocket ID / OIDC
    default: "false"
    description: >-
      Set to true if your provider does not mark emails as verified.
  - name: CODER_OIDC_USERNAME_FIELD
    group: Sign in with Pocket ID / OIDC
    default: preferred_username
    description: >-
      Which field from the provider becomes the Coder user name.
  - name: CODER_OIDC_GROUP_FIELD
    group: Sign in with Pocket ID / OIDC
    default: ""
    description: >-
      The field that holds the user's groups, like groups. Leave it out to
      not sync groups.
  - name: CODER_OIDC_GROUP_AUTO_CREATE
    group: Sign in with Pocket ID / OIDC
    default: "false"
    description: >-
      Set to true to make missing Coder groups when they come from the
      provider.
  - name: CODER_OIDC_SIGNUPS_DISABLED_TEXT
    group: Sign in with Pocket ID / OIDC
    default: ""
    description: >-
      The message people see when sign-up is off and they have no account.
  - name: CODER_DISABLE_PASSWORD_AUTH
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to turn off Coder's own user name and password sign-in.
      Only do this after you have signed in with OIDC or GitHub once, or you
      lock yourself out.
  - name: CODER_SESSION_DURATION
    group: Sign-up and accounts
    default: 24h0m0s
    description: >-
      How long a browser sign-in lasts, like 72h.
  - name: CODER_MAX_TOKEN_LIFETIME
    group: Sign-up and accounts
    default: 876600h0m0s
    description: >-
      The longest time an API token may last.
  - name: CODER_OAUTH2_GITHUB_CLIENT_ID
    group: Sign in with GitHub
    default: ""
    description: >-
      The Client ID of a GitHub OAuth app. Leave it out to keep GitHub
      sign-in off.
  - name: CODER_OAUTH2_GITHUB_CLIENT_SECRET
    group: Sign in with GitHub
    default: ""
    description: >-
      The Client Secret of that GitHub OAuth app. Its callback URL is your
      PUBLIC_URL followed by /api/v2/users/oauth2/github/callback.
  - name: CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS
    group: Sign in with GitHub
    default: "false"
    description: >-
      Set to true so new people can sign up with GitHub.
  - name: CODER_OAUTH2_GITHUB_ALLOWED_ORGS
    group: Sign in with GitHub
    default: ""
    description: >-
      Only members of these GitHub organizations may sign in. Separate
      several with commas.
  - name: CODER_OAUTH2_GITHUB_ALLOWED_TEAMS
    group: Sign in with GitHub
    default: ""
    description: >-
      Only members of these teams may sign in, written as org/team.
  - name: CODER_OAUTH2_GITHUB_ALLOW_EVERYONE
    group: Sign in with GitHub
    default: "false"
    description: >-
      Set to true to let any GitHub user sign in, whatever their
      organization.
  - name: CODER_OAUTH2_GITHUB_ENTERPRISE_BASE_URL
    group: Sign in with GitHub
    default: ""
    description: >-
      Your GitHub Enterprise address, if you use one instead of github.com.
  - name: CODER_OAUTH2_GITHUB_DEFAULT_PROVIDER_ENABLE
    group: Sign in with GitHub
    default: "true"
    description: >-
      Coder offers a shared GitHub sign-in until you set your own app. Set
      to false to turn that off.
  - name: CODER_EXTERNAL_AUTH_GITHUB_DEFAULT_PROVIDER_ENABLE
    group: Sign in with GitHub
    default: "true"
    description: >-
      Set to false to turn off Coder's shared GitHub login for git in
      workspaces.
  - name: CODER_EMAIL_SMARTHOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server and port, like smtp.gmail.com:587. Leave it out and
      Coder sends no emails.
  - name: CODER_EMAIL_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address on emails, like coder@example.com.
  - name: CODER_EMAIL_AUTH_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: CODER_EMAIL_AUTH_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: CODER_EMAIL_HELLO
    group: Email (SMTP)
    default: localhost
    description: >-
      The name Coder gives the mail server when it says hello.
  - name: CODER_EMAIL_FORCE_TLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for a server on port 465 that uses TLS from the start.
  - name: CODER_EMAIL_TLS_STARTTLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to always upgrade the connection with STARTTLS.
  - name: CODER_EMAIL_TLS_SKIPVERIFY
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to accept a mail server with a self-signed certificate.
  - name: CODER_WILDCARD_ACCESS_URL
    group: Server
    default: ""
    description: >-
      A wildcard domain for workspace apps, like *.coder.example.com. Needs
      matching DNS and HTTPS. Leave it out to serve apps on a path.
  - name: CODER_REDIRECT_TO_ACCESS_URL
    group: Server
    default: "false"
    description: >-
      Set to true to send everyone to PUBLIC_URL when they open Coder at
      another address.
  - name: CODER_SECURE_AUTH_COOKIE
    group: Server
    default: "false"
    description: >-
      Set to true when Coder is only used over HTTPS.
  - name: CODER_STRICT_TRANSPORT_SECURITY
    group: Server
    default: "0"
    description: >-
      Seconds browsers should only use HTTPS, like 31536000. Only for HTTPS.
  - name: CODER_PROXY_TRUSTED_HEADERS
    group: Server
    default: ""
    description: >-
      Headers from your reverse proxy that carry the visitor's IP, like
      X-Forwarded-For.
  - name: CODER_PROXY_TRUSTED_ORIGINS
    group: Server
    default: ""
    description: >-
      The IP ranges of your reverse proxy, like 172.17.0.0/16.
  - name: CODER_DERP_SERVER_STUN_ADDRESSES
    group: Server
    default: stun.l.google.com:19302,stun1.l.google.com:19302,stun2.l.google.com:19302,stun3.l.google.com:19302,stun4.l.google.com:19302
    description: >-
      STUN servers for direct connections to workspaces. Set to disable to
      use none.
  - name: CODER_BLOCK_DIRECT
    group: Server
    default: "false"
    description: >-
      Set to true so all workspace traffic goes through Coder, never direct.
  - name: CODER_PROVISIONER_DAEMONS
    group: Features
    default: "3"
    description: >-
      How many workspace builds can run at the same time.
  - name: CODER_DISABLE_PATH_APPS
    group: Features
    default: "false"
    description: >-
      Set to true to stop serving workspace apps on a path. Safer with a
      wildcard domain.
  - name: CODER_DISABLE_OWNER_WORKSPACE_ACCESS
    group: Features
    default: "false"
    description: >-
      Set to true so admins cannot open other people's workspaces.
  - name: CODER_EXPERIMENTS
    group: Features
    default: ""
    description: >-
      Experimental features to turn on, separated by commas.
  - name: CODER_TELEMETRY_ENABLE
    group: Features
    default: "true"
    description: >-
      Set to false to stop sending usage data to Coder.
  - name: CODER_UPDATE_CHECK
    group: Features
    default: "false"
    description: >-
      Set to true to show a message when a new Coder version is out.
  - name: CODER_AUDIT_LOGS_RETENTION
    group: Logs
    default: "0"
    description: >-
      How long to keep audit logs, like 2160h for 90 days. 0 keeps them
      forever.
  - name: CODER_WORKSPACE_AGENT_LOGS_RETENTION
    group: Logs
    default: 7d
    description: >-
      How long to keep workspace start-up logs.
  - name: CODER_VERBOSE
    group: Logs
    default: "false"
    description: >-
      Set to true for detailed logs while you fix a problem.
  - name: CODER_LOG_FILTER
    group: Logs
    default: ""
    description: >-
      Only show log lines that match this pattern.
---

# Coder

Coder turns your server into a cloud development platform: full development environments that open in your browser or in your own IDE, like a self-hosted GitHub Codespaces. This is Coder in a single container, with PostgreSQL inside, one port and one data folder. The database password is made for you on first start.

## Features

- Development environments and terminals in the browser, with no local setup
- Connect from VS Code, JetBrains or any SSH editor
- Workspaces defined as code with Terraform templates
- Sign in with Pocket ID or any OIDC provider, or with GitHub, next to Coder's own accounts
- Docker workspaces when you add the Docker socket (below)
- PostgreSQL 17 inside, no second container to look after

## How to use

1. Open Coder from your dashboard.
2. The first person to open it makes the admin account in the browser.
3. Open Templates and start from a starter template, or import your own.
4. Create a workspace from a template to get a browser IDE and terminal.
5. Connect your own VS Code or JetBrains IDE to the same workspace if you like.
6. For Pocket ID, GitHub sign-in or email, add the settings from the Variables tab.

## Docker workspaces

Most starter templates make each workspace a Docker container. For that, Coder needs your server's Docker socket. In the app settings, add a volume with host path `/var/run/docker.sock` and container path `/var/run/docker.sock`, then restart. The log then says "Docker socket found". This gives Coder full control of Docker on your server, so only do it if you trust everyone who can sign in to Coder.

## Sign in with Pocket ID

1. In Pocket ID, make a new OIDC client. Set its callback URL to your `PUBLIC_URL` followed by `/api/v2/users/oidc/callback`, for example `http://192.168.1.20:6145/api/v2/users/oidc/callback`.
2. In the Coder app settings, add `CODER_OIDC_ISSUER_URL` (your Pocket ID address), `CODER_OIDC_CLIENT_ID` and `CODER_OIDC_CLIENT_SECRET`. Add `CODER_OIDC_SIGN_IN_TEXT=Sign in with Pocket ID` if you like.
3. Restart Coder and sign in with the new button.
4. Only after that works, you can add `CODER_DISABLE_PASSWORD_AUTH=true`.

## Before you install

Set `PUBLIC_URL` to your ZimaOS IP, like `http://192.168.1.20:6145` (or your HTTPS domain). Workspaces connect back to Coder at that address, so `localhost` only works on the server itself. The first start takes about three minutes while the database is set up. The first person to open Coder makes the admin account, so do it right away. More settings, like Pocket ID, GitHub sign-in and email, are in the Variables tab; add them in the app settings.
