---
site: https://busnes.app/kypost.html
source: https://github.com/Busnes-app/KyPost-Server
services:
  - { name: Web App, path: /, icon: mail }
screenshots: [New message]
variables:
  - name: TRUSTED_PROXY_CIDRS
    group: Reverse proxy
    default: ""
    description: >-
      The address KyPost sees your reverse proxy connect from, such as
      172.18.0.2/32, so sign-in limits use visitors' real addresses. List only
      your proxy, never a range your own devices are in.
  - name: TRUSTED_PROXY_HEADER
    group: Reverse proxy
    default: "x-forwarded-for"
    description: >-
      The header your proxy puts the visitor's address in. Keep it for Nginx
      Proxy Manager; set cf-connecting-ip for a Cloudflare tunnel.
  - name: RATE_LIMIT_EXEMPT_CIDRS
    group: Sign-in protection
    default: ""
    description: >-
      Office networks that skip the per-address sign-in limits, such as
      203.0.113.0/24. Never add your proxy. Ranges wider than /16 (IPv4) or
      /48 (IPv6) stop KyPost from starting.
  - name: SMTP_HOST
    group: Mail servers
    default: ""
    description: >-
      A sending server used for accounts that name none of their own. Leave it
      empty to use each account's settings.
  - name: SMTP_PORT
    group: Mail servers
    default: "587"
    description: >-
      The sending port used when an account names none. 465 uses TLS from the
      start; other ports need STARTTLS.
  - name: SANDBOX_PRIVATE_HOSTS
    group: Mail servers
    default: ""
    description: >-
      Needed for a mail server on your home network or VPN: its hostname, or
      several separated by commas. IP addresses do not work here.
  - name: ALLOW_INSECURE_SMTP
    group: Mail servers
    default: "false"
    description: >-
      Set to true only to send through a relay on a trusted home network that
      has no encryption. Your mail and password then travel unprotected.
  - name: CLASSIFIER_ENGINE
    group: AI sorting
    default: "hybrid"
    description: >-
      hybrid uses the quick built-in sorter first and the AI model when unsure.
      Set llm to send every message to the model.
  - name: OLLAMA_MODEL
    group: AI sorting
    default: "nemotron-3-nano:4b"
    description: >-
      The model that labels mail. gemma4:e4b resists trick emails better but
      needs about 9 GB of memory, so raise the app's memory limit first.
  - name: OLLAMA_BASE_URL
    group: AI sorting
    default: "http://127.0.0.1:11434"
    description: >-
      Set to the address of your own Ollama server to use it instead of the
      built-in one. Message text is sent there, so use https for a server on
      another machine.
  - name: PAIRING_SECRET
    group: Phone apps
    default: ""
    description: >-
      The secret behind phone pairing and pickup links. Leave empty: KyPost
      makes one on first start. A value you set needs at least 32 characters.
  - name: KYPOST_KYDRIVE_URL
    group: KyDrive
    default: ""
    description: >-
      Your KyDrive https address, with no path. Leave empty to pair through
      KyIdentity. Set it together with the secret file.
  - name: KYPOST_KYDRIVE_SECRET_FILE
    group: KyDrive
    default: ""
    description: >-
      A file holding the shared secret (32 characters or more), such as
      /kypost/private/kydrive.secret. Put it in the app's private folder.
  - name: KYPOST_KYDRIVE_ALLOW_PRIVATE
    group: KyDrive
    default: "false"
    description: >-
      Set to true when the KyDrive address points to your home network.
  - name: KYPOST_KYCALENDAR_URL
    group: KyCalendar
    default: ""
    description: >-
      Your KyCalendar https address, with no path. Leave empty to pair through
      KyIdentity. Set it together with the secret file.
  - name: KYPOST_KYCALENDAR_SECRET_FILE
    group: KyCalendar
    default: ""
    description: >-
      A file holding the shared secret (32 characters or more), such as
      /kypost/private/kycalendar.secret. Put it in the app's private folder.
  - name: KYPOST_KYCALENDAR_ALLOW_PRIVATE
    group: KyCalendar
    default: "false"
    description: >-
      Set to true when the KyCalendar address points to your home network.
  - name: KYPOST_KYMESSAGE_URL
    group: KyMessages
    default: ""
    description: >-
      Your KyMessages https address, with no path. Leave empty to pair through
      KyIdentity. Set it together with the secret file.
  - name: KYPOST_KYMESSAGE_SECRET_FILE
    group: KyMessages
    default: ""
    description: >-
      A file holding the shared secret (32 characters or more), such as
      /kypost/private/kymessage.secret. Put it in the app's private folder.
  - name: KYPOST_KYMESSAGE_ALLOW_PRIVATE
    group: KyMessages
    default: "false"
    description: >-
      Set to true when the KyMessages address points to your home network.
  - name: KYPOST_BACKUP_DIR
    group: Backups
    default: ""
    description: >-
      Set to /kypost/state/backups to keep local copies of the sealed backups.
      Set up backups in KyPost under Settings, Server, Backup.
  - name: KYPOST_BACKUP_KEEP
    group: Backups
    default: "7"
    description: >-
      How many local backup copies to keep.
  - name: KYPOST_BACKUP_DEPOSIT_INTERVAL
    group: Backups
    default: "24h"
    description: >-
      How often scheduled backups run: at least 15m. Set 0 to turn them off.
  - name: KY_LOG_LEVEL
    group: Logs
    default: "info"
    description: >-
      How much KyPost writes to its logs: debug, info, warn or error.
---

# KyPost

KyPost is the mail app of the Busnes Ky Suite: a web client for the mailboxes you already have (IMAP and SMTP), that sorts and labels new mail with a small AI model running on your ZimaOS. Nothing leaves your box for the sorting.

## Features

- Read, write and search mail from your existing IMAP and SMTP accounts
- Local AI sorting and labels (Ollama), or turn it off
- Multi-factor sign-in and several users
- Links with KyDrive, KyCalendar and KyIdentity
- Sealed backups of settings and keys

## How to use

1. Set up an https reverse proxy, such as Nginx Proxy Manager, with your own domain. Point it at `http://[ZIMAOS-IP-ADDRESS]:6877`, then set `SERVER_BASE_URL` to the proxy's https address.
2. Open the Files app, go to **AppData**, **kypost**, **config** and open `first-run-password.txt` for the admin user name and password.
3. Open your https address, sign in as `admin` and choose a new password. Then delete the file.
4. Create an everyday account under **Settings** → **Server** → **Manage Users**, and sign in with it. If KyPost asks you to set up an encryption key, keep the recovery copy somewhere safe.
5. Open **Settings** → **Mail** → **Email settings**, enter your mail account, press **Save** and then **Test connection**. The test checks incoming mail only, so also send yourself a message.

## Before you install

**KyPost requires https to sign in. Set `SERVER_BASE_URL` first.** Its sign-in security check only runs on a secure connection. It starts as `https://mail.example.com`: replace that with the https address of your own reverse proxy (such as Nginx Proxy Manager or a Cloudflare tunnel), pointed at `http://[ZIMAOS-IP-ADDRESS]:6877`. Opening `http://[ZIMAOS-IP-ADDRESS]:6877` directly shows the sign-in page, but sign-in fails. Add `TRUSTED_PROXY_CIDRS` so KyPost can see each visitor's real address.

You need a mail account that already works. Incoming mail must use IMAP over TLS (usually port 993), and sending needs port 465 or STARTTLS. Providers with two-step sign-in, such as Gmail, usually need an app password. For a mail server on your home network, also set `SANDBOX_PRIVATE_HOSTS`. KyPost does not receive mail for your own domain in this setup.

The first admin password is in `/DATA/AppData/kypost/config/first-run-password.txt`; it is not shown in the app logs. AI sorting downloads about 3 GB on first start and can use about 3 GB of memory. The web app is ready in a minute or two, and sorting starts after the download. Set `KYPOST_DISABLE_AI_SORTING` to `true` to skip it. Back up the `config`, `private` and `state` folders in `/DATA/AppData/kypost` together: without the keys, saved mail passwords cannot be read. More optional settings are in the Variables tab; add them in the app settings.
