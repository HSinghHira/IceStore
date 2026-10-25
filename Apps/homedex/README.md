---
site: https://github.com/HarshShah0203/homedex
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: HOMEDEX_SECURE_COOKIES
    group: Server
    default: "false"
    description: >-
      Set to true when you open Homedex over HTTPS through a reverse proxy,
      so the sign-in cookie is only sent over HTTPS.
  - name: HOMEDEX_TRUSTED_PROXIES
    group: Server
    default: ""
    description: >-
      IPs or ranges of your reverse proxy, comma separated, like
      192.168.1.10/32. Homedex then trusts the visitor address it forwards.
  - name: HOMEDEX_GONE_RETENTION_DAYS
    group: Server
    default: "30"
    description: >-
      How many days Homedex keeps things that are gone (like a removed
      container) before it forgets them.
  - name: HOMEDEX_SECRET
    group: Server
    default: ""
    description: >-
      A base64 key that encrypts saved source credentials. Leave it out to
      use the key made on first start in the data folder.
---

# Homedex

A read-only homelab inventory. It scans Docker, Proxmox, Tailscale and your reverse proxy, then builds a searchable record of services, hosts, ports, routes, certificates, domains and changes.

## Features

- Finds every container, image, port and network on your Docker hosts
- Shows which reverse proxy route leads to which container, and flags broken ones
- Tracks certificate and domain expiry by days remaining
- Change feed shows what moved between scans
- Read-only by design: a filtering socket proxy blocks any Docker action that changes something
- SQLite storage in the app data folder

## How to use

1. Open Homedex from your dashboard.
2. Sign in with the admin password from the app settings.
3. In the setup wizard, keep the source `tcp://docker-socket-proxy:2375` and run the first scan.
4. Add more sources later under **Sources**: Traefik, Caddy, Nginx Proxy Manager, Proxmox, Tailscale and more.
5. Export Markdown, JSON or CSV, or share a read-only view.

## Before you install

`HOMEDEX_ADMIN_PASSWORD` is your admin password. It comes filled with a random value; change it to your own of 12 or more characters if you like, and write it down. It is only used on the first start, before an admin exists. Homedex reads Docker through a small proxy that blocks every change, so it can only look. Open `http://your-zimaos-ip:6150`, sign in, and keep `tcp://docker-socket-proxy:2375` as the Docker source in the setup wizard. More settings are in the Variables tab; add them in the app settings.
