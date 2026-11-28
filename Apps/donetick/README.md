---
site: https://donetick.com
source: https://github.com/donetick/donetick
screenshots: [Chores, Chore details, Mobile overview]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: DONETICK_TELEGRAM_TOKEN
    group: Notifications
    default: ""
    description: >-
      Telegram bot token, for chore reminders in Telegram.
  - name: DONETICK_PUSHOVER_TOKEN
    group: Notifications
    default: ""
    description: >-
      Pushover app token, for chore reminders with Pushover.
  - name: DT_EMAIL_HOST
    group: Email
    default: ""
    description: >-
      Mail server, for password reset emails.
  - name: DT_EMAIL_PORT
    group: Email
    default: ""
    description: >-
      Mail server port.
  - name: DT_EMAIL_EMAIL
    group: Email
    default: ""
    description: >-
      Address emails are sent from.
  - name: DT_EMAIL_KEY
    group: Email
    default: ""
    description: >-
      Mail server password or API key.
  - name: DT_EMAIL_APP_HOST
    group: Email
    default: ""
    description: >-
      Your Donetick address, used in links in emails.
  - name: DT_OAUTH2_NAME
    group: Sign-in
    default: ""
    description: >-
      Name on the button for your own OAuth/OIDC sign-in (like Authentik or Pocket ID).
  - name: DT_OAUTH2_CLIENT_ID
    group: Sign-in
    default: ""
    description: >-
      OAuth client id.
  - name: DT_OAUTH2_CLIENT_SECRET
    group: Sign-in
    default: ""
    description: >-
      OAuth client secret.
  - name: DT_OAUTH2_AUTH_URL
    group: Sign-in
    default: ""
    description: >-
      OAuth authorize URL.
  - name: DT_OAUTH2_TOKEN_URL
    group: Sign-in
    default: ""
    description: >-
      OAuth token URL.
  - name: DT_OAUTH2_USER_INFO_URL
    group: Sign-in
    default: ""
    description: >-
      OAuth user info URL.
  - name: DT_OAUTH2_REDIRECT_URL
    group: Sign-in
    default: ""
    description: >-
      Redirect URL to give your OAuth provider, your Donetick address plus /auth/oauth2.
  - name: DT_JWT_SESSION_TIME
    group: Sign-in
    default: "168h"
    description: >-
      How long a sign-in lasts.
  - name: DT_JWT_SECRET
    group: Sign-in
    default: ""
    description: >-
      Secret that signs sign-ins. Leave blank and IceStore makes one.
  - name: DT_SCHEDULER_JOBS_DUE_JOB
    group: Reminders
    default: "30m"
    description: >-
      How often due chores are checked.
  - name: DONETICK_LOG_LEVEL
    group: Advanced
    default: "info"
    description: >-
      Log detail: debug, info, warn or error.
---

# Donetick

Donetick is a task and chore manager for families and small groups. Make chores that repeat, hand them out in turns, and get reminders when something is due.

## Features

- Repeating chores by day, week, month or after they are done
- Take turns: assign to the next person, randomly or by least done
- Reminders by Telegram, Pushover, ntfy and more
- Points and history for who did what
- Phone apps, an API and Home Assistant support

## How to use

1. Open Donetick and sign up. Make a circle (group) for your household.
2. Invite the others, or have them sign up and join your circle.
3. Set DONETICK_DISABLE_SIGNUP to true, then add your first chores.

## Before you install

Donetick has no default login: open http://[ZIMAOS-IP-ADDRESS]:6899 and sign up, and let the rest of your household sign up too. When everyone has an account, set DONETICK_DISABLE_SIGNUP to true so nobody else can. The phone apps connect with the same address. Upstream's settings file ships one JWT secret for everyone; this IceStore image makes one per install and keeps it in the data folder. Any setting in upstream's selfhosted.yaml can be set as DT_ plus its path in capitals, like DT_SERVER_RATE_LIMIT.
