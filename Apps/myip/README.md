---
site: https://ipcheck.ing
source: https://github.com/jason5ng32/MyIP
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: IPINFO_API_KEY
    group: API keys
    default: ""
    description: >-
      An ipinfo.io token for IP details.
  - name: IPAPIIS_API_KEY
    group: API keys
    default: ""
    description: >-
      An ipapi.is key for IP details.
  - name: CLOUDFLARE_API_KEY
    group: API keys
    default: ""
    description: >-
      A Cloudflare API token for network details.
  - name: GOOGLE_MAP_API_KEY
    group: API keys
    default: ""
    description: >-
      A Google Maps key to show where an IP is on a map.
  - name: MAXMIND_ACCOUNT_ID
    group: API keys
    default: ""
    description: >-
      Your MaxMind account ID, for the offline GeoLite2 database (with
      MAXMIND_LICENSE_KEY).
  - name: MAXMIND_LICENSE_KEY
    group: API keys
    default: ""
    description: >-
      Your MaxMind license key.
  - name: ALLOWED_DOMAINS
    group: Security
    default: ""
    description: >-
      Host names allowed to use the API, comma separated, like
      myip.example.com. Leave empty to allow any.
  - name: LOG_LEVEL
    group: Server
    default: "info"
    description: >-
      How much is logged: error, warn, info or debug.
---

# MyIP

MyIP shows the public IP addresses your devices are seen with, where they are, and whether your VPN or proxy leaks. It also tests which websites you can reach, DNS and WebRTC leaks, connection speed, and runs global ping and MTR checks.

## Features

- Your IPv4 and IPv6 addresses from several sources, with location and network owner
- Reachability of Google, GitHub, YouTube, ChatGPT and more
- WebRTC and DNS leak tests for VPN users
- Speed test, global latency, ping and MTR
- Whois, DNS lookups and censorship checks

## How to use

1. Open MyIP on any device. Your addresses and tests show right away.

## Before you install

MyIP needs no setup: every test runs from the browser of the device that opens it, so open it on the phone or computer you want to check. It has no login. Some IP details come from free services that work better with your own API keys; add them in the app settings (Variables tab).
