---
site: https://gatus.io
source: https://github.com/TwiN/gatus
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: GATUS_LOG_LEVEL
    group: Logging
    default: "INFO"
    description: >-
      How much is logged: DEBUG, INFO, WARN or ERROR.
---

# Gatus

Gatus checks your websites and services (HTTP, TCP, DNS, ping and more) on a schedule, shows their history on a clean status page, and alerts you when something is down. Everything is set up in one YAML file.

## Features

- HTTP, TCP, UDP, ICMP, DNS, SSH, TLS certificate and WebSocket checks
- Conditions on status, body, response time and certificate expiry
- Alerts to Discord, Slack, Telegram, ntfy, Gotify, email, PagerDuty and more
- Status page with groups, badges and history kept in SQLite
- Config reloaded by itself when you save it

## How to use

1. Open Gatus. The starter checks are on the page.
2. Edit /DATA/AppData/gatus/config/config.yaml with the Files app to add your own sites.

## Before you install

Gatus is set up in one file, /DATA/AppData/gatus/config/config.yaml, written on first start with a few example checks and history kept in SQLite. Edit it with the Files app; Gatus reloads it when you save. The status page has no login, so anyone on your network can see it; any environment variable you add in the app settings can be used in config.yaml as ${NAME}, handy for alert tokens.
