---
site: https://web-check.xyz/
source: https://github.com/lissy93/web-check
services:
  - { name: Web UI, path: /, icon: search }
variables:
  - name: GOOGLE_CLOUD_API_KEY
    group: API keys
    default: ""
    description: >-
      A Google Cloud API key, for quality metrics.
  - name: REACT_APP_SHODAN_API_KEY
    group: API keys
    default: ""
    description: >-
      A Shodan API key, to show associated host names for a domain.
  - name: REACT_APP_WHO_API_KEY
    group: API keys
    default: ""
    description: >-
      A WhoAPI key, for fuller WHOIS records.
  - name: SECURITY_TRAILS_API_KEY
    group: API keys
    default: ""
    description: >-
      A SecurityTrails API key, for organisation info.
  - name: CLOUDMERSIVE_API_KEY
    group: API keys
    default: ""
    description: >-
      A Cloudmersive API key, to check for known threats.
  - name: TRANCO_USERNAME
    group: API keys
    default: ""
    description: >-
      Your Tranco email, for site rank. Set it together with TRANCO_API_KEY.
  - name: TRANCO_API_KEY
    group: API keys
    default: ""
    description: >-
      Your Tranco API key, for site rank.
  - name: URL_SCAN_API_KEY
    group: API keys
    default: ""
    description: >-
      A URLScan API key, for miscellaneous site info.
  - name: BUILT_WITH_API_KEY
    group: API keys
    default: ""
    description: >-
      A BuiltWith API key, for the tech stack check.
  - name: TORRENT_IP_API_KEY
    group: API keys
    default: ""
    description: >-
      An iknowwhatyoudownload API key, for torrent activity on the site's IP.
  - name: API_TIMEOUT_LIMIT
    group: Server
    default: "10000"
    description: >-
      How long each check may take, in milliseconds.
  - name: API_ENABLE_RATE_LIMIT
    group: Server
    default: "false"
    description: >-
      Set to true to limit how often the API can be called.
---

# Web-Check

Web-Check is a self-hosted OSINT tool that runs dozens of checks against any domain (DNS, SSL, headers, hosting, tech stack and more) and lays it all out in one clean report.

## Features

- Dozens of checks in one report: DNS records, SSL/TLS, security headers, WHOIS, hosting, tech stack, blocklist status and more
- No database or storage; every scan runs fresh
- Optional API keys unlock a few extra checks
- A clean report for any domain you enter

## How to use

1. Open Web-Check from your dashboard.
2. Type in the domain or URL you want to check.
3. Run the scan and browse the report as it loads.

## Before you install

Nothing needs to be set first; Web-Check works without any API keys. To unlock extra checks, add the matching key from the Variables tab in the app settings and restart the app.
