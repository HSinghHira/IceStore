---
site: https://about.gitea.com/
services:
  - { name: Gitea, path: /, icon: globe }
  - { name: API, path: /api/swagger, icon: code }
screenshots: [Dashboard, Issues, Pull requests, Explore]
variables:
  - name: GITEA__server__ROOT_URL
    group: Server
    default: ""
    description: >-
      The address people open Gitea at, like
      http://[ZIMAOS-IP-ADDRESS]:6795/ or https://git.example.com/. Used in
      clone links and emails. The setup page sets it too.
  - name: GITEA__server__DOMAIN
    group: Server
    default: ""
    description: >-
      The host name or IP shown in clone links, like 192.168.1.20 or
      git.example.com.
  - name: GITEA__service__DISABLE_REGISTRATION
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so only the admin can make new accounts.
  - name: GITEA__service__REQUIRE_SIGNIN_VIEW
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so people must sign in to see any page.
  - name: GITEA__mailer__ENABLED
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to send emails (sign-up confirmation, notifications).
  - name: GITEA__mailer__PROTOCOL
    group: Email (SMTP)
    default: ""
    description: >-
      smtp, smtps or smtp+starttls.
  - name: GITEA__mailer__SMTP_ADDR
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com.
  - name: GITEA__mailer__SMTP_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server's port, like 465 or 587.
  - name: GITEA__mailer__USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: GITEA__mailer__PASSWD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: GITEA__mailer__FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address, like Gitea <git@example.com>.
  - name: GITEA__actions__ENABLED
    group: Features
    default: "true"
    description: >-
      Set to false to turn off Gitea Actions. Running jobs needs a separate
      act_runner.
  - name: GITEA__log__LEVEL
    group: Logs
    default: "Info"
    description: >-
      How much Gitea writes to the log: Trace, Debug, Info, Warn or Error.
---

# Gitea

Gitea is a light Git server for you or your team. Keep your code at home with pull requests, issues, a wiki, package registries and GitHub-style Actions, in one small app.

## Features

- Git over HTTP and SSH, with LFS
- Pull requests with code review, issues, milestones and projects
- Gitea Actions, compatible with GitHub Actions workflows
- Package registry for Docker, npm, PyPI, Maven and more
- Mirror repositories from GitHub and other sites
- Organizations, teams, wikis and webhooks

## How to use

1. Open Gitea from your dashboard. You see the setup page first.
2. Keep SQLite as the database. Check the Server Domain and Gitea Base URL show your ZimaOS address.
3. Open Administrator Account Settings at the bottom, make the admin and click Install Gitea.
4. Click + and New Repository, then push your code.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6795` and fill in the setup page; until you do, anyone on your network can. Keep SQLite, set Server Domain to your ZimaOS IP and Gitea Base URL to `http://[ZIMAOS-IP-ADDRESS]:6795/` so clone links work, and make the admin account at the bottom. Git over SSH is on port 6796 (`ssh://git@[ZIMAOS-IP-ADDRESS]:6796/user/repo.git`). Gitea makes its own secret keys and keeps everything in `/DATA/AppData/gitea/data`. Sign-up, email and other settings are in the Variables tab and are added in the app settings; any `GITEA__section__KEY` setting from Gitea's config cheat sheet works the same way. Gitea Actions needs a separate runner (act_runner). It is ready in under a minute.
