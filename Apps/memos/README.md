---
site: https://www.usememos.com/
services:
  - { name: Memos, path: /, icon: globe }
screenshots: [Timeline, Dark theme]
variables:
  - name: MEMOS_INSTANCE_URL
    group: Server
    default: ""
    description: >-
      The address people use to open Memos, like
      http://[ZIMAOS-IP-ADDRESS]:6791 or https://memos.example.com. Used in
      share links and RSS feeds.
  - name: MEMOS_LOG_LEVEL
    group: Logs
    default: "info"
    description: >-
      How much Memos writes to the log: debug, info, warn or error.
---

# Memos

Memos is a light note-taking app. Jot down a thought, a link or a to-do in a few seconds, and it lands on your timeline. Everything is kept in one small file on your server.

## Features

- Write in Markdown, with tags, task lists and code blocks
- A timeline of memos, with search, tags and a calendar
- Attach images and files
- Private, team-only or public memos, and share links
- Several users, an API and webhooks
- Light and dark themes, and many languages

## How to use

1. Open Memos from your dashboard.
2. Sign up. The first account you make is the admin.
3. Type a memo in the box at the top and press Save.
4. Add #tags to sort memos, and find them again in the side bar.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6791` and sign up: the first account is the admin, so make it before anyone else on your network does. Sign-up for others can be turned off later in Settings. Memos keeps its database and uploads in `/DATA/AppData/memos/data`. The share-link address and log level are in the Variables tab and are added in the app settings. It is ready in a few seconds.
