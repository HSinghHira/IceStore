---
site: https://github.com/tarampampam/webhook-tester
source: https://github.com/tarampampam/webhook-tester
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: SESSION_TTL
    group: Sessions
    default: "168h"
    description: >-
      How long a session and its requests are kept, like 24h or 168h (a week).
  - name: MAX_REQUESTS
    group: Sessions
    default: "128"
    description: >-
      Most requests kept for each session. 0 keeps them all.
  - name: MAX_REQUEST_BODY_SIZE
    group: Sessions
    default: "0"
    description: >-
      Largest request body in bytes. 0 means no limit.
  - name: AUTO_CREATE_SESSIONS
    group: Sessions
    default: "false"
    description: >-
      true makes a session for any new URL that gets a request, so you can pick your own session ids.
  - name: PUBLIC_URL_ROOT
    group: Web
    default: ""
    description: >-
      The address shown in webhook URLs, like https://hooks.example.com. Blank uses the browser's address.
  - name: TUNNEL_DRIVER
    group: Tunnel
    default: ""
    description: >-
      ngrok opens a public tunnel so internet services can reach it. Needs NGROK_AUTHTOKEN.
  - name: NGROK_AUTHTOKEN
    group: Tunnel
    default: ""
    description: >-
      Your ngrok auth token, when TUNNEL_DRIVER is ngrok.
  - name: LOG_LEVEL
    group: Advanced
    default: "info"
    description: >-
      Log detail: debug, info, warn, error or fatal.
---

# Webhook Tester

Webhook Tester gives you a unique URL that catches every HTTP request sent to it. Point a webhook or your own app at it and see each request's headers, body and query live in the browser.

## Features

- A new catch URL in one click, with live updates
- Full headers, body and query of every request
- Set the status code, headers, body and delay it answers with
- Download a request as a file, or copy it as curl
- No sign-in and no database

## How to use

1. Open Webhook Tester. It makes a new session URL for you.
2. Send a webhook or a request to that URL.
3. Watch it show up on the page and click it to see the details.

## Before you install

Webhook Tester has no sign-in: anyone who can open http://[ZIMAOS-IP-ADDRESS]:6897 can see the requests it caught, so don't send real passwords or tokens to it. Apps on your home network can send to it straight away; services on the internet (GitHub, Stripe and so on) need a reverse proxy, a tunnel, or the built-in ngrok tunnel (TUNNEL_DRIVER=ngrok with your NGROK_AUTHTOKEN).
