---
site: https://penpot.app
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Mail Viewer, path: /mail/, icon: mail }
screenshots: [Design tokens, A design system file, Inspect mode with code, Components in a mobile app design]
variables:
  - name: PENPOT_FLAGS
    group: Features
    default: ""
    description: >-
      Extra Penpot flags, added after the built-in ones, separated by spaces.
      For example disable-registration (only invited people can join),
      enable-login-with-oidc or disable-login-with-password.
  - name: PENPOT_REGISTRATION_DOMAIN_WHITELIST
    group: Sign-up and accounts
    default: ""
    description: >-
      Only let people with these email domains sign up, separated by commas,
      like example.com.
  - name: PENPOT_TELEMETRY_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to send anonymous usage numbers to the Penpot team.
  - name: PENPOT_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com. Leave it out to send every
      email to the built-in mail viewer at /mail instead.
  - name: PENPOT_SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port.
  - name: PENPOT_SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: PENPOT_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: PENPOT_SMTP_TLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for STARTTLS (usually port 587).
  - name: PENPOT_SMTP_SSL
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for TLS from the start (usually port 465).
  - name: PENPOT_SMTP_DEFAULT_FROM
    group: Email (SMTP)
    default: no-reply@penpot.local
    description: >-
      The sender address on emails.
  - name: PENPOT_SMTP_DEFAULT_REPLY_TO
    group: Email (SMTP)
    default: no-reply@penpot.local
    description: >-
      The reply-to address on emails.
  - name: PENPOT_GOOGLE_CLIENT_ID
    group: Sign in with Google, GitHub or GitLab
    default: ""
    description: >-
      Your Google OAuth client ID. Also add enable-login-with-google to
      PENPOT_FLAGS.
  - name: PENPOT_GOOGLE_CLIENT_SECRET
    group: Sign in with Google, GitHub or GitLab
    default: ""
    description: >-
      Your Google OAuth client secret.
  - name: PENPOT_GITHUB_CLIENT_ID
    group: Sign in with Google, GitHub or GitLab
    default: ""
    description: >-
      Your GitHub OAuth app client ID. Also add enable-login-with-github to
      PENPOT_FLAGS.
  - name: PENPOT_GITHUB_CLIENT_SECRET
    group: Sign in with Google, GitHub or GitLab
    default: ""
    description: >-
      Your GitHub OAuth app client secret.
  - name: PENPOT_GITLAB_BASE_URI
    group: Sign in with Google, GitHub or GitLab
    default: https://gitlab.com
    description: >-
      Your GitLab address. Also add enable-login-with-gitlab to PENPOT_FLAGS.
  - name: PENPOT_GITLAB_CLIENT_ID
    group: Sign in with Google, GitHub or GitLab
    default: ""
    description: >-
      Your GitLab application ID.
  - name: PENPOT_GITLAB_CLIENT_SECRET
    group: Sign in with Google, GitHub or GitLab
    default: ""
    description: >-
      Your GitLab application secret.
  - name: PENPOT_OIDC_BASE_URI
    group: Sign in with OIDC
    default: ""
    description: >-
      Your OIDC provider's address, like https://auth.example.com/. Also add
      enable-login-with-oidc to PENPOT_FLAGS.
  - name: PENPOT_OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your OIDC provider.
  - name: PENPOT_OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your OIDC provider.
  - name: PENPOT_OIDC_NAME
    group: Sign in with OIDC
    default: ""
    description: >-
      The name on the sign-in button, like Pocket ID.
  - name: PENPOT_OIDC_SCOPES
    group: Sign in with OIDC
    default: openid profile email
    description: >-
      The scopes to ask for, separated by spaces.
  - name: PENPOT_LDAP_HOST
    group: Sign in with LDAP
    default: ""
    description: >-
      Your LDAP server. Also add enable-login-with-ldap to PENPOT_FLAGS.
  - name: PENPOT_LDAP_PORT
    group: Sign in with LDAP
    default: "10389"
    description: >-
      Your LDAP server port.
  - name: PENPOT_LDAP_BASE_DN
    group: Sign in with LDAP
    default: ""
    description: >-
      Where users are found, like ou=people,dc=example,dc=com.
  - name: PENPOT_LDAP_BIND_DN
    group: Sign in with LDAP
    default: ""
    description: >-
      The account Penpot signs in to LDAP with.
  - name: PENPOT_LDAP_BIND_PASSWORD
    group: Sign in with LDAP
    default: ""
    description: >-
      That account's password.
  - name: MP_UI_AUTH
    group: Mail viewer
    default: ""
    description: >-
      Your own login for the mail viewer at /mail, written as user:password.
      Leave it out for user admin and a password made on first start (shown
      in the CREDENTIALS box).
  - name: MP_MAX_MESSAGES
    group: Mail viewer
    default: "500"
    description: >-
      How many emails the mail viewer keeps.
---

# Penpot

Penpot is a design and prototyping tool that runs in your browser and works with open standards like SVG, CSS and HTML. Designers and developers work in the same files at the same time. PostgreSQL, Redis, the exporter and a mail viewer are built in, so it is one container.

## Features

- Vector design, components, variants and design tokens
- Flex and grid layouts that match how CSS works
- Interactive prototypes with flows and transitions
- Real-time teamwork with comments and version history
- Inspect mode with ready-to-copy CSS, SVG and HTML
- Exports to PNG, JPG, SVG and PDF, plus plugins and an API

## How to use

1. Set `PUBLIC_URL` to `http://[ZIMAOS-IP-ADDRESS]:6751` with your ZimaOS IP before you install.
2. Open Penpot and choose Create an account. The first account is yours.
3. Start a new project and a new file from the dashboard.
4. Invite your team from the team settings. Invitation emails show up in the mail viewer at `/mail` until you set an email server.
5. Use View mode to share prototypes and Inspect mode to hand designs to developers.

Left out: the admin console and the MCP server.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6751`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6751`. Until you do, other devices see a page that tells them to. Behind a domain, use that address instead (`https://design.example.com`).

The first start takes about 5 minutes. Then open your `PUBLIC_URL` and choose Create an account; no email check is needed. To stop others signing up afterwards, add `PENPOT_FLAGS=disable-registration` in the app settings. Emails go to the mail viewer at `http://[ZIMAOS-IP-ADDRESS]:6751/mail/` until you set an email server; its login is in the app's logs in the box marked CREDENTIALS. More settings (email, sign-in with Google, GitHub, GitLab, OIDC or LDAP) are in the Variables tab; add them in the app settings.
