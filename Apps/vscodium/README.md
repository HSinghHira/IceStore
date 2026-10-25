---
name: VSCodium
site: https://vscodium.com/
source: https://github.com/linuxserver/docker-vscodium-web
services:
  - { name: "VSCodium (add ?tkn=your-token)", path: /, icon: code }
screenshots: [Editor]
variables:
  - name: SUDO_PASSWORD
    group: Terminal
    default: ""
    description: >-
      A password for sudo in the built-in terminal. Leave it out and the
      terminal has no sudo.
  - name: SUDO_PASSWORD_HASH
    group: Terminal
    default: ""
    description: >-
      The sudo password as a hash, like $6$salt$hash, instead of plain text.
      It wins over SUDO_PASSWORD.
  - name: CONNECTION_TOKEN_FILE
    group: Access
    default: ""
    description: >-
      A file inside the container that holds the connection token, like
      /config/my-token.txt. It wins over CONNECTION_TOKEN and the token made
      on first start.
  - name: CODE_ARGS
    group: Editor
    default: ""
    description: >-
      Extra command line options for the VSCodium server. Leave it out unless
      you know you need one.
  - name: UMASK
    group: Files
    default: "022"
    description: >-
      The umask for new files, like 002 so your group can write them too.
---

# VSCodium

VSCodium is the community build of Microsoft's VS Code editor, with no tracking and a free license. This app runs its web server, so the editor loads straight into a browser tab, without a remote desktop in the way. Every install makes its own connection token, so nobody else on your network can open your editor.

## Features

- The real VSCodium editor, running in your browser
- Built-in terminal, with optional sudo
- Extensions from the Open VSX marketplace
- Put an SSH key in `.ssh` for git over SSH
- Settings, extensions and projects survive restarts and updates

## How to use

1. Find your connection token in the app log, on the line that says "open VSCodium at", or in `connection-token.txt` in the app folder.
2. Open `http://your-zimaos-ip:6160/?tkn=your-token` in your browser.
3. Open a folder, install extensions and use the terminal as usual.
4. Keep your projects in the home folder so they are saved.

## Before you install

You don't need to change anything. Leave `CONNECTION_TOKEN` blank and the app makes a random token on first start; it is in the app log on the line that says "open VSCodium at", and in `/DATA/AppData/vscodium/connection-token.txt`. Or type your own token. Opening the app without `?tkn=your-token` at the end of the address shows "Forbidden", so bookmark the full address. A sudo password for the terminal and the other settings are in the Variables tab; add them in the app settings.
