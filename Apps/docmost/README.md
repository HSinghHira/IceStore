---
site: https://docmost.com
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Mail Viewer, path: /mail/, icon: mail }
variables:
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Leave it out to keep emails in
      the built-in mail viewer at /mail.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port. Usually 587, or 465 with SMTP_SECURE set to
      true.
  - name: SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server. Leave it out if it needs none.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: SMTP_SECURE
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for a server on port 465 that uses TLS from the start.
  - name: SMTP_IGNORETLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to never use TLS, even when the server offers it. Only for
      a mail server on your own network.
  - name: MAIL_FROM_ADDRESS
    group: Email (SMTP)
    default: noreply@docmost.local
    description: >-
      The sender address on emails. Most mail servers need this to be an
      address they own.
  - name: MAIL_FROM_NAME
    group: Email (SMTP)
    default: Docmost
    description: >-
      The sender name on emails Docmost sends.
  - name: MAIL_DRIVER
    group: Email (SMTP)
    default: smtp
    description: >-
      How emails are sent: smtp or postmark.
  - name: POSTMARK_TOKEN
    group: Email (SMTP)
    default: ""
    description: >-
      Your Postmark server token, when MAIL_DRIVER is postmark.
  - name: MP_UI_AUTH
    group: Email (SMTP)
    default: ""
    description: >-
      Your own login for the mail viewer, as user:password. Leave it out to
      use the one made on first start (shown in the app logs).
  - name: JWT_TOKEN_EXPIRES_IN
    group: Sign-up and accounts
    default: 30d
    description: >-
      How long people stay signed in, like 7d or 90d.
  - name: STORAGE_DRIVER
    group: File storage
    default: local
    description: >-
      Where uploads are kept: local (the data folder), s3 or azure.
  - name: AWS_S3_ENDPOINT
    group: File storage
    default: ""
    description: >-
      The S3 server URL, for S3-compatible storage like MinIO or Garage.
      Leave it out for Amazon S3.
  - name: AWS_S3_REGION
    group: File storage
    default: ""
    description: >-
      The S3 region, like us-east-1.
  - name: AWS_S3_BUCKET
    group: File storage
    default: ""
    description: >-
      The S3 bucket name. Needed when STORAGE_DRIVER is s3.
  - name: AWS_S3_ACCESS_KEY_ID
    group: File storage
    default: ""
    description: >-
      The S3 access key.
  - name: AWS_S3_SECRET_ACCESS_KEY
    group: File storage
    default: ""
    description: >-
      The S3 secret key.
  - name: AWS_S3_FORCE_PATH_STYLE
    group: File storage
    default: "false"
    description: >-
      Set to true for most self-hosted S3 servers (MinIO, Garage).
  - name: AZURE_STORAGE_ACCOUNT_NAME
    group: File storage
    default: ""
    description: >-
      The Azure Storage account name, when STORAGE_DRIVER is azure.
  - name: AZURE_STORAGE_ACCOUNT_KEY
    group: File storage
    default: ""
    description: >-
      The Azure Storage account key.
  - name: AZURE_STORAGE_CONTAINER
    group: File storage
    default: ""
    description: >-
      The Azure blob container name.
  - name: FILE_UPLOAD_SIZE_LIMIT
    group: File storage
    default: 50mb
    description: >-
      The largest file people can upload, like 100mb.
  - name: FILE_IMPORT_SIZE_LIMIT
    group: File storage
    default: 200mb
    description: >-
      The largest file people can import, like a Notion export.
  - name: DRAWIO_URL
    group: Features
    default: https://embed.diagrams.net
    description: >-
      Your own draw.io server, to keep diagrams on your network.
  - name: GOTENBERG_URL
    group: Features
    default: ""
    description: >-
      The URL of a Gotenberg server, like http://192.168.1.20:3000, for PDF
      export on the server.
  - name: IFRAME_EMBED_ALLOWED
    group: Features
    default: "false"
    description: >-
      Set to true to let other sites show Docmost pages in an iframe.
  - name: IFRAME_ALLOWED_ORIGINS
    group: Features
    default: ""
    description: >-
      The sites allowed to embed Docmost, comma separated, like
      https://intranet.example.com. Leave it out to allow any site.
  - name: ALLOWED_PRIVATE_NETWORKS
    group: Security
    default: none
    description: >-
      Which private network addresses Docmost may call (for embeds and link
      previews): none, all, or ranges like 192.168.1.0/24.
  - name: DISABLE_TELEMETRY
    group: Privacy
    default: "false"
    description: >-
      Set to true to stop sending Docmost anonymous usage data.
  - name: DEBUG_MODE
    group: Logs
    default: "false"
    description: >-
      Set to true for more detailed logs.
  - name: LOG_HTTP
    group: Logs
    default: "false"
    description: >-
      Set to true to log every web request.
---

# Docmost

Docmost is an open source alternative to Notion and Confluence: real-time collaborative docs and a team wiki in one app. This is Docmost in a single container, with PostgreSQL, Redis and a mail viewer inside, one port and one data folder. The secret key and database passwords are made for you on first start.

## Features

- Real-time collaborative editing with a rich block editor
- Spaces, nested pages, permissions and page history
- Diagrams with draw.io, Excalidraw and Mermaid
- Comments, search, and import from Markdown, HTML and Notion
- Works without an email server: invite and password-reset emails go to the built-in mail viewer at `/mail` until you set up SMTP

## How to use

1. Open Docmost from your dashboard.
2. Make your admin account and workspace on the first screen.
3. Create a space and start writing pages.
4. Invite people from Settings, Members. Until you set up SMTP, the invite emails are in the mail viewer at `http://your-zimaos-ip:6147/mail/`. Its login is in the app logs.
5. To send real emails, add the SMTP settings from the Variables tab.

## Before you install

`PUBLIC_URL` starts as `http://localhost:6147`. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6147`, so links in emails and shared pages work from other devices. The first start takes about three minutes. Until you add an SMTP server, emails go to the mail viewer at `/mail/`; its login is in the app logs on the line that says "mail viewer (/mail) login is", and in `mail-password.txt` in the data folder. SMTP, S3 storage and the other settings are in the Variables tab; add them in the app settings.
