---
site: https://waddington.github.io/job-application-tracker/
source: https://github.com/waddington/job-application-tracker
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API Docs, path: /api/docs, icon: code }
screenshots: [Today, Kanban board, Insights, Timeline, Offers compared]
variables:
  - name: JAT_GIT_SNAPSHOTS
    group: Backups
    default: "true"
    description: >-
      Set to false before the first start so the data folder is not made a
      git repo. Snapshots then stop; a folder that is already a repo is left
      alone.
  - name: JAT_GIT_NAME
    group: Backups
    default: Job Application Tracker
    description: >-
      The author name on the snapshot commits.
  - name: JAT_GIT_EMAIL
    group: Backups
    default: jat@localhost
    description: >-
      The author email on the snapshot commits.
---

# Job Application Tracker

Job Application Tracker is a self-hosted tracker for a job search, made for the way tech hiring works: recruiters with several roles, multi-stage interviews and things that go quiet. No account, no cloud, no AI and no tracking. Your data is a folder of SQLite, JSON Lines and Markdown, with automatic git snapshots.

## Features

- Today page: replies to read, follow-ups due, what's coming up and who you're waiting on
- Kanban board with configurable stages, interview rounds and full timestamped history
- Recruiter CRM: agencies, people, calls and the roles they pitch
- Notes, links, files, exported emails and CV versions on every application
- Sankey diagram, conversion per stage, recruiter scorecard and an A/B test of your CVs
- Offers side by side, a timeline of everything and search across it all
- Automatic git snapshots and a one-click backup zip

## How to use

1. Open Job Application Tracker from your dashboard.
2. Press New application (top right) and type the company and role.
3. Drag it across the board as it moves along.
4. Check the Today page each day for what needs you.

## Before you install

Nothing has to be set. Upstream publishes no Docker image, so IceStore builds one from the v1.1.0 release. There is no login: anyone who can open `http://[ZIMAOS-IP-ADDRESS]:6172` sees your job search, so keep it on your home network or put it behind a reverse proxy with a password. It is a tool for one person. On first start the data folder becomes a git repo and every burst of changes is committed as a readable snapshot; *Download a backup* in the sidebar gives you one zip of everything. Every other setting is optional and listed in the Variables tab; to use one, add it in the app settings. It is ready about half a minute after install.
