---
name: MindSift
site: https://mindsift.app/en/
source: https://github.com/mindsift-app/mindsift
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Triage, Workspace, Focus, Journal]
variables:
  - name: REGISTRATION_MODE
    group: Sign-up and accounts
    default: ""
    description: >-
      Who may sign up: approval, domain, domain+approval or open. Left out,
      the admin chooses in the settings.
  - name: REGISTRATION_DOMAINS
    group: Sign-up and accounts
    default: ""
    description: >-
      Email domains for the domain modes, like company.com, family.org.
  - name: REGISTRATION_VERIFY_EMAIL
    group: Sign-up and accounts
    default: ""
    description: >-
      Set to true so new accounts confirm their email first (needs email).
  - name: DEFAULT_LANGUAGE
    group: Sign-up and accounts
    default: ""
    description: >-
      The language for new users, like en or de.
  - name: TRUSTED_PROXIES
    group: Server
    default: private
    description: >-
      Proxies whose forwarded client address is believed.
  - name: LOGIN_PROTECTION
    group: Server
    default: "true"
    description: >-
      Slows down repeated failed logins. Set to false to turn it off.
  - name: LOG_LEVEL
    group: Server
    default: info
    description: >-
      debug, info, warn or error.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for password resets, invitations and digests.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port.
  - name: SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: SMTP_PASS
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The address email comes from.
  - name: SMTP_TLS
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false for a mail server without TLS.
  - name: STT_URL
    group: Voice input
    default: ""
    description: >-
      A Whisper server (faster-whisper or speaches), like
      http://192.168.1.20:8000, for voice input on the server.
  - name: STT_MODEL
    group: Voice input
    default: deepdml/faster-whisper-large-v3-turbo-ct2
    description: >-
      The Whisper model the server uses.
  - name: STT_DISABLED
    group: Voice input
    default: "false"
    description: >-
      Set to true to turn voice input off.
  - name: MEDIA_MAX_IMAGE_MB
    group: Media
    default: "15"
    description: >-
      The largest image upload, in MB.
  - name: MEDIA_QUOTA_MB
    group: Media
    default: "0"
    description: >-
      Upload space per user in MB; 0 means no limit.
  - name: SECRETS_KEY
    group: Keys
    default: ""
    description: >-
      The key for hidden values in notes. Made on first start and kept in
      secrets.key when left out; never change it once values are stored.
---

# MindSift

MindSift is a self-hosted home for notes, tasks and shared lists: catch a thought in a second, sort it later, and work on it together live. One Go program with one SQLite file.

## Features

- Quick capture and a triage inbox
- Live outliner, kanban boards, a journal and a focus view
- Shared lists and workspaces, live collaboration, invite codes and organizations
- Voice input (optional Whisper server), reminders and email digests
- MCP server for AI agents, automatic backups and restore

## How to use

1. Set `BASE_URL` to your ZimaOS IP before you install.
2. Open MindSift right after the first start and create the admin account in the setup wizard.
3. Capture notes and tasks, then sort them into workspaces.
4. Invite others with invite codes from the admin settings.

## Before you install

**You must set `BASE_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6710`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6710`. Live updates only work from this address.

The first person to open MindSift creates the admin account in its setup wizard, so open it right after installing. Its sign-in and encryption keys are made on first start and kept in the data folder. More settings (sign-up, email, voice input) are in the Variables tab. The image is built for amd64 only.
