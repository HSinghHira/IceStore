---
site: https://nexterm.dev/
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Servers, Connections, SFTP, Monitoring]
variables:
  - name: ENCRYPTION_KEY
    group: Server
    default: ""
    description: >-
      The key saved passwords and SSH keys are encrypted with, 64 hex
      characters. It is made on first start and kept in
      /app/data/secrets.env. Only set it to move an old install.
  - name: LOG_LEVEL
    group: Server
    default: "system"
    description: >-
      How much goes in the log: system, info, verbose, debug, warn or error.
  - name: TRUST_PROXY
    group: Server
    default: ""
    description: >-
      Set to 1 when one reverse proxy is in front of Nexterm, so logs show
      the real visitor address.
  - name: SOURCES_ALLOWED_HOSTS
    group: Server
    default: ""
    description: >-
      Hosts on your own network that custom script sources may be loaded
      from, comma separated, like git.example.lan,10.0.0.5.
  - name: AI_SYSTEM_PROMPT
    group: AI assistant
    default: ""
    description: >-
      Extra instructions for the AI assistant, like "Always explain
      destructive commands before running them".
---

# Nexterm

Nexterm opens your servers and computers in a browser tab: SSH terminals, remote desktops over VNC and RDP, and file transfers over SFTP. Keep all your servers, logins and keys in one place, encrypted with this install's own key.

## Features

- SSH terminals, VNC and RDP desktops in the browser
- SFTP file browser with upload and download
- Servers sorted in folders, with saved logins and SSH keys
- Snippets you can run on many servers at once
- Server monitoring and session recordings
- Users, two-step sign-in and single sign-on (OIDC, LDAP)

## How to use

1. Open Nexterm from your dashboard.
2. Make the admin account on the first page.
3. Click Add Server and fill in the address and how to sign in.
4. Click the server to open a terminal, desktop or file browser.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6777`. There is no account yet: the first page asks you to make the admin account. The encryption key for your saved logins is made on first start and kept in `/DATA/AppData/nexterm/data/secrets.env`, so back up that folder as a whole. Single sign-on is set up in Nexterm's own settings; the few other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
