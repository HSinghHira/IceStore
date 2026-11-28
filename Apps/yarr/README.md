---
site: https://github.com/nkanaev/yarr
source: https://github.com/nkanaev/yarr
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: YARR_BASE
    group: Web
    default: ""
    description: >-
      Serve yarr under a sub path, like /yarr, when it sits behind a reverse proxy.
  - name: YARR_CLIENT_TIMEOUT
    group: Feeds
    default: "30s"
    description: >-
      How long yarr waits for a feed site to answer.
  - name: YARR_AUTHFILE
    group: Sign-in
    default: ""
    description: >-
      Path to a file holding username:password, instead of YARR_AUTH. Needs https too.
  - name: YARR_LOGFILE
    group: Advanced
    default: ""
    description: >-
      Write the log to this file as well, like /data/yarr.log.
---

# yarr

yarr (yet another rss reader) is a small web feed reader in one program. It keeps everything in one SQLite file and shows your feeds, the article list and the article side by side.

## Features

- RSS, Atom and JSON Feed, with folders
- Import and export OPML
- Full-text view for short feeds
- Keyboard shortcuts and a light, sepia and dark theme
- Fever API for phone apps like Reeder (needs a login)

## How to use

1. Open yarr.
2. Click the plus button to add a feed, or import an OPML file from the menu.

## Before you install

yarr starts with no login, and anyone on your network who opens http://[ZIMAOS-IP-ADDRESS]:6885 can read and change your feeds, so keep it off the internet. yarr's login (YARR_AUTH=username:password) sets a cookie that browsers only keep over https, so it only works when yarr sits behind a reverse proxy or tunnel with your own domain. The Fever API for phone apps also needs YARR_AUTH set.
