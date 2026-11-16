---
site: https://changedetection.io
source: https://github.com/dgtlmoon/changedetection.io
screenshots: [Watch list, What changed, Restock and price]
variables:
  - name: FETCH_WORKERS
    group: Checks
    default: "10"
    description: >-
      How many pages are checked at the same time.
  - name: MINIMUM_SECONDS_RECHECK_TIME
    group: Checks
    default: "3"
    description: >-
      The shortest time between two checks of a page, in seconds, whatever a watch says.
  - name: PAGE_WATCH_LIMIT
    group: Checks
    default: ""
    description: >-
      The most watches this install may hold. Leave it out for no limit.
  - name: HIDE_REFERER
    group: Checks
    default: "false"
    description: >-
      Set to true so the sites you watch can't see where the request came from.
  - name: PLAYWRIGHT_DRIVER_URL
    group: Browser for JavaScript pages
    default: ""
    description: >-
      The address of a Playwright Chrome (like the sockpuppetbrowser image), like ws://192.168.1.20:3000. Needed for pages that only work with JavaScript, and for screenshots.
  - name: HTTP_PROXY
    group: Proxy
    default: ""
    description: >-
      A proxy for http pages, like socks5h://192.168.1.5:1080.
  - name: HTTPS_PROXY
    group: Proxy
    default: ""
    description: >-
      A proxy for https pages.
  - name: NO_PROXY
    group: Proxy
    default: ""
    description: >-
      Addresses that skip the proxy, comma separated, like localhost,192.168.0.0/24.
  - name: ALLOW_IANA_RESTRICTED_ADDRESSES
    group: Proxy
    default: "false"
    description: >-
      Set to true to let watches check pages on your own network (192.168.x.x and similar).
  - name: USE_X_SETTINGS
    group: Server
    default: ""
    description: >-
      Set to 1 when a reverse proxy sends X-Forwarded headers.
  - name: DISABLE_VERSION_CHECK
    group: Server
    default: "false"
    description: >-
      Set to true to stop checking for new versions.
  - name: LLM_FEATURES_DISABLED
    group: AI
    default: "false"
    description: >-
      Set to true to hide all AI features.
  - name: LOGGER_LEVEL
    group: Logs
    default: "DEBUG"
    description: >-
      TRACE, DEBUG, INFO, SUCCESS, WARNING, ERROR or CRITICAL.
---

# changedetection.io

changedetection.io checks web pages on a schedule and tells you when something changes: a new job post, a price drop, an item back in stock, an update to a document. You pick which part of the page to watch, and get alerts by email, Discord, Telegram, ntfy, Gotify and many more.

## Features

- Watch whole pages or just one part, with CSS, XPath or JSON filters
- Price and restock tracking for shops
- See exactly what changed, side by side
- Alerts to over 80 services through Apprise
- Check schedules per watch, tags and groups
- Optional password, API and browser extension

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6734` in your browser.
2. Paste a web address and press Watch.
3. Open Settings, Notifications to add where alerts should go.
4. Set a password under Settings, General if others can reach the page.

## Before you install

For working links in alerts, change `[ZIMAOS-IP-ADDRESS]` in `BASE_URL` to your ZimaOS IP, like `http://192.168.1.20:6734`; the app works without it. There is no password at first: set one in Settings, General. Pages are fetched without a browser, which is fast and works for most sites; for pages that need JavaScript, run a Playwright Chrome and set `PLAYWRIGHT_DRIVER_URL`. Proxies and the other settings are in the Variables tab; add them in the app settings.
