---
site: https://www.docuseal.com
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: SMTP_ADDRESS
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Add it only with a value: an
      empty SMTP_ADDRESS still turns SMTP on. You can also set email up in
      the app under Settings, Email.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port. Usually 587, or 465 with SMTP_ENABLE_SSL set
      to true.
  - name: SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address on emails, like docuseal@example.com. Needed when
      SMTP_ADDRESS is set.
  - name: SMTP_DOMAIN
    group: Email (SMTP)
    default: ""
    description: >-
      The domain DocuSeal says hello as to the mail server. Most servers do
      not need it.
  - name: SMTP_AUTHENTICATION
    group: Email (SMTP)
    default: plain
    description: >-
      How DocuSeal logs in to the mail server: plain, login or cram_md5.
  - name: SMTP_ENABLE_STARTTLS
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false to stop DocuSeal upgrading the connection to TLS.
  - name: SMTP_ENABLE_SSL
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for a mail server on port 465 that uses TLS from the start.
  - name: SMTP_SSL_VERIFY
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false to accept a mail server with a self-signed certificate.
  - name: APP_URL
    group: Server
    default: ""
    description: >-
      The address you open DocuSeal at, like https://sign.example.com. Leave
      it out to set it in the app under Settings, Account.
  - name: FORCE_SSL
    group: Server
    default: ""
    description: >-
      Set to true when DocuSeal is behind an HTTPS reverse proxy, so links
      use https and cookies are secure. Leave it out for plain http.
  - name: SESSION_REMEMBER_DAYS
    group: Sign-up and accounts
    default: "730"
    description: >-
      How many days "remember me" keeps people signed in.
  - name: DATABASE_URL
    group: Database
    default: ""
    description: >-
      A Postgres or MySQL database, like
      postgresql://user:password@192.168.1.20:5432/docuseal. Leave it out to
      use the built-in SQLite database. Set it before the first start: data
      already in SQLite is not moved.
  - name: S3_ATTACHMENTS_BUCKET
    group: File storage
    default: ""
    description: >-
      An S3 bucket for documents instead of the data folder. Needs the AWS
      settings below.
  - name: AWS_ACCESS_KEY_ID
    group: File storage
    default: ""
    description: >-
      The S3 access key.
  - name: AWS_SECRET_ACCESS_KEY
    group: File storage
    default: ""
    description: >-
      The S3 secret key.
  - name: AWS_REGION
    group: File storage
    default: us-east-1
    description: >-
      The S3 region.
  - name: S3_ENDPOINT
    group: File storage
    default: ""
    description: >-
      The S3 server URL, for S3-compatible storage like MinIO or Garage.
  - name: TIMESERVER_URL
    group: Signing
    default: ""
    description: >-
      A timestamp server URL, like http://timestamp.digicert.com, to add a
      trusted time to each signature.
---

# DocuSeal

DocuSeal is an open source platform for filling and signing digital documents. Build a fillable PDF form once, then send it out for one or more people to sign from any device.

## Features

- Drag-and-drop PDF form builder with 12+ field types (signature, date, file, checkbox and more)
- Many signers per document, with email notifications
- Automatic PDF eSignature and signature verification
- Built-in SQLite database, so there is no separate database to look after
- The secret key is made for you on first start and kept in the data folder

## How to use

1. Open DocuSeal from your dashboard.
2. Create your admin account on the first screen. Type the address you open DocuSeal at as the app URL.
3. Upload a PDF to make your first template, then place the fields on it.
4. Send the template to a signer, or share the signing link.
5. To send emails, add your SMTP server under Settings, Email in the app, or with the SMTP settings in the Variables tab.

## Before you install

There is nothing you must set. The first start takes about a minute. Open `http://your-zimaos-ip:6148` and make your admin account; for the app URL, type the address in your browser bar. The secret key is made on first start and kept in `docuseal/docuseal.env` in the data folder, so back that folder up. Email can be set up inside the app, or with the SMTP settings in the Variables tab. A Postgres database (`DATABASE_URL`) only takes effect on a fresh install. Add any of these settings in the app settings.
