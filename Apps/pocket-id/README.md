---
site: https://pocket-id.org
services:
  - { name: Web App, path: /, icon: globe }
  - { name: First Setup, path: /setup, icon: plus-circle }
variables:
  - name: ENCRYPTION_KEY
    group: Server
    default: ""
    description: >-
      Your own encryption key, at least 16 characters. Leave it out: each
      install makes its own on first start and keeps it in the data folder as
      .encryption_key. Never change the key after the first start, or Pocket
      ID can't read its data.
  - name: TRUST_PROXY
    group: Server
    default: "false"
    description: >-
      The reverse proxies Pocket ID takes the visitor's real IP from, as a
      comma-separated list of IPs or ranges like 172.17.0.0/16. Set to true to
      trust every address, only when Pocket ID can't be reached without your
      proxy.
  - name: TRUSTED_PLATFORM
    group: Server
    default: ""
    description: >-
      The header your CDN puts the visitor's IP in, like CF-Connecting-IP for
      Cloudflare. Use it instead of TRUST_PROXY behind a CDN.
  - name: INTERNAL_APP_URL
    group: Server
    default: ""
    description: >-
      Another address for the token and key endpoints, for apps that reach
      Pocket ID on your network instead of through APP_URL, like
      http://192.168.1.20:6157. Leave it out to use APP_URL.
  - name: DB_CONNECTION_STRING
    group: Server
    default: data/pocket-id.db
    description: >-
      A PostgreSQL database instead of the built-in SQLite one, like
      postgres://pocketid:password@192.168.1.20:5432/pocketid. Set it before
      the first start: data already in SQLite is not moved.
  - name: MAXMIND_LICENSE_KEY
    group: Server
    default: ""
    description: >-
      A free MaxMind GeoLite2 key, so the audit log shows where sign-ins came
      from instead of "unknown".
  - name: ALLOW_INSECURE_CALLBACK_URLS
    group: Security
    default: "true"
    description: >-
      Set to false to refuse http:// callback URLs on hosts other than
      localhost. Keep it true if one of your apps only runs on http.
  - name: AUDIT_LOG_RETENTION_DAYS
    group: Security
    default: "90"
    description: >-
      How many days the audit log keeps sign-in events.
  - name: UI_CONFIG_DISABLED
    group: Application Configuration
    default: "false"
    description: >-
      Set to true to take the Application Configuration settings below from
      these variables instead of the admin pages. Then add each one only with
      a value: an empty one counts as set.
  - name: APP_NAME
    group: Application Configuration
    default: Pocket ID
    description: >-
      The name shown in the UI and in emails, up to 30 characters. Needs
      UI_CONFIG_DISABLED=true.
  - name: SESSION_DURATION
    group: Application Configuration
    default: "60"
    description: >-
      How many minutes a Pocket ID session lasts before people sign in again.
      Needs UI_CONFIG_DISABLED=true.
  - name: ALLOW_USER_SIGNUPS
    group: Application Configuration
    default: disabled
    description: >-
      Who can make an account: disabled (only the admin adds people),
      withToken (people with a sign-up link) or open (anyone). Needs
      UI_CONFIG_DISABLED=true.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Needs UI_CONFIG_DISABLED=true;
      otherwise set email up in the admin pages.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server's port, like 587 or 465.
  - name: SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address, like id@example.com.
  - name: SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: SMTP_TLS
    group: Email (SMTP)
    default: none
    description: >-
      How to encrypt the connection: none, starttls (usually port 587) or tls
      (usually port 465).
  - name: EMAIL_LOGIN_NOTIFICATION_ENABLED
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to email people when they sign in from a new device.
  - name: EMAIL_ONE_TIME_ACCESS_AS_ADMIN_ENABLED
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true so admins can email a sign-in code to someone who lost
      their passkey.
  - name: ANALYTICS_DISABLED
    group: Privacy
    default: "false"
    description: >-
      Set to true to stop the daily anonymous heartbeat that counts running
      Pocket ID servers.
  - name: VERSION_CHECK_DISABLED
    group: Privacy
    default: "false"
    description: >-
      Set to true to stop Pocket ID checking GitHub for new versions.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much Pocket ID writes to the app log: debug, info, warn or error.
---

# Pocket ID

Pocket ID is a simple, OpenID Connect Certified OIDC and OAuth 2.0 provider built around passkeys. There are no passwords to leak: people sign in with a passkey or a hardware key like a YubiKey. Every install makes its own encryption key on first start.

## Features

- Passkey-only sign-in, with no passwords anywhere in the system
- OpenID Connect Certified and OAuth 2.0 compliant, so it works with most apps that offer "Login with OIDC"
- Simple admin pages for users, groups and OIDC clients, without the complexity of Keycloak or Authentik
- Optional self-service sign-up, LDAP sync and SCIM provisioning
- SQLite built in, so there is no separate database to look after

## How to use

1. Open Pocket ID at the address you set in `APP_URL`.
2. Go to the `/setup` page and create the first admin account with a passkey.
3. Add your users, or connect LDAP if you already have a directory.
4. Create an OIDC client for each app you want to sign in to with Pocket ID.
5. In that app's OIDC settings, type your Pocket ID address and the client ID and secret.
6. Branding, email and sign-up rules are in the admin pages under Application Configuration.

## Before you install

Set `APP_URL` to the exact address you will open Pocket ID at, like `https://id.example.com`, before the first start, and don't change it later: passkeys are locked to it. Browsers only allow passkeys on https addresses (or `http://localhost:6157` on the ZimaOS box itself), so put Pocket ID behind a reverse proxy with https. The encryption key is made on first start and kept in the data folder as `.encryption_key`, so back the whole folder up. The app is ready in a few seconds; open your address with `/setup` at the end and make your admin account. More settings are in the Variables tab; add them in the app settings. The Application Configuration ones only work with `UI_CONFIG_DISABLED=true`, and then each one should only be added with a value.
