---
site: https://trackie.nz
services:
  - { name: Trackie, path: /, icon: globe }
  - { name: Sign-in server (Logto), path: /oidc/.well-known/openid-configuration, icon: plug, port: 6165 }
  - { name: Logto admin console, path: /, icon: server, port: 6166 }
screenshots: [Budget, Accounts, Reports]
variables:
  - name: LOGTO_ENDPOINT
    group: Server
    default: ""
    description: >-
      The sign-in server's address, when it has its own domain, like
      https://auth.example.com. Leave it out to use your PUBLIC_URL host with
      port 6165.
  - name: LOGTO_ADMIN_ENDPOINT
    group: Server
    default: ""
    description: >-
      The Logto admin console's address, when it has its own domain. Leave it
      out to use your PUBLIC_URL host with port 6166.
  - name: ACTUAL_OPENID_DISCOVERY_URL
    group: Server
    default: ""
    description: >-
      Use another sign-in provider instead of the built-in Logto, like
      https://auth.example.com/.well-known/openid-configuration. It must
      send a verified email. Leave it out for the built-in Logto.
  - name: TRACKIE_SUPPORT_EMAIL
    group: Server
    default: ""
    description: >-
      An email address shown in Trackie's Help menu. Leave it out to hide
      that menu entry.
  - name: ACTUAL_TOKEN_EXPIRATION
    group: Sign-in
    default: "7776000"
    description: >-
      How long people stay signed in, in seconds. The default is 90 days.
  - name: ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB
    group: Files
    default: "20"
    description: >-
      The largest file people can upload (like a budget import), in
      megabytes.
  - name: ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB
    group: Files
    default: "20"
    description: >-
      The largest budget file that can sync, in megabytes.
  - name: ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB
    group: Files
    default: "50"
    description: >-
      The largest encrypted budget file that can sync, in megabytes.
  - name: ACTUAL_IDENTITY_SECRET
    group: Keys
    default: ""
    description: >-
      Turns each email into the account's id. Leave it out: one is made on
      first start and kept in state/secrets.env. Never change it later, or
      nobody finds their budget again.
  - name: ACTUAL_AKAHU_TOKEN_SECRET
    group: Keys
    default: ""
    description: >-
      Encrypts people's Akahu bank tokens. Leave it out: one is made on
      first start. If it changes, people paste their Akahu tokens again.
---

# Trackie (Actual Budget - NZ Fork)

Trackie is a New Zealand fork of Actual Budget, a fast, private, open-source budgeting app. This is the same code that runs trackie.nz, in a single container with its Logto sign-in server and PostgreSQL inside. The secret keys and database passwords are made for you on first start, and Logto's signing key is switched to RSA for you.

## Features

- Your own private budget for each person, made the first time they sign in
- Passwordless sign-in with a code sent by email, through the built-in Logto server
- Optional end-to-end encryption you control
- NZ bank sync through Akahu, with each person's own tokens
- NZ defaults: DD/MM/YYYY dates, weeks start on Monday

## How to use

1. Do the one-time Logto setup below.
2. Open Trackie from your dashboard.
3. Sign in with your email to make your budget.
4. Link your bank under Settings if you want transactions to sync by themselves.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6164`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6164` (or your own HTTPS domain). Until you do, sign-in can't work and the app only shows a note telling you to set it. Leave `ACTUAL_OPENID_CLIENT_ID` and `ACTUAL_OPENID_CLIENT_SECRET` blank. After about three minutes, open the Logto admin console at `http://[ZIMAOS-IP-ADDRESS]:6166` and make your Logto admin account. In Logto, add an SMTP email connector (Connectors, Email and SMS) so sign-in codes can be sent, set Sign-in experience to Email with a Verification code, and make a Traditional web app called Trackie with the redirect URI `http://[ZIMAOS-IP-ADDRESS]:6164/openid/callback`. Put its App ID and App secret in `ACTUAL_OPENID_CLIENT_ID` and `ACTUAL_OPENID_CLIENT_SECRET` in the app settings; Trackie starts after that (until then, port 6164 shows a short note). Without HTTPS, browsers may say Trackie can't run: click Advanced options and use the fallback mode, or put Trackie behind HTTPS. Back up the app folder, especially `state/secrets.env`. The other settings are in the Variables tab; add them in the app settings. Trackie runs on amd64 (Intel and AMD) only.
