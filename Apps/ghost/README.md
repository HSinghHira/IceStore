---
featured: true
site: https://ghost.org
services:
  - { name: Site, path: /, icon: globe }
  - { name: Admin, path: /ghost/, icon: server }
  - { name: Mail Viewer, path: /mail/, icon: mail }
screenshots: [Admin dashboard]
variables:
  - name: mail__options__host
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.mailgun.org. Leave it out to send every
      email to the built-in mail viewer at /mail instead.
  - name: mail__options__port
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port.
  - name: mail__options__secure
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for port 465 (TLS from the start).
  - name: mail__options__auth__user
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: mail__options__auth__pass
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: mail__options__service
    group: Email (SMTP)
    default: ""
    description: >-
      A known provider name instead of a host, like Mailgun or SES.
  - name: mail__from
    group: Email (SMTP)
    default: "Ghost <noreply@ghost.local>"
    description: >-
      The sender on staff emails, like "My Blog <hello@example.com>".
  - name: admin__url
    group: Server
    default: ""
    description: >-
      A separate address for the admin, like https://admin.example.com.
      Leave it out to use PUBLIC_URL/ghost/.
  - name: security__staffDeviceVerification
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to stop emailing a code when staff sign in from a new
      device.
  - name: privacy__useUpdateCheck
    group: Server
    default: "true"
    description: >-
      Set to false to stop checking ghost.org for updates.
  - name: privacy__useGravatar
    group: Server
    default: "true"
    description: >-
      Set to false to stop loading profile pictures from Gravatar.
  - name: logging__level
    group: Logs
    default: info
    description: >-
      How much Ghost logs: error, warn, info or debug.
  - name: MP_UI_AUTH
    group: Mail viewer
    default: ""
    description: >-
      Your own login for the mail viewer at /mail, written as user:password.
      Leave it out for user admin and a password made on first start (shown
      in the CREDENTIALS box).
  - name: MP_MAX_MESSAGES
    group: Mail viewer
    default: "500"
    description: >-
      How many emails the mail viewer keeps.
---

# Ghost

Ghost is a publishing platform for blogs, magazines and newsletters. Write in a clean editor, send posts by email, and let readers sign up or pay for a membership. MySQL and a mail viewer are built in, so it is one container.

## Features

- A fast, distraction-free editor with cards for images, video, embeds and code
- Newsletters: every post can go out by email to your members
- Free and paid memberships with Stripe, plus tiers and offers
- Beautiful themes, custom pages, tags and authors
- Built-in SEO, sitemaps and social cards
- Staff users with roles, and an Admin and Content API

## How to use

1. Set `PUBLIC_URL` to `http://[ZIMAOS-IP-ADDRESS]:6752` with your ZimaOS IP (or your domain) before you install.
2. Open `http://[ZIMAOS-IP-ADDRESS]:6752/ghost/` and make the owner account.
3. Write your first post and press Publish.
4. Ghost emails a code when you sign in from a new device. Find it in the mail viewer at `/mail` until you set an email server.
5. Set your email server in the app settings before you send newsletters to real readers.

Left out: Caddy (https), ActivityPub (the social web) and Tinybird web analytics.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6752`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6752`. Until you do, other devices see a page that tells them to. For a public blog, point your domain (with https from a reverse proxy) at port 6752 and set `PUBLIC_URL=https://blog.example.com`.

The first start takes about 3 minutes. Then open your address with `/ghost/` at the end and make the owner account. Emails, including sign-in codes for new devices, go to the mail viewer at `http://[ZIMAOS-IP-ADDRESS]:6752/mail/` until you set an email server; its login is in the app's logs in the box marked CREDENTIALS. Newsletters to members need Mailgun, set up inside Ghost's settings. More settings are in the Variables tab; add them in the app settings.
