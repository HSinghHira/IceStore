---
site: https://gethomepage.dev
source: https://github.com/gethomepage/homepage
screenshots: [Dashboard, Sections]
variables:
  - name: HOMEPAGE_AUTH_ENABLED
    group: Login
    default: "false"
    description: >-
      Set to true to put a login in front of Homepage. Also set HOMEPAGE_AUTH_SECRET, HOMEPAGE_EXTERNAL_URL and a password or OIDC.
  - name: HOMEPAGE_AUTH_SECRET
    group: Login
    default: ""
    description: >-
      A random string of 32 or more characters that signs the login cookie. Make your own; don't copy one from the web.
  - name: HOMEPAGE_EXTERNAL_URL
    group: Login
    default: ""
    description: >-
      The address you open Homepage at, like http://192.168.1.20:6733.
  - name: HOMEPAGE_AUTH_PASSWORD
    group: Login
    default: ""
    description: >-
      The password for the login page.
  - name: HOMEPAGE_OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      Your OIDC provider's issuer address. With this set, OIDC replaces the password login.
  - name: HOMEPAGE_OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your provider. The callback address is your Homepage address plus /api/auth/callback/homepage-oidc.
  - name: HOMEPAGE_OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your provider.
  - name: HOMEPAGE_OIDC_NAME
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider name shown on the sign-in button.
  - name: HOMEPAGE_OIDC_AUTO_LOGIN
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to go straight to your provider instead of showing the login page.
---

# Homepage

Homepage is a fast, good-looking start page for your server. List your apps and bookmarks, and add widgets that show live numbers from over 100 apps: downloads in qBittorrent, what is playing in Jellyfin, blocked ads in Pi-hole and much more. You set it up in a few YAML files.

## Features

- Widgets for over 100 apps, with their live stats
- Info widgets: weather, search, date and time, disk and CPU use
- Bookmarks and service groups, with thousands of icons
- Themes, backgrounds, colours and layouts
- Optional password or OIDC login
- Very fast: pages are built on the server

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6733` in your browser.
2. In the Files app, open AppData, homepage, config.
3. Add your apps to `services.yaml` and your links to `bookmarks.yaml`.
4. Reload the page to see your changes.

## Before you install

**You must set `HOMEPAGE_ALLOWED_HOSTS` first.** It starts as `[ZIMAOS-IP-ADDRESS]:6733`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `192.168.1.20:6733`, or Homepage only shows a host validation error. Add more addresses, comma separated, if you also open it by a domain. Starter config files are made in `/DATA/AppData/homepage/config` on first start. This version has no access to Docker, so Docker container widgets are off; widgets that talk to your apps over the network all work. A password or OIDC login is in the Variables tab; add it in the app settings.
