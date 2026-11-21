---
site: https://www.notediscovery.com/
services:
  - { name: Web app, path: /, icon: globe }
  - { name: API docs, path: /docs, icon: code }
screenshots: [Notes, Graph, Editor]
variables:
  - name: AUTHENTICATION_ENABLED
    group: Sign-in
    default: "true"
    description: >-
      Set to false to turn the login off. Only do this behind another
      sign-in.
  - name: AUTHENTICATION_SECRET_KEY
    group: Sign-in
    default: ""
    description: >-
      The key sessions are signed with. It is made on first start and kept in
      /app/data/.icestore.
  - name: APP_NAME
    group: Look
    default: "NoteDiscovery"
    description: >-
      The name shown in the app, on the login page and in the browser tab.
  - name: DEFAULT_THEME
    group: Look
    default: "light"
    description: >-
      The theme for new browsers, like light or dark.
  - name: AUTOSAVE_DELAY_MS
    group: Look
    default: "1000"
    description: >-
      How long to wait after typing before saving, in milliseconds.
  - name: SHARE_PUBLIC_ORIGIN
    group: Sharing
    default: ""
    description: >-
      The address used in share links, like https://notes.example.com.
      Leave it out to use the address in your browser.
---

# NoteDiscovery

NoteDiscovery is a fast note app for your own server. Notes are plain Markdown files in folders, so nothing is locked in. Link notes together, see them on a graph, search everything at once, and share a single note by link.

## Features

- Markdown notes with live preview, math and diagrams
- Links between notes, backlinks and a graph view
- Instant search across all your notes
- Folders, tags, templates and drawings
- Share a note by link, and many themes
- Plain files you can back up or open in any editor

## How to use

1. Open NoteDiscovery from your dashboard.
2. Sign in with the password from the app's logs (the box marked CREDENTIALS).
3. Click New Note and start writing.
4. Type [[ to link to another note, and open the graph to see how they connect.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6788`. The login is on, with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/notediscovery/data/.icestore/password` (upstream ships the login off with the password `admin`). Set `AUTHENTICATION_PASSWORD` to pick your own. Your notes are plain Markdown files in `/DATA/AppData/notediscovery/data`. The other settings are in the Variables tab and are added in the app settings. It is ready in under a minute.
