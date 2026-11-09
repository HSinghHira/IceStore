---
name: KyRecovery
site: https://busnes.app
source: https://github.com/Busnes-app/KyRecovery-server
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Dashboard (dark), Dashboard (light)]
variables:
  - name: KYRECOVERY_TRUSTED_PROXIES
    group: Reverse proxy
    default: ""
    description: >-
      The address KyRecovery sees your proxy connect from, like 172.17.0.1.
      Needed behind a proxy, or one stranger's wrong passwords lock everyone
      out. Open https://<your domain>/api/installer/network to see it
      (clientIp).
  - name: KYRECOVERY_COOKIE_SECURE
    group: Reverse proxy
    default: ""
    description: >-
      true or false to force the secure flag on sign-in cookies. Left out, it
      follows http or https.
  - name: KY_ADMIN_INITIAL_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The local admin password on first start. Left out, one is made and
      saved in initial-admin-password in the data folder.
  - name: KY_SSO_ISSUER
    group: Sign in with KyIdentity
    default: ""
    description: >-
      Your KyIdentity address, like https://id.example.com. Setting it turns
      on single sign-on.
  - name: KY_SSO_CLIENT_ID
    group: Sign in with KyIdentity
    default: ""
    description: >-
      The client ID KyIdentity gave KyRecovery.
  - name: KY_SSO_CLIENT_SECRET
    group: Sign in with KyIdentity
    default: ""
    description: >-
      The client secret KyIdentity gave KyRecovery.
  - name: KY_SSO_REDIRECT_URL
    group: Sign in with KyIdentity
    default: ""
    description: >-
      The callback address registered in KyIdentity for KyRecovery.
  - name: KY_ADMIN_EMAIL
    group: Sign in with KyIdentity
    default: ""
    description: >-
      The verified email of the KyIdentity user who becomes KyRecovery's
      admin.
  - name: KYRECOVERY_SECRET_KEY
    group: Keys
    default: ""
    description: >-
      The server's own key (hex or base64). Made on first start and kept in
      secret.key in the data folder when left out.
---

# KyRecovery

KyRecovery is a "blind" backup store for the Busnes Ky Suite. KyIdentity, KyNotes, KyDNS and the other Ky apps seal their own backups and send them here; KyRecovery keeps them but can't open them. Only the recovery key you make in your browser, split into custodian cards, can restore them.

## Features

- Stores the sealed backups of every paired Ky app
- Recovery key made in your browser and split into cards (Shamir), so no single person or server holds it
- Pair apps with a one-time six-digit code
- Audit log of every backup, pairing and key change
- Local sign-in, or sign-in with KyIdentity

## How to use

1. Put KyRecovery behind your reverse proxy with an https domain.
2. Sign in as `admin` with the password from `initial-admin-password` in the data folder.
3. Run the recovery ceremony to make the key and print the cards.
4. Pair each Ky app with a code, from its admin page.

## Before you install

**KyRecovery needs https.** The other Ky apps only send backups to an https address, and your browser only makes the recovery key on https. Set up a reverse proxy with your own domain, like `https://recovery.example.com`, pointed at `http://[ZIMAOS-IP-ADDRESS]:6698`, then set `KYRECOVERY_TRUSTED_PROXIES` to the proxy's address.

The first `admin` password is written to `initial-admin-password` in `/DATA/AppData/kyrecovery/data` (open it with the Files app); it is never printed in the logs. Change it at the first sign-in and delete the file. Keep a copy of the whole data folder somewhere else: it is where your other Ky apps' backups live. It starts in a few seconds; more settings are in the Variables tab. The image is built for amd64 only.
