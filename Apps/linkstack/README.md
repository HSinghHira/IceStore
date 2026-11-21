---
site: https://linkstack.org/
services:
  - { name: Your page, path: /, icon: globe }
  - { name: Admin panel, path: /dashboard, icon: server }
screenshots: [LinkStack, A theme, Setup wizard]
variables:
  - name: HTTP_SERVER_NAME
    group: Server
    default: "localhost"
    description: >-
      Your domain, like links.example.com, when you use one.
  - name: LOG_LEVEL
    group: Server
    default: "info"
    description: >-
      How much the web server logs: debug, info, warn or error.
  - name: PHP_MEMORY_LIMIT
    group: Server
    default: "256M"
    description: >-
      Memory PHP may use.
---

# LinkStack

LinkStack gives you a personal page with all your links on it, like Linktree, on your own server. Add links to your socials, websites and shops, pick a theme and share one address. Several people can each have their own page.

## Features

- One page with all your links, buttons and icons
- Many themes, and your own colors and pictures
- Click counts for every link
- Several users, each with their own page
- A setup wizard, no config files
- SQLite built in, or your own MySQL

## How to use

1. Open LinkStack from your dashboard.
2. Follow the setup wizard: pick SQLite and make the admin account.
3. Open the admin panel and add your links.
4. Pick a theme in Appearance.
5. Share your page address.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6776`. The setup wizard asks for the database (pick SQLite) and makes the admin account. On first start the app is copied into `/DATA/AppData/linkstack/htdocs`, as upstream's Docker volume does, so later updates to LinkStack itself are done in its admin panel under Updates. The other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
