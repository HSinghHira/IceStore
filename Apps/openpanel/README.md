---
site: https://openpanel.dev
source: https://github.com/Openpanel-dev/openpanel
services:
  - { name: Dashboard, path: /, icon: globe }
  - { name: Tracking API, path: /api, icon: server }
screenshots: [Web analytics, Real-time, Funnel report, Dashboard, Retention, User profile]
variables:
  - name: ALLOW_REGISTRATION
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone make an account. The first account can
      always be made.
  - name: ALLOW_INVITATION
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn off inviting people to your organization.
  - name: RESEND_API_KEY
    group: Email
    default: ""
    description: >-
      A Resend API key, to send invitation and password reset emails through
      Resend.
  - name: EMAIL_SENDER
    group: Email
    default: "hello@openpanel.dev"
    description: >-
      The address emails are sent from.
  - name: SMTP_HOST
    group: Email
    default: ""
    description: >-
      Your email server, like smtp.gmail.com, to send emails without Resend.
  - name: SMTP_PORT
    group: Email
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: SMTP_SECURE
    group: Email
    default: "false"
    description: >-
      Set to true for port 465 (TLS from the start).
  - name: SMTP_USER
    group: Email
    default: ""
    description: >-
      The user name for your email server.
  - name: SMTP_PASS
    group: Email
    default: ""
    description: >-
      The password for your email server.
  - name: GOOGLE_CLIENT_ID
    group: Sign in with Google or GitHub
    default: ""
    description: >-
      Google OAuth client ID. Its redirect URI is
      PUBLIC_URL/api/oauth/google/callback.
  - name: GOOGLE_CLIENT_SECRET
    group: Sign in with Google or GitHub
    default: ""
    description: >-
      Google OAuth client secret.
  - name: GITHUB_CLIENT_ID
    group: Sign in with Google or GitHub
    default: ""
    description: >-
      GitHub OAuth app client ID. Its callback is
      PUBLIC_URL/api/oauth/github/callback.
  - name: GITHUB_CLIENT_SECRET
    group: Sign in with Google or GitHub
    default: ""
    description: >-
      GitHub OAuth app client secret.
  - name: OPENAI_API_KEY
    group: AI
    default: ""
    description: >-
      Your OpenAI API key, for the AI chat about your data.
  - name: ANTHROPIC_API_KEY
    group: AI
    default: ""
    description: >-
      Your Anthropic API key, for the AI chat about your data.
  - name: OPENAI_BASE_URL
    group: AI
    default: ""
    description: >-
      Another OpenAI-compatible server, like http://192.168.1.20:11434/v1.
  - name: API_CORS_ORIGINS
    group: Server
    default: ""
    description: >-
      Extra websites allowed to call the API, comma separated, like
      https://app.example.com.
  - name: DISABLE_PING
    group: Server
    default: "false"
    description: >-
      Set to true to stop OpenPanel's anonymous usage ping.
  - name: DISABLE_FAVICON_FETCH
    group: Server
    default: "false"
    description: >-
      Set to true to stop OpenPanel fetching website icons from the
      internet.
  - name: COOKIE_TLDS
    group: Server
    default: ""
    description: >-
      Extra two-part domain endings for sign-in cookies, like my.id, when
      you use such a domain.
---

# OpenPanel

OpenPanel is web and product analytics you host yourself: page views, visitors and sources like Plausible, plus events, funnels, retention and user profiles like Mixpanel. This is OpenPanel in a single container, with PostgreSQL, ClickHouse and Redis inside, one port and one data folder. Secret keys are made for you on first start.

## Features

- Web analytics: visitors, pages, referrers, countries and devices
- Product analytics: events, funnels, retention and conversion
- User profiles and sessions, and a real-time view
- Custom dashboards and reports, shareable with a link
- Cookieless tracking with SDKs for websites, React, Next.js, apps and servers
- Teams with invitations, and an optional AI chat about your data
- PostgreSQL, ClickHouse and Redis inside

## How to use

1. Open OpenPanel from your dashboard.
2. Create your account. The first account is the owner.
3. Add a project, then put the tracking snippet it shows on your website.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6191`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6191`, or use your https address. The dashboard and the tracking script on your websites talk to it, at `http://[ZIMAOS-IP-ADDRESS]:6191/api`. Until it is set, OpenPanel only opens on the server itself and shows a note everywhere else.

There is no admin password to set: the first person to open OpenPanel and sign up becomes the owner, and sign-up closes after that. Invite others from your organization's Members page. To track a public website, OpenPanel must be reachable from the internet at an https address. Email, sign-in with Google or GitHub and the other settings are in the Variables tab; add them in the app settings. OpenPanel needs about 1.5 GB of memory, and the first start takes about 5 minutes.
