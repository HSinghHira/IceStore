---
site: https://nocodb.com/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API docs, path: /api/v2/meta/swagger, icon: code }
screenshots: [Grid view, Kanban view, Gallery view, Form view, Calendar view]
variables:
  - name: NC_PUBLIC_URL
    group: Server
    default: ""
    description: >-
      The address people open NocoDB at, like http://192.168.1.20:6765 or
      https://db.example.com. Used for links in emails and shared views.
  - name: NC_ADMIN_EMAIL
    group: Sign-up and accounts
    default: ""
    description: >-
      Make the super admin with this email on start, instead of the first
      person who signs up. Set it together with NC_ADMIN_PASSWORD.
  - name: NC_ADMIN_PASSWORD
    group: Sign-up and accounts
    default: ""
    description: >-
      The super admin's password, with NC_ADMIN_EMAIL. At least 8
      characters with a capital letter, a number and a symbol.
  - name: NC_JWT_EXPIRES_IN
    group: Sign-up and accounts
    default: 10h
    description: >-
      How long people stay signed in, like 10h or 7d.
  - name: NC_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com, for invites and password
      resets. You can also set email up in the app under Team & Settings.
  - name: NC_SMTP_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server port, usually 587 or 465.
  - name: NC_SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: NC_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: NC_SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: NC_SMTP_SECURE
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true for port 465.
  - name: NC_DB
    group: Database
    default: ""
    description: >-
      Keep NocoDB's own data in your PostgreSQL or MySQL instead of the
      SQLite file, like pg://192.168.1.20:5432?u=nocodb&p=secret&d=nocodb.
      Set it before you start using NocoDB.
  - name: NC_ATTACHMENT_FIELD_SIZE
    group: Files
    default: "20971520"
    description: >-
      The biggest attachment people can upload, in bytes. The default is
      20 MB.
---

# NocoDB

NocoDB looks like a spreadsheet but works like a database. Make tables for contacts, orders or anything else, link them together, and look at them as a grid, a kanban board, a gallery, a form or a calendar. It keeps its data in a built-in SQLite file, so there is nothing else to set up.

## Features

- Grid, kanban, gallery, form and calendar views
- Links between tables, lookups, formulas and roll-ups
- Filters, sorting, grouping and shared views with a link
- Forms anyone can fill in to add rows
- Users and roles per base, with comments and history
- REST API and webhooks, or connect your own PostgreSQL or MySQL

## How to use

1. Open NocoDB from your dashboard.
2. Sign up with your email and a password. The first account becomes the super admin.
3. Click New Base, then add a table and your columns.
4. Add a Kanban, Gallery or Form view from the left side.
5. Click Share to invite people or share a view with a link.

## Before you install

You can install it as it is. Open `http://[ZIMAOS-IP-ADDRESS]:6765` right after the first start and sign up: the first account becomes the super admin. To make the admin yourself instead, add `NC_ADMIN_EMAIL` and `NC_ADMIN_PASSWORD` before you install. NocoDB makes its own sign-in key on first start and keeps it in its database. Set `NC_PUBLIC_URL` for working links in emails. Those and the other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
