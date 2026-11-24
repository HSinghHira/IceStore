---
site: https://b3log.org/siyuan/en/
source: https://github.com/siyuan-note/siyuan
services:
  - { name: Notes, path: /, icon: globe }
variables:
  - name: SIYUAN_ACCESS_AUTH_CODE
    group: Sign-in
    default: ""
    description: >-
      The access code (lock screen password). Made on first start and kept
      in .icestore-access-code in the workspace when left out.
  - name: SIYUAN_ACCESS_AUTH_CODE_BYPASS
    group: Sign-in
    default: ""
    description: >-
      Set to true to open SiYuan without any access code. Anyone on your
      network can then read your notes.
  - name: SIYUAN_OIDC_ENABLED
    group: Single sign-on
    default: ""
    description: >-
      Set to true to sign in with an OpenID Connect provider instead of the
      access code.
  - name: SIYUAN_OIDC_PROVIDER
    group: Single sign-on
    default: ""
    description: >-
      custom, google, microsoft or github.
  - name: SIYUAN_OIDC_CLIENT_ID
    group: Single sign-on
    default: ""
    description: >-
      The client ID from your provider.
  - name: SIYUAN_OIDC_CLIENT_SECRET
    group: Single sign-on
    default: ""
    description: >-
      The client secret from your provider (required for GitHub).
  - name: SIYUAN_OIDC_ISSUER_URL
    group: Single sign-on
    default: ""
    description: >-
      The issuer address, for custom and microsoft providers.
  - name: SIYUAN_OIDC_SCOPES
    group: Single sign-on
    default: ""
    description: >-
      Extra scopes, comma separated; openid is always included.
  - name: SIYUAN_OIDC_REDIRECT_URL
    group: Single sign-on
    default: ""
    description: >-
      Your https address followed by /api/system/oidc/callback, like
      https://notes.example.com/api/system/oidc/callback.
  - name: SIYUAN_OIDC_ALLOW_ALL
    group: Single sign-on
    default: ""
    description: >-
      Set to true to let everyone your provider signs in use SiYuan.
  - name: SIYUAN_OIDC_CLAIM_RULES
    group: Single sign-on
    default: ""
    description: >-
      Who may sign in, as JSON, like
      [{"claim":"email","operator":"equals","values":["you@example.com"]}].
---

# SiYuan

SiYuan is a note-taking app and personal knowledge base. Every paragraph is a block you can link to, embed and search, and your notes stay on your ZimaOS in plain files.

## Features

- Block editor with Markdown, tables, math, diagrams and code
- Links and backlinks between any blocks, with a graph view
- Embedded queries, database views and flashcards
- Full-text search, tags and history
- Export to Markdown, PDF, Word and HTML

## How to use

1. Open SiYuan and type the access code from the CREDENTIALS box in the app's logs.
2. Make a notebook and start writing.

## Before you install

The access code is made on first start and shown in the app's logs, in the box marked CREDENTIALS; it is kept in `/DATA/AppData/siyuan/workspace/.icestore-access-code`. To pick your own, add `SIYUAN_ACCESS_AUTH_CODE` in the app settings. `SIYUAN_LANG=en` sets the language on every start: remove it to keep the language you choose in **Settings**. Your notes are in `/DATA/AppData/siyuan/workspace`; back that folder up.
