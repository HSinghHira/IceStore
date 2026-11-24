---
site: https://freshrss.org
source: https://github.com/FreshRSS/FreshRSS
services:
  - { name: Reader, path: /, icon: globe }
  - { name: Reader-app API, path: /api/, icon: plug }
variables:
  - name: TRUSTED_PROXY
    group: Network
    default: ""
    description: >-
      Your reverse proxy's IP addresses or ranges, space separated, so the
      real visitor IP is logged. Set to 0 to trust none.
  - name: INTERNAL_HOST_ALLOWLIST
    group: Network
    default: ""
    description: >-
      Hosts on your network that feeds may come from, space separated, like
      192.168.1.20:1200 for an RSSHub on your ZimaOS. Other internal
      addresses are blocked.
  - name: OIDC_ENABLED
    group: Single sign-on
    default: ""
    description: >-
      Set to 1 to sign in with OpenID Connect; it needs the OIDC_* settings
      from the FreshRSS OpenID Connect guide.
  - name: FRESHRSS_ENV
    group: Server
    default: production
    description: >-
      Set to development for more detailed logs and error messages.
  - name: ENABLE_ACCESS_LOG
    group: Server
    default: "1"
    description: >-
      Set to empty to stop logging every web request.
---

# FreshRSS

FreshRSS collects the news from your favourite websites in one place. It checks your feeds on its own, keeps what you have read in sync across devices and works with many phone and desktop reader apps.

## Features

- RSS and Atom feeds, plus web pages watched with XPath or CSS
- Categories, labels, favourites and powerful filters
- Several users, each with their own feeds
- Google Reader and Fever API for apps like NetNewsWire, Reeder, FeedMe and Readrops
- Extensions and themes
- Import and export your feeds as OPML

## How to use

1. Open FreshRSS right away and follow the install steps. Pick **SQLite** and make your admin account.
2. Add feeds with the **+** button, or import an OPML file.
3. For phone apps, turn on API access in **Settings → Authentication**, set an API password in your **Profile**, and use `http://[ZIMAOS-IP-ADDRESS]:6813/api/greader.php` as the server.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6813` and finish the install steps; until you do, anyone on your network can. SQLite needs no extra database. Feeds refresh at minutes 3 and 33 of every hour; change `CRON_MIN` to refresh more or less often. By default FreshRSS refuses feeds on your own network: list them in `INTERNAL_HOST_ALLOWLIST` (Variables tab).
