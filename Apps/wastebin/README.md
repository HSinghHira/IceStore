---
site: https://bin.bloerg.net
source: https://github.com/matze/wastebin
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: WASTEBIN_TITLE
    group: Web
    default: "wastebin"
    description: >-
      The page title shown in the browser.
  - name: WASTEBIN_THEME
    group: Web
    default: "ayu"
    description: >-
      Color theme: ayu, base16ocean, catppuccin, coldark, gruvbox, monokai, onehalf, rosepine or solarized.
  - name: WASTEBIN_PASTE_EXPIRATIONS
    group: Pastes
    default: ""
    description: >-
      Expiry choices, comma separated, like 10m,1h,1d=d,1w,0 (=d marks the default, 0 is never).
  - name: WASTEBIN_CACHE_SIZE
    group: Advanced
    default: "128"
    description: >-
      How many rendered pastes to keep in memory.
  - name: WASTEBIN_HTTP_TIMEOUT
    group: Advanced
    default: "5"
    description: >-
      Seconds before a slow request is stopped.
  - name: WASTEBIN_SIGNING_KEY
    group: Advanced
    default: ""
    description: >-
      Key that signs cookies (128+ characters). Leave blank and IceStore makes one.
  - name: WASTEBIN_PASSWORD_SALT
    group: Advanced
    default: ""
    description: >-
      Salt for paste passwords. Leave blank and IceStore makes one; changing it makes old protected pastes unreadable.
---

# wastebin

wastebin is a small, fast pastebin. Paste code or text, pick a language and an expiry time, and share the link. Pastes can be password protected or deleted after the first read.

## Features

- Syntax highlighting for many languages, with nine color themes
- Expiry times and burn after reading
- Optional password per paste, encrypted on the server
- QR codes and raw or download links
- Upload files, or paste from the command line with curl

## How to use

1. Set WASTEBIN_BASE_URL to your ZimaOS IP address.
2. Open wastebin, paste your text and pick the language.
3. Click Paste and share the link.

## Before you install

Change WASTEBIN_BASE_URL first: put your ZimaOS IP address in place of [ZIMAOS-IP-ADDRESS], so QR codes point to http://192.168.1.20:6896 and not a placeholder. wastebin has no accounts, so anyone who can reach it can paste; keep it on your home network or behind a reverse proxy with a login. Upstream makes a new signing key on every start and uses a fixed password salt; this IceStore image makes both once per install and keeps them in the data folder, so you can still delete your own pastes after a restart.
