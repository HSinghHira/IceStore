---
site: https://homer-demo.netlify.app
source: https://github.com/bastienwirtz/homer
services:
  - { name: Dashboard, path: /, icon: globe }
variables:
  - name: SUBFOLDER
    group: Web
    default: "/_"
    description: >-
      Serve Homer under a sub path, like /homer, when it sits behind a reverse proxy.
  - name: IPV6_DISABLE
    group: Web
    default: "0"
    description: >-
      1 turns off IPv6 listening, for hosts without IPv6.
---

# Homer

Homer is a very simple static home page for your server. You list your apps and links in one config.yml file and Homer shows them as tidy cards, grouped the way you like.

## Features

- One YAML file, no database and no sign-in
- Groups, tags, icons and Font Awesome logos
- Quick search and keyboard shortcuts
- Light and dark themes, custom colors and CSS
- Smart cards that show live status for many apps

## How to use

1. Open the Files app and go to AppData/homer/assets.
2. Edit config.yml: change the title and add your apps under services.
3. Reload Homer in your browser to see the changes.

## Before you install

Homer has no settings page and no sign-in. On first start it copies an example config.yml and some icons into AppData/homer/assets; you change the dashboard by editing that file. Anyone on your network who opens http://[ZIMAOS-IP-ADDRESS]:6884 can see the page, so keep passwords out of it. Use your ZimaOS IP address in links, not localhost, so they work from other devices.
