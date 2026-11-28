---
site: https://kutt.it
source: https://github.com/thedevs-network/kutt
screenshots: [Shorten links, Admin users, Log in]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: JWT_SECRET
    group: Security
    default: ""
    description: >-
      The secret that signs sign-ins. Made on first start and kept in
      the db folder when left out.
  - name: DISALLOW_REGISTRATION
    group: Sign-in
    default: "true"
    description: >-
      Set to false to let others sign up.
  - name: DISALLOW_ANONYMOUS_LINKS
    group: Sign-in
    default: "true"
    description: >-
      Set to false to let people make links without an account.
  - name: LINK_LENGTH
    group: Links
    default: "6"
    description: >-
      How many characters new short links have.
  - name: TRUST_PROXY
    group: Network
    default: "true"
    description: >-
      Trust X-Forwarded-For from a reverse proxy, for correct visitor
      IPs.
  - name: CUSTOM_DOMAIN_USE_HTTPS
    group: Links
    default: "false"
    description: >-
      Set to true to make https links for custom domains.
  - name: MAIL_ENABLED
    group: Email
    default: "false"
    description: >-
      Set to true to send password reset and verification emails (with
      MAIL_HOST, MAIL_PORT, MAIL_USER, MAIL_PASSWORD and MAIL_FROM).
  - name: OIDC_ENABLED
    group: Sign-in
    default: "false"
    description: >-
      Set to true to sign in with OpenID Connect (with OIDC_ISSUER,
      OIDC_CLIENT_ID and OIDC_CLIENT_SECRET).
---

# Kutt

Kutt shortens long links and counts the visits, with the browser, country and referrer of each one. Use your own domain, set expiry and passwords on links, and make links from scripts with its API.

## Features

- Short links with your own slug, password, expiry and description
- Visit stats by browser, OS, country and referrer
- Custom domains and a browser extension
- Users, an admin page and an API with keys
- OIDC sign-in and email for password resets

## How to use

1. Open Kutt right away and make the admin account.
2. Paste a long link and press Shorten.

## Before you install

Before installing, set DEFAULT_DOMAIN to your ZimaOS IP and port (like 192.168.1.20:6859) or a domain pointed at it; short links start with it. Right after installing, open Kutt and make the admin account; until you do, anyone on your network can. JWT_SECRET is made on first start and kept in the db folder, so sign-ins survive restarts.
