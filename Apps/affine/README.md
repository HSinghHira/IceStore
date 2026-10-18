---
site: https://affine.pro
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Panel, path: /admin, icon: server }
screenshots: [Whiteboard, Brainstorm with AI, Documents, Admin panel]
---

# AFFiNE

AFFiNE is an open-source workspace that puts documents, an endless whiteboard and databases in one editor, like Notion and Miro together. This is AFFiNE in a single container, with one port and one data folder. Database passwords and the server key are made for you on first start.

## Features

- Rich documents for notes, wikis and knowledge bases
- An endless canvas for whiteboards, brainstorming and planning
- Databases with table and kanban views
- Real-time collaboration and sharing
- Built-in search across all your workspaces
- Admin panel for users, settings, email and AI (bring your own key)
- PostgreSQL with pgvector and Redis inside, nothing else to install

## How to use

1. Open AFFiNE from your dashboard.
2. The first time, AFFiNE asks you to create the admin account. Fill in your name, email and a password.
3. Sign in and create your first workspace.
4. Change server settings, email and AI any time in the admin panel at `http://your-server-ip:6102/admin`.

## Before you install

To use AFFiNE from other devices, change `localhost` in `PUBLIC_URL` to your server's IP address. Fill in the `MAILER_` settings only if you want AFFiNE to send emails. The first start takes about 5 minutes while the database is set up. There is no default password: you make the admin account the first time you open AFFiNE.
