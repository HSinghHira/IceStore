---
site: https://github.com/BaldissaraMatheus/Tasks.md
source: https://github.com/BaldissaraMatheus/Tasks.md
services:
  - { name: Board, path: /, icon: grid }
variables:
  - name: BASE_PATH
    group: Web
    default: ""
    description: >-
      Serve Tasks.md under a sub path, like /tasks, behind a reverse proxy. The phone app (PWA) only works without it.
  - name: LOCAL_IMAGES_CLEANUP_INTERVAL
    group: Images
    default: "1440"
    description: >-
      Minutes between removing images no card uses any more. 0 turns this off.
---

# Tasks.md

Tasks.md is a simple kanban board. Every lane is a folder and every card is a Markdown file, so your tasks stay readable and you can edit them with any text editor or sync them anywhere.

## Features

- Lanes and cards you drag and drop
- Cards are plain Markdown files with tags and due dates
- Images in cards
- Light and dark themes (Adwaita, Nord, Catppuccin) and your own CSS
- Installs as a phone or desktop app (PWA)

## How to use

1. Open Tasks.md and add a lane, like To do.
2. Add cards and drag them between lanes.
3. Find the files in AppData/tasks-md/tasks in the Files app.

## Before you install

Tasks.md has no accounts: anyone who can open http://[ZIMAOS-IP-ADDRESS]:7003 can change your boards, so keep it on your home network or put a login in front. It builds its web page each time it starts, so the first page load can take a minute or two. To change the theme, edit custom.css in AppData/tasks-md/config/stylesheets (for example swap adwaita for nord or catppuccin).
