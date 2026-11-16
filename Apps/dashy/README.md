---
site: https://dashy.to
source: https://github.com/Lissy93/dashy
screenshots: [Dashboard]
variables:
  - name: BASIC_AUTH_USERNAME
    group: Login
    default: ""
    description: >-
      A user name for a simple browser login in front of Dashy. Set it together with BASIC_AUTH_PASSWORD.
  - name: BASIC_AUTH_PASSWORD
    group: Login
    default: ""
    description: >-
      The password for that login.
  - name: ENABLE_HTTP_AUTH
    group: Login
    default: ""
    description: >-
      Set to true to check the users you list under appConfig.auth.users in conf.yml on the server, not only in the browser.
  - name: ENABLE_API
    group: API
    default: "false"
    description: >-
      Set to true to turn on the REST API for reading and writing the config.
  - name: API_TOKEN
    group: API
    default: ""
    description: >-
      A long random password for the API, sent as a bearer token. Needed when Dashy has no login.
  - name: DISABLE_CONFIG_BACKUPS
    group: Config
    default: ""
    description: >-
      Set to true to stop Dashy saving a backup copy each time you save the config.
  - name: DISABLE_PROXY_ENDPOINTS
    group: Config
    default: ""
    description: >-
      Set to true to turn off the server's proxy for widgets and status checks.
---

# Dashy

Dashy is a start page for your homelab. Put all your apps and links in one place, grouped into sections, with icons, status checks that show what is up or down, and widgets for weather, system stats and more. You change it all in the page itself or in one YAML file.

## Features

- Sections of apps and links with icons (thousands built in)
- Status checks that show which apps are up
- Over 50 widgets: weather, clocks, system info, RSS and more
- Many themes, a colour editor and several layouts
- Edit everything in the page, with a visual editor
- Optional login with users and guest access, or OIDC
- Search, keyboard shortcuts and multiple pages

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6732` in your browser. You see a sample dashboard.
2. Click Config (the wrench), then Edit Config, to change sections and items.
3. Save to disk, and the page reloads with your changes.

## Before you install

Nothing needs to be set first, and it starts in about half a minute. A sample `conf.yml` is put in `/DATA/AppData/dashy/user-data` on first start; you can edit it there with the Files app or in Dashy itself. There is no login until you add one, so keep port 6732 on your home network. A simple login, the REST API and the other settings are in the Variables tab; add them in the app settings.
