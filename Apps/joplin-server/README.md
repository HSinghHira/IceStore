---
site: https://joplinapp.org/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: Admin, path: /admin/users, icon: server }
screenshots: [Joplin apps that sync through the server]
variables:
  - name: SIGNUP_ENABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone make an account on the sign-in page.
  - name: MFA_ENABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let users turn on two-factor sign-in.
  - name: MFA_ENCRYPTION_KEY
    group: Sign-up and accounts
    default: ""
    description: >-
      The key two-factor secrets are stored with. Needed when MFA_ENABLED is
      true; make one with openssl rand -hex 32 and never change it.
  - name: COOKIES_SECURE
    group: Server
    default: "false"
    description: >-
      Set to true when people open Joplin Server over https.
  - name: INSTANCE_NAME
    group: Server
    default: ""
    description: >-
      A name shown in the page title and emails.
  - name: MAILER_ENABLED
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to send emails: invites and password resets.
  - name: MAILER_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: MAILER_PORT
    group: Email (SMTP)
    default: "465"
    description: >-
      Your email server port, usually 465 or 587.
  - name: MAILER_SECURITY
    group: Email (SMTP)
    default: tls
    description: >-
      tls for port 465, starttls for port 587, or none.
  - name: MAILER_AUTH_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: MAILER_AUTH_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: MAILER_NOREPLY_NAME
    group: Email (SMTP)
    default: ""
    description: >-
      The name emails are sent from.
  - name: MAILER_NOREPLY_EMAIL
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: LDAP_1_ENABLED
    group: Sign in with LDAP
    default: "false"
    description: >-
      Set to true to sign in with your LDAP server.
  - name: LDAP_1_HOST
    group: Sign in with LDAP
    default: ""
    description: >-
      Your LDAP server, like ldap://192.168.1.20.
  - name: LDAP_1_BASE_DN
    group: Sign in with LDAP
    default: ""
    description: >-
      Where users are found, like ou=users,dc=example,dc=com.
  - name: LDAP_1_BIND_DN
    group: Sign in with LDAP
    default: ""
    description: >-
      The account Joplin Server reads LDAP with.
  - name: LDAP_1_BIND_PW
    group: Sign in with LDAP
    default: ""
    description: >-
      That account's password.
  - name: LDAP_1_USER_AUTO_CREATION
    group: Sign in with LDAP
    default: "true"
    description: >-
      Set to false so only people who already have an account can sign in
      with LDAP.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much Joplin Server writes to the log: error, warn, info or debug.
---

# Joplin Server

Joplin Server keeps your Joplin notes in sync across your computer and phone, on your own server. It also lets you share notebooks with others and publish notes as web pages. PostgreSQL is built in, so it is one container with nothing else to set up.

## Features

- Fast sync for the Joplin desktop, phone and terminal apps
- Share notebooks with other users to work on them together
- Publish a note as a web page with a link
- Several users, each with their own notes
- End-to-end encryption still works on top

## How to use

1. Set `APP_BASE_URL` to your server's address before you install.
2. Open Joplin Server and sign in as admin@localhost with the password from the app's logs (the box marked CREDENTIALS).
3. In your profile, change the email and password.
4. In the Joplin app, open Settings, Synchronisation, pick Joplin Server and enter `http://[ZIMAOS-IP-ADDRESS]:6764` with your email and password.
5. Click Synchronise. Do the same on your phone.

## Before you install

**You must set `APP_BASE_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6764`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6764`. The first admin is admin@localhost with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/joplin-server/data/.admin_password`. Add more users under Admin, Users. Email, sign-up and LDAP are in the Variables tab and are added in the app settings. The handwriting recognition service is not included. The first start takes about 3 minutes.
