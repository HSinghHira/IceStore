---
site: https://gotify.net
source: https://github.com/gotify/server
screenshots: [Messages]
variables:
  - name: GOTIFY_REGISTRATION
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone with the address make their own account.
  - name: GOTIFY_PASSSTRENGTH
    group: Sign-up and accounts
    default: "10"
    description: >-
      How hard passwords are hashed (bcrypt cost). Higher is safer but slower to sign in.
  - name: GOTIFY_LOCALAUTH_ENABLED
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn off username and password sign-in, so only OIDC works.
  - name: GOTIFY_OIDC_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to add a sign-in button for your OIDC provider (Authentik, Pocket ID, Keycloak and others).
  - name: GOTIFY_OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's issuer address, like https://auth.example.com/application/o/gotify/.
  - name: GOTIFY_OIDC_CLIENTID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your provider.
  - name: GOTIFY_OIDC_CLIENTSECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your provider.
  - name: GOTIFY_OIDC_REDIRECTURL
    group: Sign in with OIDC
    default: ""
    description: >-
      Gotify's callback address, like http://192.168.1.20:6730/auth/oidc/callback. Add the same address in your provider.
  - name: GOTIFY_OIDC_AUTOREGISTER
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false so only people who already have a Gotify account can sign in with OIDC.
  - name: GOTIFY_OIDC_GROUPS_ADMIN
    group: Sign in with OIDC
    default: ""
    description: >-
      Groups from your provider whose members become Gotify admins, comma separated.
  - name: GOTIFY_OIDC_IDP_NAME
    group: Sign in with OIDC
    default: "OIDC"
    description: >-
      The name shown on the sign-in button.
  - name: GOTIFY_SERVER_TRUSTEDPROXIES
    group: Server
    default: ""
    description: >-
      Addresses of reverse proxies in front of Gotify, comma separated, so it sees each visitor's real address.
  - name: GOTIFY_SERVER_SECURECOOKIE
    group: Server
    default: "false"
    description: >-
      Set to true when you only open Gotify over https.
  - name: GOTIFY_SERVER_STREAM_ALLOWEDORIGINS
    group: Server
    default: ""
    description: >-
      Other web addresses allowed to open the live message stream, comma separated.
  - name: GOTIFY_MCP_ENABLED
    group: Features
    default: "true"
    description: >-
      Set to false to turn off the built-in MCP server for AI assistants.
  - name: GOTIFY_LOGLEVEL
    group: Logs
    default: "info"
    description: >-
      debug, info, warn or error.
---

# Gotify

Gotify is your own push notification server. Scripts, backups, the *arr apps, Home Assistant and many other tools send it a message with one web request, and you get it at once in the web page or the Android app.

## Features

- Send a message with one curl command or any HTTP client
- Live messages in the browser and the Android app (WebSocket)
- One token per sending app, with its own name and picture
- Several users, each with their own apps and clients
- Optional sign-in with OIDC (Authentik, Pocket ID, Keycloak and others)
- Plugins to add features

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6730` and sign in as admin. The password is in the app's logs, in the box marked CREDENTIALS.
2. Go to Apps, create an app and copy its token.
3. Send a test message: `curl "http://[ZIMAOS-IP-ADDRESS]:6730/message?token=YOUR_TOKEN" -F "title=Hello" -F "message=It works"`
4. Install the Gotify Android app and sign in with the same address to get messages on your phone.

## Before you install

Leave `GOTIFY_DEFAULTUSER_PASS` blank and the app makes a random admin password on first start. It is printed in the app's logs, in the box marked CREDENTIALS, and saved in `/DATA/AppData/gotify/data/password.txt`. It is only used on the very first start: change it later in Gotify under Users. Sign-up, OIDC sign-in and the other settings are in the Variables tab; add them in the app settings. It starts in a few seconds.
