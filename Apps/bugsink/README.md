---
site: https://www.bugsink.com
source: https://github.com/bugsink/bugsink
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: SINGLE_USER
    group: Users
    default: "false"
    description: >-
      true hides teams and users, for one person.
  - name: USER_REGISTRATION
    group: Users
    default: "CB_MEMBERS"
    description: >-
      Who may sign up: CB_ANYBODY, CB_MEMBERS (invited), CB_ADMINS or CB_NOBODY.
  - name: EMAIL_HOST
    group: Email
    default: ""
    description: >-
      Mail server for alerts and invites.
  - name: EMAIL_PORT
    group: Email
    default: "587"
    description: >-
      Mail server port.
  - name: EMAIL_HOST_USER
    group: Email
    default: ""
    description: >-
      Mail server user name.
  - name: EMAIL_HOST_PASSWORD
    group: Email
    default: ""
    description: >-
      Mail server password.
  - name: EMAIL_USE_SSL
    group: Email
    default: "false"
    description: >-
      true for port 465 (TLS from the start).
  - name: DEFAULT_FROM_EMAIL
    group: Email
    default: "Bugsink <bugsink@example.org>"
    description: >-
      The sender on emails Bugsink sends.
  - name: MAX_EVENTS_PER_HOUR
    group: Limits
    default: "5000"
    description: >-
      Most events accepted per hour, over all projects.
  - name: MAX_EVENT_AGE_DAYS
    group: Limits
    default: ""
    description: >-
      Delete events older than this many days. Blank keeps them.
  - name: MAX_RETENTION_PER_PROJECT_EVENT_COUNT
    group: Limits
    default: ""
    description: >-
      Most events kept for each project.
  - name: BEHIND_HTTPS_PROXY
    group: Web
    default: "false"
    description: >-
      true when a reverse proxy with https sits in front (set BASE_URL to the https address too).
  - name: SITE_TITLE
    group: Web
    default: "Bugsink"
    description: >-
      The name shown in the page title.
  - name: PHONEHOME
    group: Advanced
    default: "true"
    description: >-
      false stops Bugsink from sending anonymous install counts to its makers.
  - name: SECRET_KEY
    group: Advanced
    default: ""
    description: >-
      Django secret key. Leave blank and IceStore makes one and keeps it.
---

# Bugsink

Bugsink collects the errors and crashes from your apps and groups them into issues, with stack traces and the details you need to fix them. Your apps send errors with the normal Sentry SDKs.

## Features

- Works with the Sentry SDKs for Python, JavaScript, Go, PHP and more
- Errors grouped into issues, with stack traces and source context
- Email alerts and webhooks (Slack, Mattermost, Discord)
- Teams, projects and users
- Light: one container and SQLite

## How to use

1. Set BASE_URL to your ZimaOS IP address before you start.
2. Open the app's log and find the admin password under CREDENTIALS, then sign in with ADMIN_EMAIL.
3. Make a project and put its DSN into your app's Sentry SDK.

## Before you install

Change BASE_URL first: put your ZimaOS IP address in place of [ZIMAOS-IP-ADDRESS], so it reads like http://192.168.1.20:7008. Bugsink only answers to that host name and uses it in every DSN. The first admin is made on first start with ADMIN_EMAIL and a password shown in the app's log under CREDENTIALS (or the one you type in ADMIN_PASSWORD). Apps on your home network can send errors straight away; apps on the internet need a reverse proxy with your domain, then set BASE_URL to that https address and BEHIND_HTTPS_PROXY to true.
