---
site: https://open-todo.app
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Day planner, Project, Board, Dashboard]
variables:
  - name: OPENTODO_BASE_URL
    group: Server
    default: ""
    description: >-
      The exact address people open, like https://todo.example.com. Needed
      behind a reverse proxy for passkeys, secure cookies and links. Leave it
      out when you open OpenTodo by the ZimaOS address.
  - name: OPENTODO_TRUSTED_PROXIES
    group: Server
    default: ""
    description: >-
      Reverse proxies whose X-Forwarded-For is trusted, as IPs or ranges
      separated by commas, or cloudflare. Set it only when every request
      comes through them.
  - name: OPENTODO_SESSION_DAYS
    group: Server
    default: "90"
    description: >-
      How many days people stay signed in.
  - name: OPENTODO_IMPORT_MAX_MB
    group: Server
    default: "20"
    description: >-
      Largest import file in MB (1 to 200).
  - name: OPENTODO_TRASH_RETENTION_DAYS
    group: Server
    default: "30"
    description: >-
      Days a deleted task stays in the Trash. 0 keeps it until you empty the
      Trash.
  - name: OPENTODO_PUSH
    group: Server
    default: ""
    description: >-
      Set to off to turn off web push reminders, so the server never contacts
      a push service.
  - name: OPENTODO_ALLOW_SIGNUP
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone who can reach the server create an account.
      Otherwise the owner invites people.
  - name: OPENTODO_SETUP_TOKEN
    group: Sign-up and accounts
    default: ""
    description: >-
      16 characters or more. Creating the first (owner) account then asks for
      it, so a stranger can't claim a server open to the internet.
  - name: OPENTODO_SETUP_CODE
    group: Sign-up and accounts
    default: ""
    description: >-
      Set to required so the first account made from another device needs the
      one-time code from the app log.
  - name: OPENTODO_OIDC_ISSUER
    group: Single sign-on
    default: ""
    description: >-
      Your OpenID Connect provider, like https://sso.example.com. Leave the
      single sign-on settings out to set them up in Settings instead.
  - name: OPENTODO_OIDC_CLIENT_ID
    group: Single sign-on
    default: ""
    description: >-
      The client ID from your provider.
  - name: OPENTODO_OIDC_CLIENT_SECRET
    group: Single sign-on
    default: ""
    description: >-
      The client secret from your provider.
  - name: OPENTODO_OIDC_DISPLAY_NAME
    group: Single sign-on
    default: ""
    description: >-
      The name on the sign-in button, like Home SSO.
  - name: OPENTODO_OIDC_SSO_ONLY
    group: Single sign-on
    default: ""
    description: >-
      Set to false to turn SSO-only mode off, whatever Settings says.
  - name: OPENTODO_MCP
    group: Features
    default: ""
    description: >-
      true or false: the first-start setting for the AI assistant (MCP)
      endpoint. Settings wins afterwards.
  - name: OPENTODO_CALDAV
    group: Features
    default: ""
    description: >-
      true or false: the first-start setting for calendar apps (CalDAV).
      Settings wins afterwards.
  - name: OPENTODO_WEBHOOKS_ALLOW_PRIVATE
    group: Features
    default: ""
    description: >-
      Set to true so webhooks may go to your own network, like Home Assistant
      or n8n. Settings wins afterwards.
  - name: OPENTODO_BACKUP_DESTINATION
    group: Backups
    default: ""
    description: >-
      local, s3 or webdav. These backup settings are used once, on first
      start; Settings, Backups wins afterwards.
  - name: OPENTODO_BACKUP_SCHEDULE
    group: Backups
    default: ""
    description: >-
      off, hourly, daily or weekly.
  - name: OPENTODO_BACKUP_TIME
    group: Backups
    default: ""
    description: >-
      The time of day for backups, like 03:00.
  - name: OPENTODO_BACKUP_KEEP
    group: Backups
    default: ""
    description: >-
      How many backups to keep, like 7.
  - name: OPENTODO_BACKUP_PASSPHRASE
    group: Backups
    default: ""
    description: >-
      A passphrase to encrypt backups with. Keep it somewhere safe.
  - name: OPENTODO_BACKUP_S3_ENDPOINT
    group: Backups
    default: ""
    description: >-
      The S3 address, like https://s3.eu-central-1.amazonaws.com.
  - name: OPENTODO_BACKUP_S3_REGION
    group: Backups
    default: ""
    description: >-
      The S3 region.
  - name: OPENTODO_BACKUP_S3_BUCKET
    group: Backups
    default: ""
    description: >-
      The S3 bucket.
  - name: OPENTODO_BACKUP_S3_ACCESS_KEY
    group: Backups
    default: ""
    description: >-
      The S3 access key.
  - name: OPENTODO_BACKUP_S3_SECRET_KEY
    group: Backups
    default: ""
    description: >-
      The S3 secret key.
  - name: OPENTODO_BACKUP_WEBDAV_URL
    group: Backups
    default: ""
    description: >-
      The WebDAV address.
  - name: OPENTODO_BACKUP_WEBDAV_USERNAME
    group: Backups
    default: ""
    description: >-
      The WebDAV user name.
  - name: OPENTODO_BACKUP_WEBDAV_PASSWORD
    group: Backups
    default: ""
    description: >-
      The WebDAV password.
  - name: OPENTODO_EMAIL_ADDRESS
    group: Email to task
    default: ""
    description: >-
      The address that turns mail into tasks, like todo@example.com. Set this
      and the three IMAP settings together, or none of them.
  - name: OPENTODO_EMAIL_IMAP_HOST
    group: Email to task
    default: ""
    description: >-
      The IMAP server with its port, like imap.example.com:993.
  - name: OPENTODO_EMAIL_IMAP_USER
    group: Email to task
    default: ""
    description: >-
      The IMAP user name.
  - name: OPENTODO_EMAIL_IMAP_PASSWORD
    group: Email to task
    default: ""
    description: >-
      The IMAP password.
  - name: OPENTODO_EMAIL_IMAP_MAILBOX
    group: Email to task
    default: INBOX
    description: >-
      The mailbox to read.
  - name: OPENTODO_EMAIL_POLL_SECONDS
    group: Email to task
    default: "60"
    description: >-
      How often to check for mail, in seconds.
  - name: OPENTODO_LOG_LEVEL
    group: Logs
    default: info
    description: >-
      debug, info, warn or error.
---

# OpenTodo

OpenTodo is a to-do app that runs on your own server. Plan your day, keep projects in order, set reminders and share lists with your family or your team, on your phone and your computer, even offline.

## Features

- Projects, labels, due dates, priorities, reminders and repeating tasks
- Today, day planner, boards, filters and a history you can undo
- Works offline: every device keeps its own copy and syncs when it can
- Share projects and invite people; no plan per person
- Import from other apps, export to JSON, scheduled backups to disk, S3 or WebDAV
- Optional calendar apps (CalDAV), webhooks, single sign-on and AI assistants (off by default)
- One small container with SQLite inside, about 20 MB of memory

## How to use

1. Open OpenTodo from your dashboard.
2. Create your account. The first account is the owner.
3. Add tasks with `q`, or open Settings to invite people.
4. Installing it as a phone app, offline use, push reminders and passkeys need an https address (a reverse proxy). Everything else works on `http://[ZIMAOS-IP-ADDRESS]:6136`.

## Before you install

Nothing has to be set. It is ready a few seconds after the start: open `http://[ZIMAOS-IP-ADDRESS]:6136` and create your account, which becomes the owner (there is no default password). If your ZimaOS can be reached from the internet, add `OPENTODO_SETUP_TOKEN` (16 characters or more) first, so nobody else can make the owner account. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default.
