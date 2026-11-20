---
name: Cal.diy
site: https://cal.diy
source: https://github.com/calcom/cal.diy
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Mail Viewer, path: /mail/, icon: mail }
screenshots: [Booking an event]
variables:
  - name: EMAIL_SERVER_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com. Leave it out to send every
      email to the built-in mail viewer at /mail instead.
  - name: EMAIL_SERVER_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port. 465 uses TLS from the start.
  - name: EMAIL_SERVER_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: EMAIL_SERVER_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server (for Gmail, an app password).
  - name: EMAIL_FROM
    group: Email (SMTP)
    default: notifications@cal.local
    description: >-
      The sender address on booking emails.
  - name: EMAIL_FROM_NAME
    group: Email (SMTP)
    default: Cal.diy
    description: >-
      The sender name on booking emails.
  - name: RESEND_API_KEY
    group: Email (SMTP)
    default: ""
    description: >-
      Send emails with Resend instead of SMTP. Paste your Resend API key.
  - name: GOOGLE_API_CREDENTIALS
    group: Calendars and video
    default: ""
    description: >-
      The JSON of your Google Cloud OAuth client, for Google Calendar and
      Meet. Add PUBLIC_URL/api/integrations/googlecalendar/callback as a
      redirect URI in Google Cloud.
  - name: GOOGLE_LOGIN_ENABLED
    group: Calendars and video
    default: "false"
    description: >-
      Set to true (with GOOGLE_API_CREDENTIALS) to show "Sign in with Google".
  - name: MS_GRAPH_CLIENT_ID
    group: Calendars and video
    default: ""
    description: >-
      The client ID of your Microsoft Entra app, for Outlook and Office 365
      calendars.
  - name: MS_GRAPH_CLIENT_SECRET
    group: Calendars and video
    default: ""
    description: >-
      The client secret of that Microsoft app.
  - name: OUTLOOK_LOGIN_ENABLED
    group: Calendars and video
    default: "false"
    description: >-
      Set to true (with the Microsoft app) to show "Sign in with Outlook".
  - name: ZOOM_CLIENT_ID
    group: Calendars and video
    default: ""
    description: >-
      The client ID of your Zoom app, for Zoom links in bookings.
  - name: ZOOM_CLIENT_SECRET
    group: Calendars and video
    default: ""
    description: >-
      The client secret of that Zoom app.
  - name: DAILY_API_KEY
    group: Calendars and video
    default: ""
    description: >-
      Your Daily.co API key, for Cal Video meeting rooms.
  - name: DAILY_SCALE_PLAN
    group: Calendars and video
    default: ""
    description: >-
      Set to true if your Daily.co account is on the Scale plan.
  - name: BLACKLISTED_GUEST_EMAILS
    group: Bookings
    default: ""
    description: >-
      Email addresses that may not book, separated by commas.
  - name: ALLOWED_HOSTNAMES
    group: Server
    default: ""
    description: >-
      Host names Cal.diy accepts for organization subdomains, written as
      "cal.example.com". Most people leave it out.
  - name: NEXTAUTH_COOKIE_DOMAIN
    group: Server
    default: ""
    description: >-
      Share the sign-in cookie across subdomains, like .example.com. Most
      people leave it out.
  - name: CALCOM_TELEMETRY_DISABLED
    group: Server
    default: "1"
    description: >-
      Set to 0 to send anonymous usage numbers to Cal.com.
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

# Cal.diy

Cal.diy is the open-source, self-hosted edition of Cal.com. Share a link, and people pick a free time in your calendar without the back and forth. PostgreSQL and a mail viewer are built in, so it is one container.

## Features

- Booking pages with your event types: length, buffers, limits and questions
- Checks your Google, Outlook or CalDAV calendars so you are never double-booked
- Availability schedules, time zones and date overrides
- Teams with round-robin and collective events
- Workflows that send reminders, webhooks and an embed for your website
- A built-in mail viewer at `/mail` shows every email while no email server is set

## How to use

1. Set `PUBLIC_URL` to `http://[ZIMAOS-IP-ADDRESS]:6749` with your ZimaOS IP before you install.
2. Open Cal.diy. The setup page makes your admin account.
3. Connect a calendar under Settings, Calendars, and set your working hours under Availability.
4. Make an event type, like a 30 minute call.
5. Copy its link and send it to people. Their bookings show up under Bookings.

Left out: the separate API v2 service, Redis and Prisma Studio. Only for amd64 (upstream's ARM image is a separate build).

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6749`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6749`. Until you do, other devices see a page that tells them to. Behind a domain, use that address instead (`https://cal.example.com`).

The first start takes about 5 minutes. Then open your `PUBLIC_URL`: the setup page makes the admin account. Emails go to the mail viewer at `http://[ZIMAOS-IP-ADDRESS]:6749/mail/` until you set an email server; its login is in the app's logs in the box marked CREDENTIALS. More settings (email server, Google, Outlook and Zoom) are in the Variables tab; add them in the app settings.
