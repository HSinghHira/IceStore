---
site: https://github.com/hanzydev/Fileship
services:
  - { name: Dashboard, path: /, icon: globe }
screenshots: [Dashboard]
variables:
  - name: NUXT_PUBLIC_SITE_NAME
    group: Server
    default: Fileship
    description: >-
      The name shown in the browser title, embeds and the dashboard.
  - name: NUXT_PUBLIC_RETURN_HTTPS
    group: Server
    default: auto
    description: >-
      Set to true to always give https links for uploads, like when Fileship
      is behind an HTTPS proxy that doesn't say so.
  - name: NUXT_PUBLIC_REGISTRATION_ENABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone make an account from the sign-in page.
  - name: NUXT_REGISTRATION_PERMISSIONS
    group: Sign-up and accounts
    default: UploadFiles,TakeNotes,ShortenLinks
    description: >-
      What people who sign up themselves may do, separated by commas:
      UploadFiles, TakeNotes, ShortenLinks.
  - name: NUXT_REGISTRATION_USABLE_SPACE
    group: Sign-up and accounts
    default: "-1"
    description: >-
      Storage limit for people who sign up themselves, in MB. -1 means no
      limit.
  - name: NUXT_PUBLIC_TURNSTILE_SITE_KEY
    group: Sign-up and accounts
    default: ""
    description: >-
      Your Cloudflare Turnstile site key, to stop bots on the sign-in page.
  - name: NUXT_TURNSTILE_SECRET_KEY
    group: Sign-up and accounts
    default: ""
    description: >-
      Your Cloudflare Turnstile secret key.
  - name: NUXT_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.example.com. Email also needs
      NUXT_SMTP_FROM and PUBLIC_URL set to a real address.
  - name: NUXT_SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      The mail server's port. Usually 587 for starttls and 465 for tls.
  - name: NUXT_SMTP_SECURITY
    group: Email (SMTP)
    default: starttls
    description: >-
      starttls, tls or none.
  - name: NUXT_SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server user name. Leave it out if the server needs no
      sign-in.
  - name: NUXT_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server password.
  - name: NUXT_SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address on emails, like fileship@example.com.
  - name: NUXT_OIDC_ENABLED
    group: Single sign-on (OIDC)
    default: "false"
    description: >-
      Set to true to sign in with an OpenID Connect provider like Pocket ID,
      Authentik or Google. Needs PUBLIC_URL set to a real address. The
      redirect URI is your PUBLIC_URL plus /api/auth/oidc/callback.
  - name: NUXT_OIDC_ISSUER_URL
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      Your provider's issuer address, exactly as it publishes it, like
      https://id.example.com.
  - name: NUXT_OIDC_CLIENT_ID
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client ID from your provider.
  - name: NUXT_OIDC_CLIENT_SECRET
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client secret from your provider. Leave it out for a public
      client.
  - name: NUXT_OIDC_BUTTON_LABEL
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The provider name on the sign-in button, like Authentik.
  - name: NUXT_OIDC_AUTO_REGISTER
    group: Single sign-on (OIDC)
    default: "false"
    description: >-
      Set to true to make an account for people who sign in through the
      provider and don't have one yet.
  - name: NUXT_PASSWORD_LOGIN_ENABLED
    group: Single sign-on (OIDC)
    default: "true"
    description: >-
      Set to false so everyone signs in through the provider. Super admins
      can still use their password.
  - name: NUXT_PUBLIC_AI_ENABLED
    group: AI
    default: "true"
    description: >-
      Set to false to turn off AI search, captions and OCR.
  - name: NUXT_AI_PRESET
    group: AI
    default: low
    description: >-
      low, medium or high. Higher finds more but needs more memory: about
      4, 6 or 8 GB in all. Raise the app's memory limit for medium or high.
  - name: NUXT_AI_QUEUE_CONCURRENCY
    group: AI
    default: "1"
    description: >-
      How many uploads the AI looks at at the same time.
  - name: NUXT_AI_INFERENCE_THREADS
    group: AI
    default: "2"
    description: >-
      How many CPU threads each AI job uses.
  - name: NUXT_PUBLIC_FILE_CHUNK_SIZE
    group: Uploads
    default: "25"
    description: >-
      Size of each upload piece, in MB, at least 5.
  - name: NUXT_AVATAR_MAX_SIZE
    group: Uploads
    default: "4"
    description: >-
      The largest profile picture, in MB.
  - name: NUXT_REMOVE_EXIF_DATA
    group: Uploads
    default: "true"
    description: >-
      Set to false to keep photo details (EXIF, like location) in uploads.
  - name: NUXT_TRASH_RETENTION_DAYS
    group: Uploads
    default: "30"
    description: >-
      Days deleted things stay in the trash. 0 deletes them right away.
  - name: NUXT_SCHEDULED_BACKUPS_ENABLED
    group: Uploads
    default: "true"
    description: >-
      Set to false to stop automatic account backups for everyone.
  - name: NUXT_TELEMETRY_ENABLED
    group: Logs
    default: "true"
    description: >-
      Set to false to stop sending Fileship anonymous usage data.
  - name: NUXT_LOG_LEVEL
    group: Logs
    default: "2"
    description: >-
      0, 1 or 2. Higher logs more.
---

# Fileship

Fileship is a self-hosted file and media platform: a ShareX upload server, a file cloud with folders and notes, short links and AI search that runs on your own server. This is Fileship in a single container, with PostgreSQL inside, one port and one data folder. The database passwords and the admin password are made for you on first start.

## Features

- Files, nested shared folders, Markdown notes, short links and a trash
- Public sharing with passwords, expiry dates, view limits and rich embeds for Discord
- AI search, captions and OCR that run on your server (no GPU needed)
- Uploads on this server, or on S3, SFTP or FTP storage
- Many users with permissions, storage limits, passkeys, two-factor sign-in and single sign-on
- ShareX, browser extension, Windows app and phone app uploads

## How to use

1. Find the admin password in the app log, on the line that says "Fileship login is".
2. Open Fileship from your dashboard and sign in as `admin`.
3. Change the password in Settings, Security.
4. Drop files on the page to upload them, or set up ShareX from Settings.
5. Add other people in Administration, Users.

## Before you install

Fileship works from any device at `http://[ZIMAOS-IP-ADDRESS]:6131` with the defaults. `PUBLIC_URL` starts as `http://localhost:6131`; change it to `http://[ZIMAOS-IP-ADDRESS]:6131` with your ZimaOS IP, like `http://192.168.1.20:6131`, or your own domain, so links in emails and single sign-on work. Leave `ADMIN_PASSWORD` blank to get a random one: it is in the app log on the line that says "Fileship login is", and in `admin-password.txt` in the app folder. It replaces upstream's default admin / password login, and is only used until you change the password in Fileship. The first start takes about two minutes. Sign-up, email, single sign-on, AI and the other settings are in the Variables tab; add them in the app settings. Settings saved in Administration, Instance win over them.

The AI preset starts at `low` (about 4 GB of memory). The app's memory limit is 4 GB; raise it in the app settings before you pick `medium` or `high`. One-click updates from the dashboard are off, because upstream's updater needs the Docker socket; the IceStore image follows new Fileship versions every week.
