---
name: OpenSignup
source: https://github.com/richshaw/OpenSignup
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Mail Viewer, path: /mail/, icon: mail }
screenshots: [New signup, Share panel, What people see]
variables:
  - name: NEXT_PUBLIC_INSTANCE_NAME
    group: Site
    default: OpenSignup
    description: >-
      The site's name, shown in the header, the footer and the legal pages.
  - name: NEXT_PUBLIC_SUPPORT_EMAIL
    group: Site
    default: support@opensignup.local
    description: >-
      The contact email shown in the footer and the privacy policy. Set it to
      an address people can write to.
  - name: NEXT_PUBLIC_GOVERNING_LAW
    group: Site
    default: ""
    description: >-
      The governing law in the terms of service, like England and Wales or
      the State of Oregon. Left out, the terms name the laws of the place
      where the operator of the site lives.
  - name: NEXT_PUBLIC_OPERATOR_NAME
    group: Site
    default: ""
    description: >-
      The person or group running this site, named in the privacy policy and
      terms. Leave it out to say "the operator of this instance".
  - name: AUTH_MAGIC_LINK_MAX_AGE_MINUTES
    group: Sign-in
    default: "60"
    description: >-
      How long a sign-in link works, in minutes (1 to 10080).
  - name: GOOGLE_CLIENT_ID
    group: Sign in with Google
    default: ""
    description: >-
      The client ID of a Google OAuth client, to let organizers sign in with
      Google. Its redirect URI is your PUBLIC_URL plus
      /api/auth/callback/google.
  - name: GOOGLE_CLIENT_SECRET
    group: Sign in with Google
    default: ""
    description: >-
      The client secret of that Google OAuth client. Set both or neither.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for sign-in links and reminders. Leave it out to keep
      every email in the mail viewer at /mail.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port.
  - name: SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server. Set both this and SMTP_PASSWORD, or
      neither.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: SMTP_SECURE
    group: Email (SMTP)
    default: ""
    description: >-
      Leave it out to pick from the port (TLS from the start on 465,
      STARTTLS otherwise). Set true or false to choose yourself.
  - name: SMTP_REQUIRE_TLS
    group: Email (SMTP)
    default: ""
    description: >-
      Set to false only for a mail server on your own network that takes a
      login but has no STARTTLS.
  - name: EMAIL_FROM
    group: Email (SMTP)
    default: OpenSignup <noreply@opensignup.local>
    description: >-
      The sender of every email, like Bake Sale <signups@example.com>.
  - name: EMAIL_TRANSPORT
    group: Email (SMTP)
    default: ""
    description: >-
      How email is sent: smtp, resend or console. Leave it out to use smtp
      when SMTP_HOST is set, Resend when RESEND_API_KEY is set, and the mail
      viewer otherwise.
  - name: RESEND_API_KEY
    group: Email (SMTP)
    default: ""
    description: >-
      A Resend API key, to send email with Resend instead of SMTP.
  - name: MP_UI_AUTH
    group: Email (SMTP)
    default: ""
    description: >-
      The mail viewer's login as user:password. Leave it out to use admin and
      the password in the CREDENTIALS box.
  - name: LLM_BASE_URL
    group: AI
    default: ""
    description: >-
      An OpenAI-compatible API address for Magic Compose (AI drafts), like
      https://openrouter.ai/api/v1 or http://[ZIMAOS-IP-ADDRESS]:11434/v1 for
      Ollama. Set it with LLM_MODEL.
  - name: LLM_MODEL
    group: AI
    default: ""
    description: >-
      The model for Magic Compose, like openai/gpt-4o-mini or llama3.1:8b.
  - name: LLM_API_KEY
    group: AI
    default: ""
    description: >-
      The API key for that address. Not needed for Ollama.
  - name: LLM_TIMEOUT_MS
    group: AI
    default: "180000"
    description: >-
      How long to wait for an AI draft, in milliseconds.
  - name: OAUTH_STATIC_CLIENTS
    group: AI
    default: ""
    description: >-
      Pre-registered AI assistant clients, as a JSON list of client_id,
      client_name and redirect_uris. Most assistants don't need this.
---

# OpenSignup

OpenSignup is an ad-free, open-source sign-up sheet for school parents, coaches and community groups: snack rotations, volunteer shifts, potlucks and carpools. Participants sign up from a link, with no account. Built here from upstream's source, with PostgreSQL, the reminder email worker and a mail viewer inside one container.

## Features

- Signups with slots, groups, dates, times and a limit of people per slot
- Participants sign up, change or cancel from a link, no account needed
- Reminder emails, and an email when a slot moves to a new time
- Share panel with a ready message, email link and QR code
- Responses tab with CSV export, and taking someone off a slot
- Workspaces with owners, editors and viewers
- Optional AI drafts (Magic Compose) and an MCP connector for AI assistants

## How to use

1. Set `PUBLIC_URL` to your ZimaOS IP in the app settings.
2. Open OpenSignup and sign in with your email address.
3. Open the sign-in link from the mail viewer at `http://[ZIMAOS-IP-ADDRESS]:6727/mail/` (its login is in the app's logs).
4. Make a signup, publish it and share its link.

## Before you install

**Set `PUBLIC_URL` to `http://[ZIMAOS-IP-ADDRESS]:6727` with your ZimaOS IP, like `http://192.168.1.20:6727`.** Sign-in links, share links and the links in emails all use it. Until you do, other devices get a page saying what to set.

Organizers sign in with an emailed link (or Google, if you set it up). Until you add `SMTP_HOST` and the other email settings, every email, sign-in links and participants' reminders included, lands in the built-in mail viewer at `/mail/`. Its login is in the app's logs, in the box marked CREDENTIALS, on every start. Participants only get their reminders once real email is set up.

Upstream bakes the site name, support email and legal text into its build; here they are app settings (`NEXT_PUBLIC_INSTANCE_NAME`, `NEXT_PUBLIC_SUPPORT_EMAIL`, `NEXT_PUBLIC_GOVERNING_LAW`, `NEXT_PUBLIC_OPERATOR_NAME`) that are filled in on every start. Set them before people outside your home use the site. To use it from outside your home, put it behind HTTPS with your own domain (a reverse proxy or tunnel to port 6727) and set `PUBLIC_URL` to that address, like `https://signup.example.com`. Connecting an AI assistant over MCP needs HTTPS too.

The first start takes about two minutes (the database and its tables). More settings are in the Variables tab.
