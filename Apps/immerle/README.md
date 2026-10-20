---
site: https://immerle.com/
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: ADMIN_USERNAME
    group: Sign-up and accounts
    default: ""
    description: >-
      Makes an admin account with this name on first start, instead of the
      setup screen. Set it together with ADMIN_PASSWORD. Only used when no
      accounts exist yet.
  - name: ADMIN_PASSWORD
    group: Sign-up and accounts
    default: ""
    description: >-
      The password for the admin account made from ADMIN_USERNAME.
  - name: AUTH_REQUIRE_SETUP_TOKEN
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to ask for a one-time token before the first admin account
      is made. The token shows in the app log.
  - name: AUTH_SECRET
    group: Sign-up and accounts
    default: ""
    description: >-
      The secret used to sign logins. Leave it out and Immerle makes a random
      one on first start and keeps it.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much Immerle writes to its log. One of debug, info, warn or error.
---

# Immerle

A self-hosted music server with its own web app that also speaks Subsonic and OpenSubsonic, so clients like Supersonic, Symfonium and DSub just work.

## Features

- Browse, search, stream and transcode your own music library
- Works with Subsonic and OpenSubsonic clients, with scrobbling and now-playing
- Playlists, collaborative playlists and an activity feed with per-event privacy
- Jam sessions to listen together, in sync
- On-demand catalog providers, like Jamendo and the Internet Archive
- Playlist import, discovery mixes, internet radio and podcasts
- One small Go server with SQLite, no extra database needed

## How to use

1. Put your music in the Music folder inside Media on your server.
2. Open Immerle from your dashboard.
3. Create your admin account on the setup screen.
4. Play music from the web app, or sign in from a Subsonic client using your server's IP address and port 6108.
5. Change library, provider and transcoding settings in the admin area of the app.

## Before you install

Copy your music into `/DATA/Media/Music` first. Immerle reads it read-only and never changes your files. Create your admin account right after install, because until you do, anyone on your network could make it. To lock that down, add `AUTH_REQUIRE_SETUP_TOKEN` or `ADMIN_USERNAME` and `ADMIN_PASSWORD` from the Variables tab in the app settings.
