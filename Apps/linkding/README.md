---
site: https://linkding.link
source: https://github.com/sissbruecker/linkding
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: LD_SUPERUSER_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The first admin password. Made on first start when left out. Only
      used when the admin account is created; later changes go in the
      app's Settings.
  - name: LD_ENABLE_OIDC
    group: Sign-in
    default: "False"
    description: >-
      Set to True to sign in with OpenID Connect (also needs the OIDC_*
      settings from the linkding docs).
  - name: LD_DISABLE_LOGIN_FORM
    group: Sign-in
    default: "False"
    description: >-
      Set to True to hide the user name and password form when you only
      use OIDC.
  - name: LD_ENABLE_AUTH_PROXY
    group: Sign-in
    default: "False"
    description: >-
      Set to True to trust a user name header from your reverse proxy.
  - name: LD_CSRF_TRUSTED_ORIGINS
    group: Network
    default: ""
    description: >-
      Your https address, like https://links.example.com, when linkding
      is behind a reverse proxy that changes the Host header.
  - name: LD_CONTEXT_PATH
    group: Network
    default: ""
    description: >-
      Serve linkding under a sub-path, like bookmarks/ (with the
      trailing slash).
  - name: LD_FAVICON_PROVIDER
    group: Features
    default: ""
    description: >-
      Where favicons come from, like
      https://icons.duckduckgo.com/ip3/{domain}.ico.
  - name: LD_DISABLE_BACKGROUND_TASKS
    group: Features
    default: "False"
    description: >-
      Set to True to stop fetching favicons
  - name: LD_SINGLEFILE_TIMEOUT_SEC
    group: Features
    default: "120"
    description: >-
      How long saving a full copy of one page may take
---

# linkding

linkding saves and organizes your bookmarks. Add tags and notes, search everything in a moment, archive pages so they never disappear, and save links from any browser with its extension or bookmarklet.

## Features

- Fast search across titles, descriptions, notes and tags
- Browser extensions for Firefox and Chrome, and a bookmarklet
- Saves a full copy of each page (HTML snapshot) or uses the Internet Archive
- Read-it-later list, bundles and shared bookmarks for other users
- Import and export in the Netscape HTML format, and a REST API
- Several users, with sign-in through OIDC if you want

## How to use

1. Open linkding and sign in as admin with the password from the CREDENTIALS box in the app's logs.
2. Install the browser extension or drag the bookmarklet from Settings, Integrations.
3. Save a link, add tags, and find it again with the search box.

## Before you install

The admin account is made on first start; its password is shown in the app's logs, in the box marked CREDENTIALS, and kept in /DATA/AppData/linkding/data. To choose it yourself, add LD_SUPERUSER_PASSWORD in the app settings before the first start. Sign-in with OIDC, a reverse proxy and other options are in the Variables tab.
