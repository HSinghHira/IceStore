---
site: https://goauthentik.io
services:
  - { name: Sign-in and user dashboard, path: /, icon: globe }
  - { name: Admin interface, path: /if/admin/, icon: server }
screenshots: [authentik]
variables:
  - name: AUTHENTIK_EMAIL__HOST
    group: Email (SMTP)
    default: localhost
    description: >-
      Your mail server, for example smtp.gmail.com. authentik uses it for
      password resets, sign-up checks and alerts.
  - name: AUTHENTIK_EMAIL__PORT
    group: Email (SMTP)
    default: "25"
    description: >-
      The mail server port. Usually 587 with TLS or 465 with SSL.
  - name: AUTHENTIK_EMAIL__USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: AUTHENTIK_EMAIL__PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: AUTHENTIK_EMAIL__USE_TLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to use STARTTLS (port 587).
  - name: AUTHENTIK_EMAIL__USE_SSL
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to use SSL (port 465). Don't turn on both TLS and SSL.
  - name: AUTHENTIK_EMAIL__TIMEOUT
    group: Email (SMTP)
    default: "10"
    description: >-
      Seconds to wait for the mail server.
  - name: AUTHENTIK_EMAIL__FROM
    group: Email (SMTP)
    default: authentik@localhost
    description: >-
      The sender address, for example "authentik <auth@example.com>".
  - name: AUTHENTIK_BOOTSTRAP_TOKEN
    group: Admin account
    default: ""
    description: >-
      An API token for akadmin, for scripts and automation. Type any long
      random text. Only used on the first start.
  - name: AUTHENTIK_BOOTSTRAP_PASSWORD_HASH
    group: Admin account
    default: ""
    description: >-
      A pre-hashed akadmin password instead of ADMIN_PASSWORD. Only used on
      the first start. Leave ADMIN_PASSWORD blank when you use it.
  - name: AUTHENTIK_COOKIE_DOMAIN
    group: Server
    default: ""
    description: >-
      Share the sign-in cookie with subdomains, for example example.com.
      Needed for the proxy outpost in domain mode.
  - name: AUTHENTIK_SESSIONS__UNAUTHENTICATED_AGE
    group: Server
    default: days=1
    description: >-
      How long a visitor who has not signed in yet keeps their session.
  - name: AUTHENTIK_OUTPOSTS__DISABLE_EMBEDDED_OUTPOST
    group: Outposts
    default: "false"
    description: >-
      Set to true to turn off the built-in proxy outpost.
  - name: AUTHENTIK_OUTPOSTS__DISCOVER
    group: Outposts
    default: "true"
    description: >-
      Set to false so authentik doesn't look for Docker or Kubernetes to run
      outposts on.
  - name: AUTHENTIK_STORAGE__BACKEND
    group: File storage
    default: file
    description: >-
      Set to s3 to keep uploaded media in S3 instead of the data folder.
      Then also set the S3 settings below.
  - name: AUTHENTIK_STORAGE__S3__ENDPOINT
    group: File storage
    default: ""
    description: >-
      The S3 address, for example https://s3.us-east-1.amazonaws.com.
  - name: AUTHENTIK_STORAGE__S3__REGION
    group: File storage
    default: ""
    description: >-
      The S3 region, for example us-east-1.
  - name: AUTHENTIK_STORAGE__S3__BUCKET_NAME
    group: File storage
    default: ""
    description: >-
      The S3 bucket name.
  - name: AUTHENTIK_STORAGE__S3__ACCESS_KEY
    group: File storage
    default: ""
    description: >-
      The S3 access key.
  - name: AUTHENTIK_STORAGE__S3__SECRET_KEY
    group: File storage
    default: ""
    description: >-
      The S3 secret key.
  - name: AUTHENTIK_DISABLE_UPDATE_CHECK
    group: Privacy
    default: "false"
    description: >-
      Set to true so authentik doesn't check for new versions.
  - name: AUTHENTIK_DISABLE_STARTUP_ANALYTICS
    group: Privacy
    default: "false"
    description: >-
      Set to true so authentik doesn't send anonymous start-up statistics.
  - name: AUTHENTIK_ERROR_REPORTING__ENABLED
    group: Privacy
    default: "false"
    description: >-
      Set to true to send error reports to the authentik developers.
  - name: AUTHENTIK_WEB__WORKERS
    group: Performance
    default: "2"
    description: >-
      How many web server processes run. Raise it for many users.
  - name: AUTHENTIK_WORKER__THREADS
    group: Performance
    default: "2"
    description: >-
      How many background jobs run at once.
  - name: AUTHENTIK_LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much goes in the app log: debug, info, warning or error.
---

# authentik

authentik is an open-source identity provider and single sign-on platform. It lets your users sign in once and reach all your self-hosted apps, with full control over flows, policies and users. This is authentik in a single container, with one port and one data folder. Secret keys and the database password are made for you on first start.

## Features

- Single sign-on with OIDC, OAuth 2.0, SAML 2.0, LDAP and RADIUS
- Sign in with Google, GitHub, Discord and other social logins, or bring another OIDC or SAML provider
- Flows and stages for sign-in, sign-up, recovery and multi-factor login
- Policies to decide who can open which app
- The built-in proxy outpost protects apps that have no sign-in of their own
- PostgreSQL inside, with no extra cache service needed

## How to use

1. Open authentik from your dashboard.
2. Sign in as akadmin with the admin password.
3. Open the admin interface and create your users and groups.
4. Add an application and a provider (OIDC or SAML) for each app you want to protect.
5. Copy the provider details into the app you are connecting.

## Before you install

Set `ADMIN_EMAIL` to your own email. Leave `ADMIN_PASSWORD` blank to get a random password: after the first start, open the app log and find the line that says "the admin password is". Both are only used the first time; change them later inside authentik. The user name is `akadmin`. Open `http://your-zimaos-ip:6123` from other devices, and use that same address when you connect other apps. The first start takes about five minutes. Email (SMTP) and the other settings are in the Variables tab; add them in the app settings. To let authentik start its own outpost containers, add `/var/run/docker.sock` as a volume. That gives authentik full control of Docker on the device, so only add it if you need it.
