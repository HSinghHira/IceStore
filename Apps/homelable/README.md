---
site: https://github.com/Pouzor/homelable
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API Docs, path: /docs, icon: code }
variables:
  - name: AUTH_USERNAME
    group: Sign-in
    default: admin
    description: >-
      The user name for the password login.
  - name: AUTH_PASSWORD_HASH
    group: Sign-in
    default: ""
    description: >-
      A bcrypt hash of your password, if you would rather not type the
      password itself. It wins over ADMIN_PASSWORD. Leave it out normally.
  - name: ACCESS_TOKEN_EXPIRE_MINUTES
    group: Sign-in
    default: "1440"
    description: >-
      How long a password sign-in lasts, in minutes.
  - name: AUTH_MODE
    group: Sign in with OpenID Connect
    default: local
    description: >-
      Set to oidc to sign in with your own identity provider (Authentik,
      Pocket ID, Keycloak...) instead of the password.
  - name: OIDC_DISCOVERY_URL
    group: Sign in with OpenID Connect
    default: ""
    description: >-
      Your provider's discovery address, ending in
      /.well-known/openid-configuration.
  - name: OIDC_CLIENT_ID
    group: Sign in with OpenID Connect
    default: ""
    description: >-
      The client ID from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OpenID Connect
    default: ""
    description: >-
      The client secret from your provider.
  - name: OIDC_REDIRECT_URI
    group: Sign in with OpenID Connect
    default: "<PUBLIC_URL>/api/v1/auth/oidc/callback"
    description: >-
      The callback address to register at your provider. It is made from
      PUBLIC_URL, so you rarely need to set it.
  - name: OIDC_SCOPES
    group: Sign in with OpenID Connect
    default: openid profile email
    description: >-
      The scopes to ask for, separated by spaces.
  - name: OIDC_COOKIE_SECURE
    group: Sign in with OpenID Connect
    default: "true"
    description: >-
      Needs HTTPS for PUBLIC_URL and the provider. Set to false only to try
      OpenID Connect over plain HTTP on your own network.
  - name: OIDC_SESSION_EXPIRE_MINUTES
    group: Sign in with OpenID Connect
    default: "480"
    description: >-
      How long an OpenID Connect sign-in lasts, in minutes (5 to 1440).
  - name: CORS_ORIGINS
    group: Server
    default: '["<PUBLIC_URL>"]'
    description: >-
      Other browser addresses allowed to call the API directly, as a JSON
      list. The web app does not need it.
  - name: SCANNER_RANGES
    group: Network scanner
    default: '["192.168.1.0/24"]'
    description: >-
      The networks the scanner starts with, as a JSON list like
      ["192.168.1.0/24","10.0.0.0/24"]. You can also change them in the app.
  - name: SCANNER_HTTP_RANGES
    group: Network scanner
    default: "[]"
    description: >-
      Extra ports for the deep scan, as a JSON list like ["8080","9000-9100"].
  - name: SCANNER_HTTP_PROBE_ENABLED
    group: Network scanner
    default: "false"
    description: >-
      Set to true to look at web pages on found ports to name the service.
  - name: SCANNER_HTTP_VERIFY_TLS
    group: Network scanner
    default: "false"
    description: >-
      Set to true to check HTTPS certificates during the deep scan.
  - name: STATUS_CHECKER_INTERVAL
    group: Status checks
    default: "60"
    description: >-
      How often every node is checked, in seconds.
  - name: STATUS_CHECKER_ENABLED
    group: Status checks
    default: "true"
    description: >-
      Set to false when another tool does your monitoring.
  - name: LIVEVIEW_KEY
    group: Sharing
    default: ""
    description: >-
      Set a long random value to turn on a read-only canvas at
      /view?key=<value>, for a wall screen.
  - name: DOCS_VIEW_KEY
    group: Sharing
    default: ""
    description: >-
      Set a long random value to turn on read-only documentation at
      /docs?key=<value>. Anyone with the link reads every document.
  - name: HOMEPAGE_API_KEY
    group: Sharing
    default: ""
    description: >-
      Set a random value to turn on the gethomepage widget at
      /api/v1/stats/summary (send it in the X-API-Key header).
  - name: PROXMOX_HOST
    group: Proxmox auto-sync
    default: ""
    description: >-
      Your Proxmox server, like 192.168.1.10. Only needed for auto-sync;
      one-off imports ask in the app.
  - name: PROXMOX_PORT
    group: Proxmox auto-sync
    default: "8006"
    description: >-
      Your Proxmox API port.
  - name: PROXMOX_TOKEN_ID
    group: Proxmox auto-sync
    default: ""
    description: >-
      The API token id, like root@pam!homelable. Give it the read-only
      PVEAuditor role.
  - name: PROXMOX_TOKEN_SECRET
    group: Proxmox auto-sync
    default: ""
    description: >-
      The API token secret.
  - name: PROXMOX_VERIFY_TLS
    group: Proxmox auto-sync
    default: "true"
    description: >-
      Set to false if Proxmox uses a self-signed certificate.
  - name: UNRAID_HOST
    group: Unraid auto-sync
    default: ""
    description: >-
      Your Unraid server, like 192.168.1.20.
  - name: UNRAID_API_KEY
    group: Unraid auto-sync
    default: ""
    description: >-
      An Unraid API key with read access to Docker, VMs and Info.
  - name: UNRAID_USE_HTTPS
    group: Unraid auto-sync
    default: "false"
    description: >-
      Set to true when Unraid's "Use SSL/TLS" is on.
  - name: UNRAID_PORT
    group: Unraid auto-sync
    default: "80"
    description: >-
      The Unraid web port (443 with HTTPS).
  - name: UNRAID_VERIFY_TLS
    group: Unraid auto-sync
    default: "false"
    description: >-
      Set to true once Unraid has a trusted certificate.
  - name: ZIGBEE_MQTT_HOST
    group: Zigbee2MQTT auto-sync
    default: ""
    description: >-
      Your MQTT broker, like 192.168.1.20.
  - name: ZIGBEE_MQTT_PORT
    group: Zigbee2MQTT auto-sync
    default: "1883"
    description: >-
      Your MQTT broker's port (usually 8883 with TLS).
  - name: ZIGBEE_MQTT_USERNAME
    group: Zigbee2MQTT auto-sync
    default: ""
    description: >-
      The MQTT user name, if your broker needs one.
  - name: ZIGBEE_MQTT_PASSWORD
    group: Zigbee2MQTT auto-sync
    default: ""
    description: >-
      The MQTT password.
  - name: ZIGBEE_BASE_TOPIC
    group: Zigbee2MQTT auto-sync
    default: zigbee2mqtt
    description: >-
      The Zigbee2MQTT base topic.
  - name: ZIGBEE_MQTT_TLS
    group: Zigbee2MQTT auto-sync
    default: "false"
    description: >-
      Set to true for a TLS broker.
  - name: ZIGBEE_NETWORKMAP_TIMEOUT
    group: Zigbee2MQTT auto-sync
    default: "300"
    description: >-
      Seconds to wait for the network map. Raise it for a very large mesh.
  - name: ZWAVE_MQTT_HOST
    group: Z-Wave JS auto-sync
    default: ""
    description: >-
      Your MQTT broker, like 192.168.1.20.
  - name: ZWAVE_MQTT_PORT
    group: Z-Wave JS auto-sync
    default: "1883"
    description: >-
      Your MQTT broker's port.
  - name: ZWAVE_MQTT_USERNAME
    group: Z-Wave JS auto-sync
    default: ""
    description: >-
      The MQTT user name, if your broker needs one.
  - name: ZWAVE_MQTT_PASSWORD
    group: Z-Wave JS auto-sync
    default: ""
    description: >-
      The MQTT password.
  - name: ZWAVE_PREFIX
    group: Z-Wave JS auto-sync
    default: zwave
    description: >-
      The Z-Wave JS UI MQTT prefix.
  - name: ZWAVE_GATEWAY_NAME
    group: Z-Wave JS auto-sync
    default: zwavejs2mqtt
    description: >-
      The Z-Wave JS UI gateway name.
  - name: ZWAVE_MQTT_TLS
    group: Z-Wave JS auto-sync
    default: "false"
    description: >-
      Set to true for a TLS broker.
---

# Homelable

Homelable is a self-hosted map of your homelab: scan your network, drop the devices it finds onto a canvas, and watch live health checks light up as your gear goes on and offline. This is Homelable in a single container, with the API and the web app behind one port and one data folder. The secret key and the admin password are made for you on first start.

## Features

- One-click nmap network scans that queue new devices for you to approve onto the canvas
- 15+ node types: routers, switches, servers, hypervisors, firewalls, Docker hosts and containers, IoT and more
- Live status checks per node (ping, TCP, HTTP) with real-time updates
- Import Proxmox hosts and guests, Unraid, Zigbee2MQTT meshes and Z-Wave JS networks
- Rack view with port-to-port cabling, next to your network and electrical diagrams
- Sign in with a password or with your own OpenID Connect provider

## How to use

1. Open Homelable from your dashboard.
2. Sign in as `admin`. The password is in the app logs, on the line that says "admin login is".
3. Click **Scan Network** to find devices on your network, or add nodes by hand.
4. Approve the devices you want from the Pending Devices list.
5. Double-click a node to set its health check, icon and services.
6. Scans run from inside the container, so device MAC addresses are not shown.

## Before you install

`PUBLIC_URL` starts as `http://localhost:6151`; change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6151`. Type a password in `ADMIN_PASSWORD`, or leave it empty and one is made for you: it is in the app logs on the line that says "admin login is", and in `admin-password.txt` in the data folder. You no longer need to make a bcrypt hash yourself. The first start takes about a minute. Scan ranges, Proxmox, Unraid, Zigbee and Z-Wave auto-sync and OpenID Connect sign-in are in the Variables tab; add them in the app settings.
