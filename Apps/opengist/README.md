---
site: https://opengist.io
source: https://github.com/thomiceli/opengist
screenshots: [Dark mode, Light mode]
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Admin panel, path: /admin-panel, icon: grid }
variables:
  - name: OG_EXTERNAL_URL
    group: Server
    default: ""
    description: >-
      Your https address, like https://gist.example.com, when Opengist is
      behind a reverse proxy. Needed for sign-in with GitHub, GitLab, Gitea
      or OIDC.
  - name: OG_LOG_LEVEL
    group: Server
    default: warn
    description: >-
      How much is logged: debug, info, warn, error or fatal.
  - name: OG_SSH_GIT_ENABLED
    group: Git
    default: builtin
    description: >-
      Set to disabled to turn off git over SSH.
  - name: OG_HTTP_GIT_ENABLED
    group: Git
    default: "true"
    description: >-
      Set to false to turn off clone and push over http.
  - name: OG_DISABLE_FILE_UPLOAD
    group: Features
    default: "false"
    description: >-
      Set to true to stop people uploading files into gists.
  - name: OG_DISABLE_COMMENTS
    group: Features
    default: "false"
    description: >-
      Set to true to turn off comments on gists.
  - name: OG_GITHUB_CLIENT_KEY
    group: Sign-in
    default: ""
    description: >-
      A GitHub OAuth app's client ID, to sign in with GitHub (with
      OG_GITHUB_SECRET and OG_EXTERNAL_URL).
  - name: OG_GITHUB_SECRET
    group: Sign-in
    default: ""
    description: >-
      That GitHub OAuth app's client secret.
  - name: OG_OIDC_CLIENT_KEY
    group: Sign-in
    default: ""
    description: >-
      An OpenID Connect client ID (with OG_OIDC_SECRET,
      OG_OIDC_DISCOVERY_URL and OG_EXTERNAL_URL).
  - name: OG_OIDC_SECRET
    group: Sign-in
    default: ""
    description: >-
      That OpenID Connect client's secret.
  - name: OG_OIDC_DISCOVERY_URL
    group: Sign-in
    default: ""
    description: >-
      Your provider's discovery address, ending in
      /.well-known/openid-configuration.
---

# Opengist

Opengist is a place for your code snippets, notes and config files. Every gist is a Git repository, so you can edit it in the page or clone, change and push it with git.

## Features

- Public, unlisted and private gists with several files each
- Syntax highlighting, Markdown and CSV previews
- Full history of every change, likes and forks
- Clone and push over http or SSH
- Search across all gists, topics and an embed code
- Users, admin panel, sign-in with GitHub, GitLab, Gitea or OIDC

## How to use

1. Open Opengist right away and register. The first account is the admin.
2. Press **New**, paste your snippet and save.
3. In the **Admin panel**, turn off sign-ups if only you should have an account.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6815` and register; the first account becomes the admin, and until then anyone on your network can take it. Git over SSH uses port `6816` (`git clone ssh://[ZIMAOS-IP-ADDRESS]:6816/user/gist.git`); add your SSH key in **Settings** first. All settings are listed in the [configuration cheat sheet](https://opengist.io/docs/configuration/cheat-sheet.html); each one can be added in the app settings as an `OG_...` variable.
