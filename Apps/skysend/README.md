---
site: https://skysend.app
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: FILE_MAX_SIZE
    group: Files
    default: "2GB"
    description: >-
      The biggest file someone can upload, like 500MB or 10GB.
  - name: FILE_MAX_FILES_PER_UPLOAD
    group: Files
    default: "200"
    description: >-
      The most files in one upload.
  - name: FILE_EXPIRE_OPTIONS_SEC
    group: Files
    default: "300,3600,86400,604800"
    description: >-
      The expiry times people can pick, in seconds, comma-separated (300 is 5
      minutes, 604800 is 7 days).
  - name: FILE_DEFAULT_EXPIRE_SEC
    group: Files
    default: "86400"
    description: >-
      The expiry time picked at first, in seconds. It must be one of
      FILE_EXPIRE_OPTIONS_SEC.
  - name: FILE_DOWNLOAD_OPTIONS
    group: Files
    default: "1,2,3,4,5,10,20,50,100"
    description: >-
      The download limits people can pick, comma-separated.
  - name: FILE_DEFAULT_DOWNLOAD
    group: Files
    default: "1"
    description: >-
      The download limit picked at first. It must be one of
      FILE_DOWNLOAD_OPTIONS.
  - name: FILE_UPLOAD_QUOTA_BYTES
    group: Files
    default: "0"
    description: >-
      How much one person may upload per time window, like 5GB. 0 means no
      limit.
  - name: FILE_UPLOAD_QUOTA_WINDOW
    group: Files
    default: "86400"
    description: >-
      The time window for FILE_UPLOAD_QUOTA_BYTES, in seconds.
  - name: FILE_UPLOAD_SPEED_LIMIT
    group: Files
    default: "0"
    description: >-
      The fastest one upload may go, like 10MB (per second). 0 means no limit.
  - name: FILE_UPLOAD_WS
    group: Files
    default: "true"
    description: >-
      Set to false if uploads fail because WebSockets are blocked, for example
      by a proxy.
  - name: NOTE_MAX_SIZE
    group: Notes
    default: "1MB"
    description: >-
      The biggest note someone can share.
  - name: NOTE_EXPIRE_OPTIONS_SEC
    group: Notes
    default: "300,3600,86400,604800"
    description: >-
      The expiry times people can pick for notes, in seconds, comma-separated.
  - name: NOTE_DEFAULT_EXPIRE_SEC
    group: Notes
    default: "86400"
    description: >-
      The note expiry time picked at first. It must be one of
      NOTE_EXPIRE_OPTIONS_SEC.
  - name: NOTE_VIEW_OPTIONS
    group: Notes
    default: "0,1,2,3,5,10,20,50,100"
    description: >-
      The view limits people can pick for notes, comma-separated. 0 means no
      limit.
  - name: NOTE_DEFAULT_VIEWS
    group: Notes
    default: "0"
    description: >-
      The view limit picked at first. 1 means burn after reading.
  - name: FILE_REQUEST_EXPIRE_OPTIONS_SEC
    group: File requests
    default: "86400,259200,604800"
    description: >-
      How long a file request can stay open, in seconds, comma-separated.
  - name: FILE_REQUEST_DEFAULT_EXPIRE_SEC
    group: File requests
    default: "259200"
    description: >-
      How long a file request stays open at first. It must be one of
      FILE_REQUEST_EXPIRE_OPTIONS_SEC.
  - name: FILE_REQUEST_UPLOAD_OPTIONS
    group: File requests
    default: "1,2,3,5,10,20,50,100"
    description: >-
      How many uploads a file request can take, comma-separated.
  - name: FILE_REQUEST_DEFAULT_UPLOADS
    group: File requests
    default: "10"
    description: >-
      How many uploads a file request takes at first.
  - name: FILE_REQUEST_MAX_SIZE
    group: File requests
    default: "2GB"
    description: >-
      The biggest file someone can upload into a request. It can't be more
      than FILE_MAX_SIZE.
  - name: FILE_REQUEST_RETENTION_SEC
    group: File requests
    default: "604800"
    description: >-
      How long an uploaded file stays in the inbox, in seconds.
  - name: FILE_REQUEST_DAILY_LIMIT
    group: File requests
    default: "0"
    description: >-
      How many new file requests one person can make per day. 0 means no
      limit.
  - name: ENABLED_SERVICES
    group: Features
    default: "file,note,request"
    description: >-
      Which parts are on: any of file, note and request, comma-separated.
  - name: DEFAULT_TAB
    group: Features
    default: "file"
    description: >-
      The tab shown first: file or note. text, password, code or sshkey open
      the note tab with that block added.
  - name: FORCE_FILE_PASSWORD
    group: Features
    default: "false"
    description: >-
      Set to true to require a password on every file upload.
  - name: FORCE_NOTE_PASSWORD
    group: Features
    default: "false"
    description: >-
      Set to true to require a password on every note.
  - name: FORCE_REQUEST_PASSWORD
    group: Features
    default: "false"
    description: >-
      Set to true to require a password on the inbox of every file request.
  - name: TRUST_PROXY
    group: Server
    default: "false"
    description: >-
      Set to true when SkySend is behind a reverse proxy, so it sees the
      visitor's real IP.
  - name: CORS_ORIGINS
    group: Server
    default: ""
    description: >-
      Other web addresses allowed to call this SkySend, comma-separated. Most
      people never need it.
  - name: RATE_LIMIT_MAX
    group: Server
    default: "60"
    description: >-
      The most requests one IP can make per minute.
  - name: PASSWORD_MAX_ATTEMPTS
    group: Server
    default: "10"
    description: >-
      Wrong password tries before an IP is locked out of a file or note.
  - name: PASSWORD_LOCKOUT_MS
    group: Server
    default: "900000"
    description: >-
      How long that lockout lasts, in milliseconds (900000 is 15 minutes).
  - name: CUSTOM_TITLE
    group: Branding
    default: "SkySend"
    description: >-
      The site name shown in the browser tab and the page.
  - name: CUSTOM_COLOR
    group: Branding
    default: "46c89d"
    description: >-
      The main color, as a 6-digit hex code.
  - name: CUSTOM_LOGO
    group: Branding
    default: ""
    description: >-
      Your own logo. Put the file in data/branding in the app's folder and
      type /branding/logo.svg.
  - name: DEFAULT_THEME
    group: Branding
    default: "graphite"
    description: >-
      The look of the site: graphite, aurora or midnight.
  - name: DEFAULT_COLOR_SCHEME
    group: Branding
    default: "system"
    description: >-
      Dark, light or system for new visitors.
  - name: CUSTOM_PRIVACY
    group: Branding
    default: ""
    description: >-
      A link to your privacy policy, shown at the bottom of the page.
  - name: CUSTOM_LEGAL
    group: Branding
    default: ""
    description: >-
      A link to your legal notice or impressum, shown at the bottom of the
      page.
  - name: CUSTOM_LINK_URL
    group: Branding
    default: ""
    description: >-
      A link of your own at the bottom of the page. Set CUSTOM_LINK_NAME too.
  - name: CUSTOM_LINK_NAME
    group: Branding
    default: ""
    description: >-
      The text of that link, up to 50 characters.
  - name: CUSTOM_REPORT_URL
    group: Branding
    default: ""
    description: >-
      A link to a page for reporting abuse, shown at the bottom of the page.
  - name: OIDC_PROVIDER
    group: Sign in with SSO (OIDC)
    default: "generic"
    description: >-
      Your sign-in provider: generic, pocketid, authentik or keycloak.
  - name: OIDC_ISSUER
    group: Sign in with SSO (OIDC)
    default: ""
    description: >-
      Your provider's issuer address. With OIDC_CLIENT_ID and
      OIDC_CLIENT_SECRET it turns SSO on. All three must be set together, or
      SkySend won't start.
  - name: OIDC_CLIENT_ID
    group: Sign in with SSO (OIDC)
    default: ""
    description: >-
      The client ID from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with SSO (OIDC)
    default: ""
    description: >-
      The client secret from your provider.
  - name: OIDC_SESSION_SECRET
    group: Sign in with SSO (OIDC)
    default: ""
    description: >-
      At least 32 random characters that keep people signed in after a
      restart. Without it everyone is signed out on each restart.
  - name: OIDC_PROTECT_FILES
    group: Sign in with SSO (OIDC)
    default: "true"
    description: >-
      Set to false to let people upload files without signing in.
  - name: OIDC_PROTECT_NOTES
    group: Sign in with SSO (OIDC)
    default: "true"
    description: >-
      Set to false to let people make notes without signing in.
  - name: OIDC_PROTECT_REQUESTS
    group: Sign in with SSO (OIDC)
    default: ""
    description: >-
      Set to false to let people make file requests without signing in. Left
      out, requests need sign-in while files or notes do.
  - name: OIDC_SCOPES
    group: Sign in with SSO (OIDC)
    default: "openid profile email"
    description: >-
      The scopes to ask for, separated by spaces.
  - name: OIDC_SESSION_DURATION
    group: Sign in with SSO (OIDC)
    default: "86400"
    description: >-
      How long a sign-in lasts, in seconds.
  - name: STORAGE_BACKEND
    group: S3 storage
    default: "filesystem"
    description: >-
      Set to s3 to keep uploads in S3-compatible storage instead of the
      uploads folder.
  - name: S3_BUCKET
    group: S3 storage
    default: ""
    description: >-
      The bucket name.
  - name: S3_REGION
    group: S3 storage
    default: ""
    description: >-
      The region, like eu-central-1.
  - name: S3_ENDPOINT
    group: S3 storage
    default: ""
    description: >-
      The S3 server address, for R2, MinIO, Garage and others. Leave it out
      for AWS.
  - name: S3_ACCESS_KEY
    group: S3 storage
    default: ""
    description: >-
      The access key.
  - name: S3_SECRET_KEY
    group: S3 storage
    default: ""
    description: >-
      The secret key.
  - name: S3_FORCE_PATH_STYLE
    group: S3 storage
    default: "false"
    description: >-
      Set to true for MinIO, Garage and some other self-hosted S3 servers.
  - name: PUID
    group: Server
    default: "1001"
    description: >-
      The user that owns the data and uploads folders.
  - name: PGID
    group: Server
    default: "1001"
    description: >-
      The group that owns the data and uploads folders.
---

# SkySend

SkySend is a minimalist, end-to-end encrypted file and note sharing service. Files and notes are encrypted in your browser before upload, so the server only stores encrypted data and never sees the key.

## Features

- Drag-and-drop file and folder uploads, with expiry times and download limits
- Encrypted notes made of blocks: text, passwords, code and SSH keys together, with optional burn-after-reading
- File requests: hand out a link and others upload files that only you can open
- Optional password protection with Argon2id
- Optional OIDC / SSO sign-in to limit who can upload, while downloads stay public
- Optional S3-compatible storage (AWS S3, R2, MinIO and more)
- No accounts and no telemetry

## How to use

1. Open SkySend from your dashboard.
2. Drag a file onto the page, or switch to the Note tab to share text, a password, code or an SSH key.
3. Pick an expiry time and a download or view limit, and add a password if you like.
4. Copy the share link and send it. The key to open it is only in the link, never on the server.
5. Open My Links to see what you shared from this browser.

## Before you install

Set `BASE_URL` to the address you open SkySend at, like `http://192.168.1.50:6159`; share links are built from it. The first start takes about half a minute. Everything else is optional and listed in the Variables tab: size limits, expiry choices, branding, S3 storage and SSO sign-in. Add them in the app settings, only with a value. For SSO, `OIDC_ISSUER`, `OIDC_CLIENT_ID` and `OIDC_CLIENT_SECRET` must be set together, and set `OIDC_SESSION_SECRET` too so people stay signed in after a restart.
