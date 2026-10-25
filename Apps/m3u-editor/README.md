---
site: https://sparkison.github.io/m3u-editor-docs/
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: OIDC_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to sign in with your own OIDC provider (Authentik,
      Authelia, Keycloak, Pocket ID...).
  - name: OIDC_ISSUER_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's address, without /.well-known/openid-configuration.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your provider.
  - name: OIDC_SCOPES
    group: Sign in with OIDC
    default: openid,profile,email
    description: >-
      The scopes to ask for, separated by commas.
  - name: OIDC_AUTO_CREATE_USERS
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false so only existing users can sign in with OIDC.
  - name: OIDC_AUTO_REDIRECT
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to skip the login form and go straight to your provider.
  - name: OIDC_BUTTON_LABEL
    group: Sign in with OIDC
    default: Login with SSO
    description: >-
      The text on the sign-in button.
  - name: OIDC_HIDE_LOGIN_FORM
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to hide the user name and password form.
  - name: M3U_PROXY_TOKEN
    group: Stream proxy
    default: ""
    description: >-
      The token between the app and its built-in stream proxy. Leave it out
      and a new one is made on every start.
  - name: M3U_PROXY_LOG_LEVEL
    group: Stream proxy
    default: ERROR
    description: >-
      How much the stream proxy logs: ERROR, WARNING, INFO or DEBUG.
  - name: HLS_GC_ENABLED
    group: Stream proxy
    default: "true"
    description: >-
      Set to false to keep old HLS stream pieces instead of cleaning them up.
  - name: HLS_GC_AGE_THRESHOLD
    group: Stream proxy
    default: "7200"
    description: >-
      Delete HLS stream pieces older than this many seconds.
  - name: NETWORK_BROADCAST_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to turn on Networks (your own pseudo-TV channels).
  - name: ALLOW_PRIVATE_WEBHOOK_URLS
    group: Features
    default: "false"
    description: >-
      Set to true so post-processing webhooks can call local addresses, like
      Jellyfin or Emby on your network.
  - name: NGINX_READ_TIMEOUT
    group: Server
    default: "900"
    description: >-
      How many seconds a player may take to download a big playlist or EPG.
  - name: LOG_LEVEL
    group: Logs
    default: debug
    description: >-
      How much the app logs, like error, warning, info or debug.
---

# M3U Editor

A full-featured IPTV editor, like xTeVe or Threadfin. It handles playlists, EPG data and Xtream API output. This uses upstream's own all-in-one image: PostgreSQL, Redis and the m3u-proxy stream proxy all run inside the one container.

## Features

- Works with m3u, m3u8, m3u+ and Xtream Codes API sources
- EPG from XMLTV files, XMLTV URLs and Schedules Direct
- Xtream API output and series management with `.strm` file sync
- Post processing with custom scripts, webhooks and email
- Built-in stream proxy with Redis pooling for smoother playback
- Sign in with your own OIDC provider, if you want

## How to use

1. Open M3U Editor from your dashboard.
2. Sign in with user name `admin` and password `admin`.
3. Change the admin password right away.
4. Add a playlist from your IPTV provider.
5. Add an EPG source to get a TV guide.
6. Copy your output playlist or Xtream link into Plex, Jellyfin, Emby or any IPTV player.

## Before you install

`APP_URL` starts as `http://localhost:6153`. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6153`, so playlist and EPG links work on other devices. `PG_PASSWORD` and `DB_PASSWORD` are filled in with a random password; if you change one, change the other to the same value (letters and numbers only) before the first start, because it is locked in then. The first start takes about two minutes. Sign in with `admin` / `admin` and change the password. OIDC sign-in and the stream proxy settings are in the Variables tab; add them in the app settings.
