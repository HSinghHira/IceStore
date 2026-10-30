---
site: https://github.com/TimWitzdam/GitSave
services:
  - { name: Web App, path: /, icon: globe }
  - { name: First Setup, path: /setup, icon: plus-circle }
screenshots: [Schedules, Overview, History]
variables:
  - name: DISABLE_AUTH
    group: Sign-in
    default: "false"
    description: >-
      Set to true to turn off sign-in. Only do this when GitSave sits behind
      another login.
  - name: JWT_SECRET
    group: Secrets
    default: ""
    description: >-
      Your own sign-in key. Leave it out: each install makes its own on first
      start and keeps it in the data folder as .jwt_secret. Changing it signs
      everyone out.
  - name: ENCRYPTION_SECRET
    group: Secrets
    default: ""
    description: >-
      Your own key for saved access tokens, exactly 32 characters. Leave it
      out: each install makes its own on first start and keeps it in the data
      folder as .encryption_secret. Never change it afterwards, or saved
      tokens can't be read.
  - name: GIT_TIMEOUT
    group: Backups
    default: "15000"
    description: >-
      How long a git command may run before it is stopped, in milliseconds.
---

# GitSave

GitSave keeps backups of your own and your favourite Git repositories. Add a repository, pick how often to back it up and how many copies to keep, and GitSave makes a full mirror clone on that schedule. Every install makes its own secret keys on first start.

## Features

- A simple web page that works on phones too
- Backups on a schedule, with the number of copies to keep
- GitHub, GitLab and any other Git host, with access tokens for private repositories
- Pause and resume schedules
- A history of every backup run
- Back up to the backups folder or to an SMB share

## How to use

1. Open GitSave at `http://[ZIMAOS-IP-ADDRESS]:6181`.
2. Make your account on the first page you see.
3. For private repositories, add an access token under Settings.
4. Open Schedules and add a repository, how often to back it up and how many copies to keep.
5. The backups are in the backups folder of the app, or on your SMB share if you picked one under Settings.

## Before you install

There is nothing to set first: `JWT_SECRET` and `ENCRYPTION_SECRET` are made on first start and kept in the data folder, so back that folder up. The first start takes about a minute. Then open `http://[ZIMAOS-IP-ADDRESS]:6181` and make your account. GitSave only runs on amd64 (Intel and AMD) machines. The other settings are in the Variables tab; add them in the app settings.
