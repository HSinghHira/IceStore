---
site: https://atreolink.com
source: https://github.com/atreoLABS/atreoAGENT
services:
  - { name: Proxy (plain http), path: /, icon: server }
screenshots: [Dashboard, Phone app]
variables:
  - name: ENDPOINT_IP
    group: Public address
    default: ""
    description: >-
      Your public IP, only if UPnP and NAT-PMP don't work and you forwarded
      the WireGuard port on your router yourself.
  - name: ENDPOINT_PORT
    group: Public address
    default: "51820"
    description: >-
      The outside port you forwarded to WG_PORT, used with ENDPOINT_IP.
  - name: WG_PORT
    group: WireGuard
    default: "51820"
    description: >-
      The UDP port the WireGuard tunnel listens on.
  - name: WG_UPNP_ENABLED
    group: WireGuard
    default: "true"
    description: >-
      Set to false so the agent doesn't ask your router to open a port with
      UPnP or NAT-PMP.
  - name: WG_PCP_ENABLED
    group: WireGuard
    default: "true"
    description: >-
      Set to false so the agent doesn't ask your router to open a port with
      PCP.
  - name: WG_IPV6_PINHOLE_ENABLED
    group: WireGuard
    default: "true"
    description: >-
      Set to false so the agent doesn't open an IPv6 pinhole on your router.
  - name: WG_FIREWALL_ENABLED
    group: WireGuard
    default: "true"
    description: >-
      Keeps family devices to the proxy ports only. Set to false only if you
      want every port on your ZimaOS reachable from every paired device; it
      skips the per-app access rules.
  - name: RELAY_ENABLED
    group: Relay
    default: "true"
    description: >-
      Set to false so the agent never uses the atreoLINK relay, even when no
      direct path works (behind CGNAT).
  - name: RELAY_FORCE
    group: Relay
    default: "false"
    description: >-
      Set to true to always keep a relay ready, even when a direct path works.
  - name: PROXY_ENABLED
    group: Proxy
    default: "true"
    description: >-
      Set to false to use your own reverse proxy (Caddy, Traefik, nginx) with
      the agent's forward-auth endpoint instead of the built-in proxy.
  - name: PROXY_HTTPS_PORT
    group: Proxy
    default: "443"
    description: >-
      The https port of the built-in proxy. Family devices connect to it.
  - name: PROXY_AUTH_PORT
    group: Proxy
    default: "9091"
    description: >-
      The forward-auth endpoint port, on the tunnel address only.
  - name: PROXY_TRUSTED_PROXIES
    group: Proxy
    default: ""
    description: >-
      The addresses of your own reverse proxy whose X-Forwarded headers the
      forward-auth endpoint trusts, comma-separated, like 10.0.0.0/24.
  - name: NOTIFY_PORT
    group: Notifications
    default: "9876"
    description: >-
      The port of the local notification API your apps send push messages to.
  - name: SMTP_ENABLED
    group: Email to push gateway
    default: "false"
    description: >-
      Set to true so apps that send email alerts can send them to the agent,
      which turns them into encrypted push notifications.
  - name: SMTP_LISTEN
    group: Email to push gateway
    default: 0.0.0.0:2525
    description: >-
      Address and port of the email gateway. Keep it on your home network.
  - name: SMTP_TLS_ENABLED
    group: Email to push gateway
    default: "false"
    description: >-
      Set to true to offer STARTTLS with a self-signed certificate, for apps
      that refuse plain email connections.
  - name: SMTP_CATCH_ALL
    group: Email to push gateway
    default: ""
    description: >-
      A member's email address that gets mail sent to unknown addresses.
      Leave it out to refuse unknown addresses.
  - name: SMTP_MAX_MESSAGE_BYTES
    group: Email to push gateway
    default: "1048576"
    description: >-
      The biggest email the gateway accepts, in bytes.
  - name: SMTP_RATE_PER_MINUTE
    group: Email to push gateway
    default: "5"
    description: >-
      How many emails one address may send each minute.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      Set to debug for detailed logs when something doesn't connect.
---

# atreoLINK

atreoAGENT runs on your ZimaOS and pairs it with your atreoLINK account, so you and your family can open the apps you host, like Jellyfin, Immich or Home Assistant, from anywhere. Traffic goes through an encrypted WireGuard tunnel that atreoLINK can't read. You need a free account at atreolink.com.

## Features

- Encrypted WireGuard tunnel, peer-to-peer, with a relay when you are behind CGNAT
- Opens the ports it needs by itself (UPnP, NAT-PMP, PCP), so there is no port forwarding to set up
- Pick which family member can open which app
- A free subdomain with an https certificate, made and renewed for you; your own domain works too
- End-to-end encrypted push notifications, and an optional email to push gateway for apps that send email alerts
- Apps for phones, TVs and the browser for your family

## How to use

1. After install, open the app's log in your dashboard.
2. Copy the pairing link from the log and open it in a browser where you are signed in to atreolink.com.
3. Pick your subdomain and approve.
4. Add your apps and invite your family in the dashboard at https://app.atreolink.com.

This app has no web page of its own on your server. Everything is set up at app.atreolink.com.

## Before you install

Make a free account at https://atreolink.com. The agent uses host networking and needs port 443 (https) and UDP port 51820 free; its plain http port is moved to 6140 so it doesn't clash with the ZimaOS dashboard on port 80. After install, the pairing link is in the app log; a new link is printed each time the app restarts until it is paired. When you add apps at app.atreolink.com, use addresses like `http://[ZIMAOS-IP-ADDRESS]:<the app's port>`. Every other setting is optional and listed in the Variables tab; to use one, add it in the app settings. Back up the data folder, or you have to pair again.
