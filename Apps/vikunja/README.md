---
site: https://vikunja.io/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API docs, path: /api/v1/docs, icon: code }
screenshots: [Overview, List, Kanban, Gantt, Task details]
variables:
  - name: VIKUNJA_SERVICE_SECRET
    group: Server
    default: ""
    description: >-
      The key that signs sign-ins. It is made on first start and kept in the
      data folder as .service_secret. Only set it to use your own.
  - name: VIKUNJA_SERVICE_TIMEZONE
    group: Server
    default: ""
    description: >-
      The time zone for reminders, like Europe/Berlin. Leave it out to use
      TZ.
  - name: VIKUNJA_SERVICE_ENABLECALDAV
    group: Features
    default: "true"
    description: >-
      Set to false to turn off CalDAV sync.
  - name: VIKUNJA_SERVICE_ENABLELINKSHARING
    group: Features
    default: "true"
    description: >-
      Set to false so nobody can share a project with a public link.
  - name: VIKUNJA_SERVICE_ENABLETASKATTACHMENTS
    group: Features
    default: "true"
    description: >-
      Set to false to turn off file attachments on tasks.
  - name: VIKUNJA_SERVICE_ENABLETASKCOMMENTS
    group: Features
    default: "true"
    description: >-
      Set to false to turn off comments on tasks.
  - name: VIKUNJA_SERVICE_ENABLETOTP
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn off two-factor sign-in.
  - name: VIKUNJA_SERVICE_ENABLEUSERDELETION
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false so people can't delete their own account.
  - name: VIKUNJA_SERVICE_ENABLEPUBLICTEAMS
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let teams be found and joined by anyone on this
      Vikunja.
  - name: VIKUNJA_SERVICE_ENABLEEMAILREMINDERS
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false to stop reminder emails. Needs the mailer below.
  - name: VIKUNJA_MAILER_ENABLED
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to send emails: reminders, password resets and invites.
  - name: VIKUNJA_MAILER_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: VIKUNJA_MAILER_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: VIKUNJA_MAILER_USERNAME
    group: Email (SMTP)
    default: user
    description: >-
      The user name for your email server.
  - name: VIKUNJA_MAILER_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: VIKUNJA_MAILER_FROMEMAIL
    group: Email (SMTP)
    default: mail@vikunja
    description: >-
      The address emails are sent from.
  - name: VIKUNJA_MAILER_FORCESSL
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for port 465.
  - name: VIKUNJA_FILES_MAXSIZE
    group: Files
    default: 20MB
    description: >-
      The biggest file people can attach, like 100MB.
  - name: VIKUNJA_DEFAULTSETTINGS_EMAIL_REMINDERS_ENABLED
    group: New users
    default: "false"
    description: >-
      Set to true so new users get reminder emails without turning them on.
  - name: VIKUNJA_DEFAULTSETTINGS_WEEK_START
    group: New users
    default: "0"
    description: >-
      The first day of the week for new users: 0 is Sunday, 1 is Monday.
  - name: VIKUNJA_DEFAULTSETTINGS_LANGUAGE
    group: New users
    default: ""
    description: >-
      The language for new users, like de-DE or fr-FR. Leave it out to follow
      the browser.
  - name: VIKUNJA_LOG_LEVEL
    group: Logs
    default: INFO
    description: >-
      How much Vikunja writes to the log: CRITICAL, ERROR, WARNING, INFO or
      DEBUG.
---

# Vikunja

Vikunja is a to-do app for you, your family or your team. Put tasks in projects and look at them as a list, a kanban board, a table or a Gantt chart. The database is built in, so it is one container with nothing else to set up.

## Features

- List, kanban, table and Gantt views of every project
- Due dates, reminders, repeating tasks, labels and priorities
- Quick add with words like "tomorrow" or "*shopping"
- Share projects with people, teams or a public link
- Attachments, comments and task relations
- CalDAV sync with your phone's calendar and reminders, and a REST API

## How to use

1. Open Vikunja from your dashboard.
2. Click Create account and make your account.
3. Make a project and add your first tasks.
4. Switch between List, Kanban, Table and Gantt at the top.
5. When everyone has an account, set `VIKUNJA_SERVICE_ENABLEREGISTRATION` to `false` in the app settings.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6761`. There is no admin account: make yours with Create account, then set `VIKUNJA_SERVICE_ENABLEREGISTRATION=false`. Set `VIKUNJA_SERVICE_PUBLICURL` to the address you use (like `http://[ZIMAOS-IP-ADDRESS]:6761`) when you want working links in emails or CalDAV on your phone. A secret is made on first start, so people stay signed in across restarts. Email and the other settings are in the Variables tab and are added in the app settings. Sign-in with OpenID is set up with a config file; see the Vikunja docs. It is ready in under a minute.
