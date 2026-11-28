---
site: https://www.openproject.org
source: https://github.com/opf/openproject
screenshots: [Work package, Portfolios, Meetings]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: OPENPROJECT_SEED_ADMIN_USER_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The first admin password. Made on first start when left out; only
      used when the database is first set up.
  - name: SECRET_KEY_BASE
    group: Security
    default: ""
    description: >-
      The key that signs sessions and encrypts data. Made on first start
      and kept in the assets folder; never change it afterwards.
  - name: OPENPROJECT_SEED_ADMIN_USER_MAIL
    group: Sign-in
    default: ""
    description: >-
      The admin's email address on first setup.
  - name: OPENPROJECT_EMAIL__DELIVERY__METHOD
    group: Email
    default: ""
    description: >-
      smtp to send emails (with OPENPROJECT_SMTP__ADDRESS,
      OPENPROJECT_SMTP__PORT, OPENPROJECT_SMTP__USER__NAME and
      OPENPROJECT_SMTP__PASSWORD).
  - name: OPENPROJECT_RAILS__RELATIVE__URL__ROOT
    group: Server
    default: ""
    description: >-
      Serve OpenProject under a sub-path, like /openproject.
  - name: OPENPROJECT_HSTS
    group: Server
    default: ""
    description: >-
      Set to false to stop HSTS headers when testing https.
---

# OpenProject

OpenProject plans and tracks projects of any size: work packages with Gantt charts, agile boards, backlogs, time and cost tracking, wikis, meetings and document collaboration, for your team or club.

## Features

- Work packages with types, workflows, relations and custom fields
- Gantt charts, team planner and roadmaps
- Scrum and kanban boards, backlogs and sprints
- Time and cost tracking, meetings and wikis
- Users, groups, roles and project permissions

## How to use

1. Open OpenProject and sign in as admin with the password from the CREDENTIALS box in the app's logs.
2. Create a project and add work packages.

## Before you install

You must set OPENPROJECT_HOST__NAME before installing: replace [ZIMAOS-IP-ADDRESS] with your ZimaOS IP (like 192.168.1.20:6869) or your domain, exactly as your browser shows it. The first start sets up the built-in database and takes about five minutes. The admin password is made on first start and shown in the app's logs, in the box marked CREDENTIALS (user admin). OPENPROJECT_HTTPS=false allows plain http on your home network; set it to true behind an https reverse proxy. The image is large and the app needs a few GB of memory.
