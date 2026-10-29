---
site: https://monolith-site-maxjafars-projects.vercel.app
services:
  - { name: Workspace, path: /, icon: globe }
  - { name: API Reference, path: /api/v1/openapi.json, icon: code }
screenshots: [Workspace, Dashboard widgets, Project board, Inline databases, Add-ons and widgets]
variables:
  - name: SERVER_NAME
    group: Server
    default: monolith
    description: >-
      The server's name, shown to desktop apps that connect to it.
  - name: FILE_UPLOAD_MAX_BYTES
    group: Server
    default: "2147483648"
    description: >-
      The largest file that can be uploaded, in bytes (2 GB by default).
  - name: MONOLITH_AUTH_ADMIN_IDS
    group: Admins
    default: ""
    description: >-
      Account IDs (UUIDs), separated by commas, that may change the server's
      sign-in providers.
  - name: MONOLITH_ADDON_ADMIN_IDS
    group: Admins
    default: ""
    description: >-
      Account IDs (UUIDs), separated by commas, that may install and remove
      add-ons on this server.
  - name: BOOTSTRAP_TOKEN
    group: Admins
    default: ""
    description: >-
      A long random token that lets a desktop app create the first account.
      Leave it out to create the first account in the browser.
  - name: MONOLITH_CORE_ONLY
    group: Add-ons
    default: "0"
    description: >-
      Set to 1 to load only the core features and download add-ons from the
      catalog instead of using the ones built in.
  - name: MONOLITH_ADDON_CATALOG_URL
    group: Add-ons
    default: ""
    description: >-
      Your own add-on catalog address. Leave it out to use the official one.
  - name: MONOLITH_ADDON_CATALOG_PUBLIC_KEY
    group: Add-ons
    default: ""
    description: >-
      The public key your own catalog is signed with.
  - name: ROOMS_TURN_URLS
    group: Rooms (calls)
    default: ""
    description: >-
      Your own TURN relay for calls in Rooms, like turn:turn.example.com:3478.
      No public relay is used by default.
  - name: ROOMS_TURN_SECRET
    group: Rooms (calls)
    default: ""
    description: >-
      The shared secret of that TURN relay.
---

# Monolith

Monolith brings your pages, projects and everyday tools into one self-hosted workspace. Write documents, organize records, plan projects and build a dashboard around what matters to you. This is Monolith in a single container, with its API, gateway, web app and PostgreSQL inside, one port and one data folder. Secret keys are made for you on first start.

## Features

- Docs: nested pages, rich blocks, references, backlinks and inline databases
- Databases with typed properties, relations, filters and table, board and calendar views
- Projects in boards, lists, timelines and Gantt; Actions for Today and Upcoming
- Calendar, Rooms for workspace chat, and a dashboard of widgets
- Workspaces with owner, editor and viewer roles
- Optional add-ons (Atlas, Automations, Agents, Redraw, Gym, Tech Lab) and MCP/CLI for AI agents
- Web app, plus Windows and macOS desktop apps
- PostgreSQL inside

## How to use

1. Monolith needs an https address to sign in from other devices. Put it behind a reverse proxy (or Tailscale) and set `PUBLIC_URL` to that address. On the ZimaOS box itself, `http://localhost:6138` works.
2. Open your `PUBLIC_URL` address.
3. Create your account. The first account is the owner.
4. Make your first page, project or database.

## Before you install

**Monolith only signs you in on an https address.** Make one with a reverse proxy (like Nginx Proxy Manager or Caddy) or Tailscale, pointed at `http://[ZIMAOS-IP-ADDRESS]:6138`, and set `PUBLIC_URL` to it, like `https://monolith.example.com`. Without it, Monolith only works in a browser on the ZimaOS box itself at `http://localhost:6138`; any other address shows a note saying what to do. There is no default password: create your account right after the first start, since the first account becomes the owner. The image is amd64 only for now. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. The first start takes 2 to 5 minutes.
