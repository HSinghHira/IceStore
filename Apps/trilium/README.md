---
site: https://triliumnotes.org/
services:
  - { name: Trilium, path: /, icon: globe }
screenshots: [Notes]
variables:
  - name: TRILIUM_GENERAL_INSTANCENAME
    group: Server
    default: ""
    description: >-
      A name for this server, shown in the app and usable in scripts.
  - name: TRILIUM_NETWORK_TRUSTEDREVERSEPROXY
    group: Server
    default: "false"
    description: >-
      Set to true, or to your reverse proxy's address, when Trilium sits
      behind a reverse proxy, so sign-in limits see the real addresses.
  - name: TRILIUM_SESSION_COOKIEMAXAGE
    group: Sign-in
    default: "1814400"
    description: >-
      How long you stay signed in, in seconds (21 days).
  - name: TRILIUM_GENERAL_NOAUTHENTICATION
    group: Sign-in
    default: "false"
    description: >-
      Set to true to open Trilium without a password. Only for a server
      nobody else can reach.
  - name: TRILIUM_GENERAL_READONLY
    group: Features
    default: "false"
    description: >-
      Set to true to make every note read-only.
  - name: TRILIUM_GENERAL_NOBACKUP
    group: Features
    default: "false"
    description: >-
      Set to true to stop Trilium's own daily, weekly and monthly backups.
  - name: TRILIUM_LOGGING_RETENTIONDAYS
    group: Logs
    default: "90"
    description: >-
      How many days of log files to keep.
---

# Trilium Notes

Trilium Notes keeps all your notes in one deep tree. Write rich text, code, diagrams and maps, link notes together, and find anything with fast search. Use it in the browser, or sync it with the desktop app.

## Features

- Notes in a tree of any depth; one note can sit in several places
- Rich text with tables, images and math, plus Markdown import and export
- Code notes, Mermaid and canvas diagrams, mind maps and maps
- Note history, protected (encrypted) notes and daily backups
- Fast full-text search, tags and attributes
- Sync server for the Trilium desktop apps

## How to use

1. Open Trilium from your dashboard.
2. Pick "I'm a new user" and set your password.
3. Sign in. Right-click a note in the tree to add a note under it.
4. To use the desktop app, pick sync from server and enter this server's address.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6797`, pick "I'm a new user" and set your password; until you do, anyone on your network who opens the page can. The desktop apps can sync with `http://[ZIMAOS-IP-ADDRESS]:6797`. Notes, attachments and Trilium's own backups are in `/DATA/AppData/trilium/data`. A few server settings are in the Variables tab and are added in the app settings; everything else is in Trilium's Options. It is ready in under a minute.
