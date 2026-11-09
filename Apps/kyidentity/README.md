---
name: KyIdentity
site: https://busnes.app
source: https://github.com/Busnes-app/KyIdentity-server
services:
  - { name: Web App, path: /, icon: globe }
  - { name: OpenID Connect discovery, path: /.well-known/openid-configuration, icon: info }
screenshots: [Applications (dark), Applications (light)]
variables:
  - name: TRUSTED_PROXY_CIDRS
    group: Reverse proxy
    default: ""
    description: >-
      The address of your reverse proxy as KyIdentity sees it, like
      172.17.0.1/32, so it believes the visitor's IP and https from the
      proxy. Only your proxy; never a whole network.
  - name: KYIDENTITY_FORWARDED_HEADER
    group: Reverse proxy
    default: X-Forwarded-For
    description: >-
      The one header your proxy puts the visitor's IP in. Use
      CF-Connecting-IP behind Cloudflare.
  - name: KYIDENTITY_SECURE_COOKIES
    group: Reverse proxy
    default: ""
    description: >-
      Set to true when your proxy serves https but doesn't send
      X-Forwarded-Proto, so sign-in cookies are marked secure.
  - name: KYIDENTITY_SESSION_TTL
    group: Sign-in
    default: 24h
    description: >-
      How long a sign-in lasts, like 24h or 12h.
  - name: KYIDENTITY_SESSION_IDLE_TTL
    group: Sign-in
    default: 8h
    description: >-
      Sign out after this long without use, like 8h. Can't be longer than
      KYIDENTITY_SESSION_TTL.
  - name: KYIDENTITY_ALLOW_PRIVATE_CALLBACKS
    group: Sign-in
    default: "false"
    description: >-
      Set to true when the other Ky apps call back over your home network
      (a 192.168.x.x or 10.x.x.x address, or plain http).
  - name: PUSH_RELAY_URL
    group: Push MFA (KyAuth app)
    default: https://fcm.relay.kyauth.busnes.app
    description: >-
      The relay that sends sign-in approvals to KyAuth on Android. Set it
      empty to turn Android push off (TOTP and passkeys still work).
  - name: APNS_RELAY_URL
    group: Push MFA (KyAuth app)
    default: https://apn.relay.kyauth.busnes.app
    description: >-
      The relay that sends sign-in approvals to KyAuth on iPhone. Set it
      empty to turn iPhone push off.
  - name: KYIDENTITY_BACKUP_DEPOSIT_INTERVAL
    group: Backups
    default: 24h
    description: >-
      How often KyIdentity sends an encrypted backup to a paired KyRecovery.
  - name: KYIDENTITY_BACKUP_DIR
    group: Backups
    default: ""
    description: >-
      A folder inside the container for local backup copies, like
      /data/backups.
  - name: KYIDENTITY_BACKUP_KEEP
    group: Backups
    default: "7"
    description: >-
      How many local backup copies to keep.
  - name: KYIDENTITY_SECRET_KEY
    group: Keys
    default: ""
    description: >-
      A 64-character hex key (openssl rand -hex 32). Made on first start and
      kept in the data folder when left out; never change it afterwards.
  - name: KYIDENTITY_ENCRYPTION_KEY
    group: Keys
    default: ""
    description: >-
      A 64-character hex key that encrypts MFA secrets. Made on first start
      when left out; never change it afterwards.
---

# KyIdentity

KyIdentity is the identity provider of the Busnes Ky Suite: one place for people, groups, app access and MFA. KyNotes, KyDrive, KyCalendar, KyPost and the other Ky apps sign in through it, and so can any app that speaks OpenID Connect. It also works on its own.

## Features

- User directory with groups, delegated admins and account end dates
- OpenID Connect and OAuth 2.0 provider (PKCE, JWKS, RS256)
- MFA: authenticator apps (TOTP), passkeys, recovery codes and push approvals with the KyAuth phone app
- App launcher, audit log, alerts and SCIM provisioning
- Encrypted backups to KyRecovery

## How to use

1. Put KyIdentity behind your reverse proxy with an https domain and set `KYIDENTITY_ISSUER_URL` to it before you install.
2. Find the first password in `first-run-password.txt` in the data folder.
3. Open your https address and sign in as `admin`.
4. Choose a new password, set up MFA and add your users.
5. Connect the other Ky apps under **App connections**.

## Before you install

**You must set `KYIDENTITY_ISSUER_URL` first.** KyIdentity only runs on an https address (or on `http://localhost:6695`, on the box itself). Set up a reverse proxy with your own domain, like `https://id.example.com`, pointed at `http://[ZIMAOS-IP-ADDRESS]:6695`, and put that domain in `KYIDENTITY_ISSUER_URL`. Never change it after apps are connected.

The first administrator is `admin`. Leave `BOOTSTRAP_ADMIN_PASS` empty and a password is written to `first-run-password.txt` in `/DATA/AppData/kyidentity/data` (open it with the Files app); it is never printed in the logs. You choose a new password at the first sign-in, and the file is then deleted.

Tell KyIdentity your proxy's address with `TRUSTED_PROXY_CIDRS` so the audit log and rate limits see real visitor addresses. That and the other settings are in the Variables tab; add them in the app settings. It starts in a few seconds. The image is built for amd64 only.
