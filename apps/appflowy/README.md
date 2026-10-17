---
site: https://appflowy.com
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Console, path: /console, icon: server }
  - { name: Mail Viewer, path: /mail, icon: mail }
---

# AppFlowy AIO

AppFlowy is an open-source workspace for notes, docs, wikis and projects. This is the self-hosted AppFlowy Cloud in a single container, with one port and one data folder. Secret keys are made for you on first start.

## Features

- Docs, databases, boards, calendars and wikis in one workspace
- Real-time sync and teamwork across web, desktop and mobile apps
- Workspaces, members, guests and sharing with access control
- Publish pages to the web
- Built-in keyword search
- PostgreSQL with pgvector, Redis and Silo file storage inside
- Admin console to manage users and workspaces
- Bundled Mailpit catches all email, such as invites and password resets

## How to use

1. Open AppFlowy AIO from your dashboard.
2. Sign up with your email and password.
3. Create your first workspace and page.
4. To use the AppFlowy desktop or mobile app, choose the self-hosted server option and enter your address with port `8481`.
5. Manage users at `/console`. Sign in with the admin email and password.
6. Read the email AppFlowy sends at `/mail`.

## Before you install

Set `ADMIN_EMAIL` to your own email. Leave `ADMIN_PASSWORD` blank to get a random one, shown in the app log as "admin password is". To use AppFlowy from other devices, change `localhost` in `PUBLIC_URL` to your server's IP address. The first start takes about four minutes.
