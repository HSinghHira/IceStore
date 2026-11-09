---
name: Valet
site: https://askvalet.dev
source: https://github.com/askvalet/valet
services:
  - { name: Homepage, path: /, icon: globe }
  - { name: Wall display, path: /wall, icon: monitor }
screenshots: [Main screen, Wall display, Asking Valet]
variables:
  - name: OPENAI_API_KEY
    group: Assistant
    default: ""
    description: >-
      For an OpenAI (or compatible) hosted model. A local model (Ollama, LM
      Studio) usually needs no key. Use it in config.yaml as
      ${OPENAI_API_KEY}.
  - name: ANTHROPIC_API_KEY
    group: Assistant
    default: ""
    description: >-
      For Claude as the assistant's model.
  - name: HA_TOKEN
    group: Service keys
    default: ""
    description: >-
      A Home Assistant long-lived access token (best from a non-admin user).
  - name: TAUTULLI_KEY
    group: Service keys
    default: ""
    description: >-
      Tautulli's API key, for Plex.
  - name: SONARR_KEY
    group: Service keys
    default: ""
    description: >-
      Sonarr's API key (Settings, General).
  - name: RADARR_KEY
    group: Service keys
    default: ""
    description: >-
      Radarr's API key.
  - name: PROWLARR_KEY
    group: Service keys
    default: ""
    description: >-
      Prowlarr's API key.
  - name: QBIT_USER
    group: Service keys
    default: ""
    description: >-
      Your qBittorrent web UI user name.
  - name: QBIT_PASS
    group: Service keys
    default: ""
    description: >-
      Your qBittorrent web UI password.
  - name: IMMICH_KEY
    group: Service keys
    default: ""
    description: >-
      An Immich API key with read permissions.
  - name: PIHOLE_PASSWORD
    group: Service keys
    default: ""
    description: >-
      A Pi-hole v6 app password.
  - name: PAPERLESS_TOKEN
    group: Service keys
    default: ""
    description: >-
      A Paperless-ngx API token (best from a view-only user).
---

# Valet

Valet is a homepage for your homelab that can also do things. It shows what's happening across your services, live, and lets you act on it right there. Ask it questions in plain words, with a local or hosted AI model, or switch the AI off. One YAML file sets up everything, with 185 integrations.

## Features

- Live cards for your services: status, downloads, what's playing, cameras, the weather and more
- Ask the assistant anything; every change it makes waits for your approval
- Wall display mode at `/wall` for a tablet or a spare screen
- 185 integrations (Home Assistant, Plex, the *arr apps, Immich, Pi-hole...) and your own
- Your API keys stay on the server; no account, no telemetry

## How to use

1. Open Valet from your dashboard. A getting-started card walks you through the first steps.
2. Edit `config.yaml` in `/DATA/AppData/valet/config` to add your services.
3. Put each service's API key in the app settings as a variable, and use it in `config.yaml` as `${NAME}`.
4. To use the buttons, turn on sign-in (`auth: { mode: local }`) and restart.

## Before you install

Valet starts **read-only**: anyone who can open the page sees your services, but nothing can be changed until you turn on sign-in. Add `auth: { mode: local, secureCookie: false }` to `config.yaml` (the `secureCookie: false` part is needed over plain http), restart the app, copy the one-time setup code from its logs and make your account.

Every service key is a variable you add in the app settings (the Variables tab lists the common ones; any name works) and refer to in `config.yaml` as `${NAME}`. Valet answers on its IP address and localhost; for a domain, add it to `allowedHosts` in `config.yaml`. To show your containers, use the `docker` integration with a read-only socket proxy, never the Docker socket itself.
