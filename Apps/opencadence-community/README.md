---
site: https://opencadence.app
source: https://github.com/OpenCadence/opencadence
services:
  - { name: Workspace, path: /, icon: globe }
screenshots: [Today view]
---

# OpenCadence

OpenCadence is a calm, private workspace for freelancers and independent professionals: clients, leads, projects, tasks, follow-ups and notes in one place, so you always know what needs your attention next. OpenCadence itself has no login, so IceStore puts a password in front of it, made for you on first start.

## Features

- Today view with tasks due or overdue, follow-ups, active projects and recent notes
- Leads and clients with conversations and follow-up reminders
- Projects with their tasks and notes, and progress at a glance
- Search across clients, projects, tasks and notes
- Optional AI assistant through MCP
- One SQLite file, easy to back up

## How to use

1. Open OpenCadence from your dashboard.
2. Type the user name and password from the app log.
3. Choose the example workspace to look around, or start empty.

## Before you install

Leave `PASSWORD` blank to get a random one, shown in the app log in the box marked CREDENTIALS and saved as `icestore-password.txt` in the data folder. Your browser asks for it before OpenCadence opens, from every device, at `http://[ZIMAOS-IP-ADDRESS]:6195`. OpenCadence is for one person: everyone with the password sees the same workspace. There are no other settings.

To make a backup, open the app's terminal in your dashboard and run `node scripts/backup.mjs`; the file lands in `backups/` in the data folder. Upstream has no release tags yet, so this app is built from a fixed commit and is updated in IceStore by hand.
