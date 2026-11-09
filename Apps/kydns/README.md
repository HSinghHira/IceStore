---
name: KyDNS
site: https://busnes.app
source: https://github.com/Busnes-app/KyDNS-server
services:
  - { name: Admin, path: /, icon: globe }
  - { name: First-run setup, path: /setup, icon: server }
screenshots: [Dashboard, Settings]
variables:
  - name: KYDNS_ADMIN_HOSTNAMES
    group: Admin page
    default: ""
    description: >-
      Extra names you open the admin page by, like kydns.home.arpa. It always
      answers on localhost and IP addresses.
  - name: KYDNS_TRUSTED_PROXIES
    group: Admin page
    default: ""
    description: >-
      The address of a reverse proxy in front of the admin page, so KyDNS
      believes the visitor's IP from it. It does not limit who can connect.
  - name: KYDNS_BACKUP_DEPOSIT_INTERVAL
    group: Backups
    default: 24h
    description: >-
      How often KyDNS sends a sealed backup to a paired KyRecovery.
  - name: KYDNS_BACKUP_DIR
    group: Backups
    default: ""
    description: >-
      A folder inside the container for local backups, like
      /var/lib/kydns/backups.
  - name: KYDNS_BACKUP_KEEP
    group: Backups
    default: "7"
    description: >-
      How many local backups to keep.
  - name: KYDNS_BACKUP_ALLOW_PRIVATE_RECOVERY
    group: Backups
    default: "false"
    description: >-
      Set to true for a KyRecovery on your home network (it still needs
      https).
---

# KyDNS

KyDNS is a DNS server and service directory for homes, homelabs and small teams. Give your services names like `nas.home.arpa` once, and every device on your network can reach them. It also blocks ads and trackers with built-in and your own block lists. Part of the Busnes Ky Suite; it works on its own.

## Features

- Private service names, DNS records and per-network views
- Ad and tracker blocking with block lists, allow and deny rules
- Encrypted upstream DNS
- Query log and statistics
- Optional replication between two KyDNS servers, backups to KyRecovery and an MCP server for AI agents

## How to use

1. Copy the setup token from the app's logs.
2. Open `http://[ZIMAOS-IP-ADDRESS]:6697/setup`, enter the token and choose your admin password.
3. Add your services and names.
4. Point a test device's DNS at your ZimaOS IP. When it works, set it in your router for every device.

## Before you install

KyDNS answers DNS on **port 53** of your ZimaOS box (UDP and TCP), so nothing else there may use it: stop AdGuard Home, Pi-hole or any other DNS app first. The admin page is on port 6697.

On the first start KyDNS prints a setup token in its logs and also writes it to `setup-token` in `/DATA/AppData/kydns/data`. Open `http://[ZIMAOS-IP-ADDRESS]:6697/setup`, enter it and choose a password. Test with one device before you change your router's DNS. Most settings (upstream resolvers, block lists, names) are changed on the admin page; the few others are in the Variables tab and are added in the app settings. The built-in DHCP server needs host networking, so it is not available here.
