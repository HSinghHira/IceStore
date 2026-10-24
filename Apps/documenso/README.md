---
site: https://documenso.com
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Mail Viewer, path: /mail/, icon: mail }
screenshots: [Documents, Editor]
variables:
  - name: NEXT_PRIVATE_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Leave it out to keep emails in
      the built-in mail viewer at /mail.
  - name: NEXT_PRIVATE_SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port. Usually 587, or 465 with
      NEXT_PRIVATE_SMTP_SECURE set to true.
  - name: NEXT_PRIVATE_SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server. Leave it out if it needs none.
  - name: NEXT_PRIVATE_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: NEXT_PRIVATE_SMTP_SECURE
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for a server on port 465 that uses TLS from the start.
  - name: NEXT_PRIVATE_SMTP_UNSAFE_IGNORE_TLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to never use TLS, even when the server offers it. Only for
      a mail server on your own network.
  - name: NEXT_PRIVATE_SMTP_FROM_NAME
    group: Email (SMTP)
    default: Documenso
    description: >-
      The sender name on emails Documenso sends.
  - name: NEXT_PRIVATE_SMTP_FROM_ADDRESS
    group: Email (SMTP)
    default: noreply@documenso.local
    description: >-
      The sender address on emails. Most mail servers need this to be an
      address they own.
  - name: NEXT_PRIVATE_SMTP_TRANSPORT
    group: Email (SMTP)
    default: smtp-auth
    description: >-
      How emails are sent: smtp-auth, smtp-api, resend or mailchannels.
      Leave it out for a normal mail server.
  - name: NEXT_PRIVATE_RESEND_API_KEY
    group: Email (SMTP)
    default: ""
    description: >-
      Your Resend API key, when NEXT_PRIVATE_SMTP_TRANSPORT is resend.
  - name: MP_UI_AUTH
    group: Email (SMTP)
    default: ""
    description: >-
      Your own login for the mail viewer, as user:password. Leave it out to
      use the one made on first start (shown in the app logs).
  - name: NEXT_PUBLIC_DISABLE_SIGNUP
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so nobody new can sign up, by any method. Do this after
      you have made your own account.
  - name: NEXT_PUBLIC_DISABLE_EMAIL_PASSWORD_SIGNUP
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to stop sign-up with email and password, but still allow
      sign-up with Google, Microsoft or OIDC.
  - name: NEXT_PRIVATE_ALLOWED_SIGNUP_DOMAINS
    group: Sign-up and accounts
    default: ""
    description: >-
      Only let emails from these domains sign up, comma separated, like
      example.com,acme.org.
  - name: NEXT_PUBLIC_DISABLE_EMAIL_PASSWORD_SIGNIN
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to turn off email and password sign-in, so everyone signs
      in with Google, Microsoft or OIDC.
  - name: NEXT_PRIVATE_GOOGLE_CLIENT_ID
    group: Sign in with Google
    default: ""
    description: >-
      Client ID of a Google OAuth app. The redirect URL to add in Google is
      PUBLIC_URL followed by /api/auth/callback/google.
  - name: NEXT_PRIVATE_GOOGLE_CLIENT_SECRET
    group: Sign in with Google
    default: ""
    description: >-
      Client secret of the same Google OAuth app.
  - name: NEXT_PUBLIC_DISABLE_GOOGLE_SIGNUP
    group: Sign in with Google
    default: "false"
    description: >-
      Set to true so Google can only sign in people who already have an
      account.
  - name: NEXT_PUBLIC_DISABLE_GOOGLE_SIGNIN
    group: Sign in with Google
    default: "false"
    description: >-
      Set to true to hide the Google button.
  - name: NEXT_PRIVATE_MICROSOFT_CLIENT_ID
    group: Sign in with Microsoft
    default: ""
    description: >-
      Application (client) ID of a Microsoft Entra app. The redirect URL to
      add is PUBLIC_URL followed by /api/auth/callback/microsoft.
  - name: NEXT_PRIVATE_MICROSOFT_CLIENT_SECRET
    group: Sign in with Microsoft
    default: ""
    description: >-
      Client secret of the same Microsoft app.
  - name: NEXT_PUBLIC_DISABLE_MICROSOFT_SIGNUP
    group: Sign in with Microsoft
    default: "false"
    description: >-
      Set to true so Microsoft can only sign in people who already have an
      account.
  - name: NEXT_PUBLIC_DISABLE_MICROSOFT_SIGNIN
    group: Sign in with Microsoft
    default: "false"
    description: >-
      Set to true to hide the Microsoft button.
  - name: NEXT_PRIVATE_OIDC_WELL_KNOWN
    group: Sign in with OIDC
    default: ""
    description: >-
      The discovery URL of your provider (Pocket ID, authentik, Keycloak),
      like https://auth.example.com/.well-known/openid-configuration. The
      redirect URL to add there is PUBLIC_URL followed by
      /api/auth/callback/oidc.
  - name: NEXT_PRIVATE_OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      Client ID from your OIDC provider.
  - name: NEXT_PRIVATE_OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      Client secret from your OIDC provider.
  - name: NEXT_PRIVATE_OIDC_PROVIDER_LABEL
    group: Sign in with OIDC
    default: OIDC
    description: >-
      The name on the sign-in button, like Pocket ID.
  - name: NEXT_PRIVATE_OIDC_SKIP_VERIFY
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to accept accounts whose email the provider has not
      verified. Without it, those sign-ins fail with UNVERIFIED_EMAIL.
  - name: NEXT_PRIVATE_OIDC_PROMPT
    group: Sign in with OIDC
    default: login
    description: >-
      The prompt sent to the provider. login asks for the password each
      time; set to none to skip it when already signed in there.
  - name: NEXT_PUBLIC_DISABLE_OIDC_SIGNUP
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true so OIDC can only sign in people who already have an
      account.
  - name: NEXT_PUBLIC_DISABLE_OIDC_SIGNIN
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to hide the OIDC button.
  - name: NEXT_PUBLIC_DISABLE_OIDC_AUTO_REDIRECT
    group: Sign in with OIDC
    default: "false"
    description: >-
      When OIDC is the only way to sign in, the sign-in page jumps straight
      to your provider. Set to true to show the sign-in page instead.
  - name: NEXT_PRIVATE_SIGNING_PASSPHRASE
    group: Signing
    default: ""
    description: >-
      Only if you put your own certificate in the data folder as
      cert/cert.p12: its passphrase. Leave it out to use the certificate
      made on first start.
  - name: NEXT_PRIVATE_SIGNING_REASON
    group: Signing
    default: Signed by Documenso
    description: >-
      The reason written into each signature.
  - name: NEXT_PUBLIC_SIGNING_CONTACT_INFO
    group: Signing
    default: ""
    description: >-
      The contact info written into each signature. Leave it out to use
      PUBLIC_URL.
  - name: NEXT_PRIVATE_SIGNING_TIMESTAMP_AUTHORITY
    group: Signing
    default: ""
    description: >-
      Timestamp server URLs, comma separated, like
      http://timestamp.digicert.com. Adds a trusted time to each signature.
  - name: NEXT_PUBLIC_UPLOAD_TRANSPORT
    group: File storage
    default: database
    description: >-
      Where uploaded PDFs are kept: database (inside the data folder) or s3.
  - name: NEXT_PRIVATE_UPLOAD_ENDPOINT
    group: File storage
    default: ""
    description: >-
      The S3 server URL, for S3-compatible storage like MinIO or Garage.
  - name: NEXT_PRIVATE_UPLOAD_REGION
    group: File storage
    default: us-east-1
    description: >-
      The S3 region.
  - name: NEXT_PRIVATE_UPLOAD_BUCKET
    group: File storage
    default: ""
    description: >-
      The S3 bucket name. Needed when NEXT_PUBLIC_UPLOAD_TRANSPORT is s3.
  - name: NEXT_PRIVATE_UPLOAD_ACCESS_KEY_ID
    group: File storage
    default: ""
    description: >-
      The S3 access key.
  - name: NEXT_PRIVATE_UPLOAD_SECRET_ACCESS_KEY
    group: File storage
    default: ""
    description: >-
      The S3 secret key.
  - name: NEXT_PRIVATE_UPLOAD_FORCE_PATH_STYLE
    group: File storage
    default: "false"
    description: >-
      Set to true for most self-hosted S3 servers (MinIO, Garage).
  - name: NEXT_PUBLIC_DOCUMENT_SIZE_UPLOAD_LIMIT
    group: File storage
    default: "5"
    description: >-
      The largest PDF people can upload, in MB.
  - name: NEXT_PRIVATE_DOCUMENT_CONVERSION_URL
    group: Features
    default: ""
    description: >-
      The URL of a Gotenberg server, like http://192.168.1.20:3000, to accept
      Word (DOCX) files. Leave it out to accept PDF only.
  - name: NEXT_PRIVATE_WEBHOOK_SSRF_BYPASS_HOSTS
    group: Features
    default: ""
    description: >-
      Host names or IPs on your own network that webhooks may call, comma
      separated, like 192.168.1.5.
  - name: GOOGLE_VERTEX_API_KEY
    group: AI
    default: ""
    description: >-
      A Google Vertex AI (Gemini) API key, to turn on the AI features, like
      finding the fields in a document for you.
  - name: GOOGLE_VERTEX_PROJECT_ID
    group: AI
    default: ""
    description: >-
      Your Google Cloud project ID for Vertex AI.
  - name: GOOGLE_VERTEX_LOCATION
    group: AI
    default: global
    description: >-
      The Google Cloud region for Vertex AI.
  - name: NEXT_PUBLIC_TURNSTILE_SITE_KEY
    group: Security
    default: ""
    description: >-
      A Cloudflare Turnstile site key, to show a bot check on sign-up and
      sign-in. Needs NEXT_PRIVATE_TURNSTILE_SECRET_KEY too.
  - name: NEXT_PRIVATE_TURNSTILE_SECRET_KEY
    group: Security
    default: ""
    description: >-
      The Cloudflare Turnstile secret key.
  - name: DOCUMENSO_DISABLE_TELEMETRY
    group: Privacy
    default: "false"
    description: >-
      Set to true to stop sending Documenso the app version and an
      anonymous install ID.
  - name: NEXT_PRIVATE_DOCUMENSO_LICENSE_KEY
    group: Privacy
    default: ""
    description: >-
      A Documenso license key, if you bought one, to turn on enterprise
      features.
---

# Documenso

Documenso is an open source document-signing platform - like DocuSign, but self-hosted and fully auditable. This is Documenso in a single container, with PostgreSQL and a mail viewer inside, one port and one data folder. Secret keys, the database password and a signing certificate are made for you on first start.

## Features

- Upload PDFs, place signature and text fields, and send documents out for signature
- Documents are signed with a certificate, so changes after signing can be detected
- Many recipients, signing order and email reminders
- Sign in with Google, Microsoft or any OIDC provider (Pocket ID, authentik, Keycloak)
- Templates, teams, webhooks and an open API
- Works without an email server: emails go to the built-in mail viewer at `/mail` until you set up SMTP

## How to use

1. Open Documenso from your dashboard and sign up.
2. Open `http://your-zimaos-ip:6142/mail/` to find the confirm email. The login for the mail viewer is in the app logs.
3. Click the link in the email, then sign in.
4. Upload a PDF, add the people who need to sign, and drag the fields onto the page.
5. Send it. Signers get an email and sign in their browser, with no account needed.
6. To send real emails, add the SMTP settings from the Variables tab.

## Before you install

Change `localhost` in `PUBLIC_URL` to your ZimaOS IP, like `http://192.168.1.20:6142`, so links in emails work on other devices. Put the email you will sign up with in `DOCUMENSO_ADMIN_EMAIL`, and that account becomes the admin as soon as it is created. Until you add an SMTP server, emails (like the sign-up confirm email) go to the mail viewer at `/mail/`; its login is in the app logs on the line that says "mail viewer (/mail) login is", and in `mail-password.txt` in the data folder. A self-signed signing certificate is made in `cert/cert.p12` in the data folder; to use your own, replace that file and set `NEXT_PRIVATE_SIGNING_PASSPHRASE`. The first start takes about three minutes. SMTP, sign-up rules, Google, Microsoft and OIDC sign-in and the other settings are in the Variables tab; add them in the app settings.
