---
site: https://asm0dey.github.io/calit/
services:
  - { name: Dashboard, path: /me, icon: globe }
  - { name: First Setup, path: /setup, icon: plus-circle }
screenshots: [Public landing page, Booking page, Owner dashboard, Booking confirmation]
variables:
  - name: MAIL_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port. For 465, also set MAIL_TLS to true and
      MAIL_START_TLS to OPTIONAL.
  - name: MAIL_START_TLS
    group: Email (SMTP)
    default: REQUIRED
    description: >-
      REQUIRED for port 587 (STARTTLS), OPTIONAL for port 465.
  - name: MAIL_TLS
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for port 465 (TLS from the start).
  - name: SIGNUP_ENABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone make an account. Otherwise the admin adds
      users at /me/users.
  - name: OIDC_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to show "Sign in with SSO" (Authelia, Authentik, Pocket ID
      and others).
  - name: OIDC_ISSUER_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's address, like https://auth.example.com.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your provider.
  - name: OIDC_ADMIN_GROUP
    group: Sign in with OIDC
    default: ""
    description: >-
      Members of this provider group become calit admins. Leave it out for
      none.
  - name: GOOGLE_OAUTH_CLIENT_ID
    group: Google Calendar
    default: ""
    description: >-
      Your Google OAuth client ID, for Calendar sync and Meet links. In
      Google, add PUBLIC_URL/api/google/callback and
      PUBLIC_URL/api/google/login/callback as redirect URIs. Google needs an
      https address or localhost.
  - name: GOOGLE_OAUTH_CLIENT_SECRET
    group: Google Calendar
    default: ""
    description: >-
      Your Google OAuth client secret.
  - name: GOOGLE_PROBE_INTERVAL
    group: Google Calendar
    default: 1h
    description: >-
      How often each Google connection is checked, like 30m or 1h.
  - name: CALDAV_ALLOW_PRIVATE_HOSTS
    group: Calendars
    default: "false"
    description: >-
      Set to true to use a CalDAV server on your own network.
  - name: REMINDER_LEAD_MINUTES
    group: Bookings
    default: "1440"
    description: >-
      How many minutes before a meeting the reminder email goes out.
  - name: APPROVAL_HOLD_HOURS
    group: Bookings
    default: "24"
    description: >-
      How many hours a booking waits for approval before it expires.
  - name: PER_EMAIL_DAILY_CAP
    group: Bookings
    default: "10"
    description: >-
      Most bookings one email address can make in a day.
  - name: INVITEE_ERASURE
    group: Bookings
    default: "true"
    description: >-
      Set to false so guests can't erase their own data from the manage link.
  - name: BOOKING_RETENTION_DAYS
    group: Bookings
    default: ""
    description: >-
      Anonymise bookings this many days after they end, like 730. Leave it
      out to keep them.
  - name: CAPTCHA_PROVIDER
    group: Spam protection
    default: none
    description: >-
      none, turnstile or altcha (self-hosted, no outside service).
  - name: ALTCHA_HMAC_KEY
    group: Spam protection
    default: ""
    description: >-
      A long random secret. Needed when CAPTCHA_PROVIDER is altcha.
  - name: ALTCHA_MAX_NUMBER
    group: Spam protection
    default: "100000"
    description: >-
      How hard the ALTCHA puzzle is.
  - name: TURNSTILE_ENABLED
    group: Spam protection
    default: "false"
    description: >-
      Set to true to use Cloudflare Turnstile.
  - name: TURNSTILE_SITE_KEY
    group: Spam protection
    default: ""
    description: >-
      Your Turnstile site key.
  - name: TURNSTILE_SECRET_KEY
    group: Spam protection
    default: ""
    description: >-
      Your Turnstile secret key.
  - name: NOTIFY_ALLOWED_SCHEMES
    group: Notifications
    default: "*"
    description: >-
      Which notification channels users may add, like
      telegram,slack,discord,gotify,ntfy. * allows all.
  - name: NOTIFY_ALLOW_PRIVATE
    group: Notifications
    default: "true"
    description: >-
      Set to false so users can't send notifications to addresses on your
      network.
  - name: NOTIFY_MAX_ATTEMPTS
    group: Notifications
    default: "3"
    description: >-
      How many times a notification is tried.
  - name: OPERATOR_NAME
    group: Privacy page
    default: ""
    description: >-
      Your name or company, shown on /privacy and /terms.
  - name: PRIVACY_CONTACT_EMAIL
    group: Privacy page
    default: ""
    description: >-
      The email shown on /privacy for data requests.
  - name: GOOGLE_SITE_VERIFICATION
    group: Privacy page
    default: ""
    description: >-
      A Google Search Console verification token.
  - name: SESSION_ENCRYPTION_KEY
    group: Keys
    default: ""
    description: >-
      Leave it out: each install makes its own on first start. Changing it
      signs everyone out.
  - name: TOKEN_ENCRYPTION_KEY
    group: Keys
    default: ""
    description: >-
      64 hex characters. Leave it out: each install makes its own on first
      start. Never change it afterwards, or Google connections stop working.
  - name: QUARKUS_LOG_LEVEL
    group: Logs
    default: INFO
    description: >-
      DEBUG, INFO, WARN or ERROR.
---

# calit

calit is a scheduling app you host yourself, like Calendly. Every user gets their own booking pages: people pick a free time and book, and both sides get an email. This is calit in a single container, with PostgreSQL inside, one port and one data folder. Secret keys are made for you on first start.

## Features

- Booking pages per user and meeting type, with buffers, minimum notice and how far ahead people can book
- Weekly availability with date-by-date changes
- Optional approval before a booking is confirmed
- Extra questions on the booking form, reminder emails
- Optional Google Calendar sync with Google Meet links, and CalDAV
- Several users, with an admin to manage them; optional sign-in with OIDC (Authelia, Authentik, Pocket ID)
- Spam protection (Cloudflare Turnstile or self-hosted ALTCHA), notifications to Telegram, Slack, Discord, ntfy or Gotify
- PostgreSQL inside

## How to use

1. Open calit from your dashboard. The first visit goes to `/setup`.
2. Create the first user. It is the admin.
3. Make a meeting type and set when you are free.
4. Share your booking page, `http://[ZIMAOS-IP-ADDRESS]:6137/<your user name>`.

## Before you install

Change `localhost` in `PUBLIC_URL` to your ZimaOS IP, like `http://192.168.1.20:6137`; every booking link and email link starts with it. Fill in `MAIL_HOST`, `MAIL_USERNAME`, `MAIL_PASSWORD` and `MAIL_FROM` with your email server: calit sends every confirmation and reminder by email, and without them bookings still work but nobody is told (the mail waits and goes out once you set them). There is no default password: the first visit goes to `/setup`, where you make the admin account. Google Calendar sync needs an https address. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. The first start takes about a minute.
