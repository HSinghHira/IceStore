---
site: https://healthchecks.io/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API docs, path: /docs/api/, icon: code }
screenshots: [My checks, Check details, Cron schedule]
variables:
  - name: ALLOWED_HOSTS
    group: Server
    default: "*"
    description: >-
      The names Healthchecks answers to, comma separated. * allows any.
  - name: PING_ENDPOINT
    group: Server
    default: ""
    description: >-
      The start of ping URLs. Leave it out to use SITE_ROOT/ping/.
  - name: PING_BODY_LIMIT
    group: Server
    default: "10000"
    description: >-
      How much of a ping's body to keep, in bytes.
  - name: SITE_LOGO_URL
    group: Server
    default: ""
    description: >-
      A link to your own logo.
  - name: SECRET_KEY
    group: Server
    default: ""
    description: >-
      The key sessions are signed with. It is made on first start and kept in
      /data/secrets.env. Only set it to use your own.
  - name: REMOTE_USER_HEADER
    group: Server
    default: ""
    description: >-
      Sign in from a header a proxy sets, like HTTP_REMOTE_EMAIL.
  - name: SECURE_PROXY_SSL_HEADER
    group: Server
    default: ""
    description: >-
      Set to HTTP_X_FORWARDED_PROTO,https behind an https reverse proxy.
  - name: INTEGRATIONS_ALLOW_PRIVATE_IPS
    group: Server
    default: "False"
    description: >-
      Set to True so webhooks can call addresses on your own network.
  - name: DEFAULT_FROM_EMAIL
    group: Email (SMTP)
    default: "healthchecks@example.org"
    description: >-
      The address emails are sent from.
  - name: EMAIL_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com, for alerts and sign-in links.
  - name: EMAIL_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: EMAIL_HOST_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: EMAIL_HOST_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: EMAIL_USE_TLS
    group: Email (SMTP)
    default: "True"
    description: >-
      Use STARTTLS (port 587).
  - name: EMAIL_USE_SSL
    group: Email (SMTP)
    default: "False"
    description: >-
      Set to True for SSL (port 465).
  - name: EMAIL_USE_VERIFICATION
    group: Email (SMTP)
    default: "True"
    description: >-
      Ask people to confirm an email address before alerts go to it.
  - name: SMTPD_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      Set a port, like 2525, to accept pings by email (also publish it).
  - name: APPRISE_ENABLED
    group: Alerts
    default: "False"
    description: >-
      Set to True to send alerts through Apprise.
  - name: SHELL_ENABLED
    group: Alerts
    default: "False"
    description: >-
      Set to True to run shell commands as alerts.
  - name: NTFY_SH_TOKEN
    group: Alerts
    default: ""
    description: >-
      Your ntfy.sh access token.
  - name: TELEGRAM_BOT_NAME
    group: Alerts
    default: "ExampleBot"
    description: >-
      Your Telegram bot's name.
  - name: TELEGRAM_TOKEN
    group: Alerts
    default: ""
    description: >-
      Your Telegram bot's token.
  - name: DISCORD_CLIENT_ID
    group: Alerts
    default: ""
    description: >-
      Discord app client ID.
  - name: DISCORD_CLIENT_SECRET
    group: Alerts
    default: ""
    description: >-
      Discord app client secret.
  - name: SLACK_CLIENT_ID
    group: Alerts
    default: ""
    description: >-
      Slack app client ID (plain Slack webhooks work without it).
  - name: SLACK_CLIENT_SECRET
    group: Alerts
    default: ""
    description: >-
      Slack app client secret.
  - name: MATRIX_HOMESERVER
    group: Alerts
    default: ""
    description: >-
      Your Matrix server, like https://matrix.org.
  - name: MATRIX_USER_ID
    group: Alerts
    default: ""
    description: >-
      The Matrix bot user, like @bot:matrix.org.
  - name: MATRIX_ACCESS_TOKEN
    group: Alerts
    default: ""
    description: >-
      The Matrix bot's access token.
  - name: PUSHOVER_API_TOKEN
    group: Alerts
    default: ""
    description: >-
      Your Pushover app token.
  - name: PUSHOVER_SUBSCRIPTION_URL
    group: Alerts
    default: ""
    description: >-
      Your Pushover subscription URL.
  - name: SIGNAL_CLI_SOCKET
    group: Alerts
    default: ""
    description: >-
      The signal-cli socket, for Signal alerts.
  - name: TWILIO_ACCOUNT
    group: Alerts
    default: ""
    description: >-
      Twilio account SID, for SMS and calls.
  - name: TWILIO_AUTH
    group: Alerts
    default: ""
    description: >-
      Twilio auth token.
  - name: TWILIO_FROM
    group: Alerts
    default: ""
    description: >-
      The Twilio number to send from.
  - name: PROMETHEUS_ENABLED
    group: Alerts
    default: "True"
    description: >-
      Set to False to hide the Prometheus metrics option.
---

# Healthchecks

Healthchecks watches your scheduled jobs: backups, cron jobs, scripts. Each job calls its own ping URL when it runs. When a ping does not come in on time, Healthchecks tells you by email, ntfy, Telegram, Discord, Slack and many more. It uses a built-in SQLite database, so it is one container with nothing else to set up.

## Features

- A ping URL for every job, with simple or cron schedules
- Grace time before an alert goes out
- Start, success and failure signals, and run times
- Alerts to more than 25 services, plus webhooks
- Projects, teams and read-only badges
- A full API and Prometheus metrics

## How to use

1. Open Healthchecks from your dashboard.
2. Sign in with the email and the password from the app's logs (the box marked CREDENTIALS).
3. Click Add Check and set how often the job runs.
4. Copy its ping URL into your job, like curl at the end of a script.
5. Add where alerts go in Integrations.

## Before you install

Set `SITE_ROOT` to `http://[ZIMAOS-IP-ADDRESS]:6773` with your ZimaOS IP in place of `[ZIMAOS-IP-ADDRESS]`: the ping URLs your jobs call are made from it. The first account is `ADMIN_EMAIL` (`admin@example.com` unless you change it) with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/healthchecks/data/.admin_password`. Email, the alert services and the other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
