---
source: https://github.com/glanceapp/glance
screenshots: [Home, Dashboard, Markets, Themes]
services:
  - { name: Dashboard, path: /, icon: grid }
variables:
  - name: GITHUB_TOKEN
    group: Widgets
    default: ""
    description: >-
      A read-only GitHub token, to lift the 60 requests an hour limit of
      the releases widget. Use it in glance.yml as token: ${GITHUB_TOKEN}.
---

# Glance

Glance is a fast, good-looking start page. It puts your RSS feeds, Reddit, Hacker News, YouTube channels, weather, calendar, stock prices, GitHub releases and the status of your apps on one page, set up in a single file.

## Features

- RSS, Reddit, Hacker News, Lobsters and YouTube feeds
- Weather, calendar, clock, markets and GitHub releases
- Monitor widget that shows which of your apps are up
- Bookmarks, search box and your own widgets from any JSON API
- Several pages, themes and an optional login

## How to use

1. Open Glance. A starter dashboard is ready.
2. Edit `/DATA/AppData/glance/config/glance.yml` with the Files app. Glance reloads it when you save. Every widget is described in the [configuration docs](https://github.com/glanceapp/glance/blob/main/docs/configuration.md).

## Before you install

Glance is set up in one file, `glance.yml`, written on first start to `/DATA/AppData/glance/config`; change the weather city there first. It has no login at first, so anyone on your network can see the dashboard; the starter file shows how to add one with `auth` (make the secret key with `docker exec glance /app/glance secret:make`). Any environment variable you add in the app settings can be used in `glance.yml` as `${NAME}`, like `${GITHUB_TOKEN}`; a missing one stops Glance from loading the file. Put your own icons and CSS in the `assets` folder next to it; they are served at `/assets/`.
