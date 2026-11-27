---
site: https://busnes.app/kypulse.html
source: https://github.com/Busnes-app/KyPulse-server
services:
  - { name: Web App, path: /, icon: monitor }
screenshots: []
variables:
  - name: KYPULSE_TRUSTED_PROXIES
    group: Reverse proxy
    default: ""
    description: >-
      The address KyPulse sees your reverse proxy connect from, such as
      172.18.0.2/32, so sign-in limits use visitors' real addresses. List only
      your proxy; 0.0.0.0/0 stops KyPulse from starting.
  - name: KYPULSE_COOKIE_SECURE
    group: Reverse proxy
    default: "true"
    description: >-
      Keeps sign-in cookies to https only, which KyPulse needs anyway. Leave it
      out.
  - name: KYPULSE_SESSION_SECRET
    group: Keys
    default: ""
    description: >-
      The secret that protects the sign-in check. Leave it out: KyPulse makes
      one on first start in session.key. A value you set needs at least 16
      characters.
  - name: KYPULSE_KYSIGNON_ISSUER
    group: KyIdentity sign-in
    default: ""
    description: >-
      Your KyIdentity address, such as https://id.example.com. Register your
      KyPulse https address followed by /api/sso/kysignon/callback there, and
      give administrators the kypulse.admin role.
  - name: KYPULSE_KYSIGNON_CLIENT_ID
    group: KyIdentity sign-in
    default: ""
    description: >-
      The client ID KyIdentity gave KyPulse.
  - name: KYPULSE_KYSIGNON_SECRET
    group: KyIdentity sign-in
    default: ""
    description: >-
      The client secret KyIdentity gave KyPulse.
  - name: KYPULSE_KYSIGNON_HMAC_SECRET
    group: KyIdentity sign-in
    default: ""
    description: >-
      The shared secret (16 characters or more) that lets KyIdentity send
      account changes to KyPulse.
  - name: KYPULSE_SSO_ENABLED
    group: KyIdentity sign-in
    default: "true"
    description: >-
      Set to false to turn off single sign-on.
  - name: KYPULSE_SSO_AUTO_PROVISION
    group: KyIdentity sign-in
    default: "true"
    description: >-
      Set to false so people are not given an account automatically the first
      time they sign in through KyIdentity.
  - name: KYPULSE_POLL_WORKERS
    group: Monitoring
    default: "4"
    description: >-
      How many health checks run at the same time, from 1 to 32.
  - name: KYPULSE_ALERT_ALLOW_HTTP
    group: Monitoring
    default: "false"
    description: >-
      Set to true to send alerts to a plain http webhook, such as an ntfy or
      Gotify server on your home network.
  - name: KYPULSE_KYYARD_ALLOW_HTTP
    group: Monitoring
    default: "false"
    description: >-
      Set to true to connect to a KyYard server over plain http.
  - name: KYPULSE_BACKUP_KEEP
    group: Backups
    default: "7"
    description: >-
      How many local backup copies to keep, at least 1.
  - name: KYPULSE_BACKUP_DEPOSIT_INTERVAL
    group: Backups
    default: "24h"
    description: >-
      How often scheduled backups run once a recovery key is set up: at least
      15m. Set 0 to turn them off.
  - name: KYPULSE_BACKUP_ALLOW_PRIVATE_RECOVERY
    group: Backups
    default: "false"
    description: >-
      Set to true when your KyRecovery server is on your home network. It still
      needs https.
  - name: KY_LOG_LEVEL
    group: Logs
    default: "info"
    description: >-
      How much KyPulse writes to its logs: debug, info, warn or error.
---

# KyPulse

KyPulse is the health board of the Busnes Ky Suite: it checks the health address of each Ky app (and any other service you add), shows what is broken first and sends alerts. Local accounts work on their own; KyIdentity (also in IceStore) sign-in is optional.

## Features

- Health checks for every Ky app and any service with a health address
- Broken services first, with alerts to ntfy, Gotify, Discord or another webhook
- Warnings before https certificates expire
- A signed audit log
- Local accounts or KyIdentity sign-in
- Sealed backups, daily once you set up a recovery key

## How to use

1. Set up an https reverse proxy, such as Nginx Proxy Manager, with your own domain. Point it at `http://[ZIMAOS-IP-ADDRESS]:6878`, then set `KYPULSE_APP_URL` to the proxy's https address.
2. Open the app logs and find the box marked **CREDENTIALS**. It has the first `admin` password when `KYPULSE_ADMIN_PASSWORD` was left empty.
3. Open your https address, sign in as `admin` and change the password.
4. On **Status**, press **Add app** and enter a name and health address, such as `http://[ZIMAOS-IP-ADDRESS]:6875/healthz` for KyDrive. Use your ZimaOS IP, not `localhost`.
5. For alerts, fill in the **Alert webhook** under **Settings** → **Server** and press **Send test**.

## Before you install

**KyPulse requires https to sign in. Set `KYPULSE_APP_URL` first.** Its sign-in security check only runs on a secure connection. It starts as `https://pulse.example.com`: replace that with the https address of your own reverse proxy (such as Nginx Proxy Manager or a Cloudflare tunnel), pointed at `http://[ZIMAOS-IP-ADDRESS]:6878`. Opening `http://[ZIMAOS-IP-ADDRESS]:6878` directly shows the sign-in page, but sign-in fails. Give KyPulse its own hostname, not one shared with another Ky app, or they sign each other out. Add `KYPULSE_TRUSTED_PROXIES` so KyPulse can see each visitor's real address.

When `KYPULSE_ADMIN_PASSWORD` is empty, the first password is in the **CREDENTIALS** box in the app logs and in `initial-admin-password` in `/DATA/AppData/kypulse/data` (open it with the Files app). Change it after you sign in, then delete the file. Local accounts have no two-step sign-in; use KyIdentity for that. No backups are made until you pair KyRecovery or add a recovery key on the **Backup** page. Keep the `data`, `backups` and `secrets` folders in `/DATA/AppData/kypulse` together. More optional settings are in the Variables tab; add them in the app settings.
