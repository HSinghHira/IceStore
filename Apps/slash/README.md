---
site: https://github.com/yourselfhosted/slash
source: https://github.com/yourselfhosted/slash
screenshots: [Shortcuts, Workspace settings]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: SLASH_DRIVER
    group: Database
    default: "sqlite"
    description: >-
      sqlite keeps the links in the data folder. postgres uses your own PostgreSQL server with SLASH_DSN.
  - name: SLASH_DSN
    group: Database
    default: ""
    description: >-
      PostgreSQL connection string, like postgresql://user:pass@host:5432/slash, when SLASH_DRIVER is postgres.
---

# Slash

Slash turns long addresses into short, easy names like s/handbook, so you and your family or team can share and open links fast. Group links into collections and see how often each one is opened.

## Features

- Short links with your own names
- Tags, collections and full search
- Public, workspace-only or private links
- Visit counts for each link
- Browser extension to open s/name from the address bar

## How to use

1. Open Slash and sign up. The first account becomes the admin.
2. Click Create to make a short link, like handbook.
3. Open it at http://[ZIMAOS-IP-ADDRESS]:6892/s/handbook, or install the browser extension to type s/handbook.

## Before you install

Slash has no default login: the first person to sign up at http://[ZIMAOS-IP-ADDRESS]:6892 becomes the admin, so do it right after installing, then turn off sign-up in the admin settings. The browser extension needs your Slash address and an access token from your Slash settings. SLASH_METRIC is false here, so Slash sends no usage numbers.
