---
name: Fluxer
site: https://fluxer.com
source: https://github.com/fluxerapp/fluxer
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Panel, path: /admin, icon: server }
screenshots: [Desktop and mobile]
variables:
  - name: FLUXER_SETUP_TOKEN
    group: Server
    default: ""
    description: >-
      The token the setup page asks for before it creates the first admin
      account. Leave it out to use the one made on first start (shown in
      the CREDENTIALS box in the logs).
  - name: FLUXER_APP_PRODUCT_NAME
    group: Server
    default: ""
    description: >-
      The name the apps show, like "Family Chat". Only used until you finish
      the setup page; after that, change it in the admin panel.
  - name: FLUXER_ACCOUNT_IDENTITY
    group: Sign-up and accounts
    default: ""
    description: >-
      How people sign in on a new server: username or email. Read only on
      the first start; the setup page asks again.
  - name: FLUXER_AUTO_JOIN_INVITE_CODE
    group: Sign-up and accounts
    default: ""
    description: >-
      One or more invite codes, separated by commas. New accounts join
      those communities.
  - name: FLUXER_BREACHED_PASSWORD_CHECK_ENABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to refuse passwords found in known data breaches (checks
      api.pwnedpasswords.com).
  - name: FLUXER_DISCOVERY_ENABLED
    group: Features
    default: "true"
    description: >-
      Set to false to turn off community discovery.
  - name: FLUXER_KLIPY_API_KEY
    group: Features
    default: ""
    description: >-
      Your Klipy API key for GIF search. GIF search is off without it (or
      without a key saved in the admin panel).
  - name: FLUXER_YOUTUBE_API_KEY
    group: Features
    default: ""
    description: >-
      A YouTube Data API v3 key for YouTube link previews.
  - name: FLUXER_EMAIL_DELIVERY
    group: Email (SMTP)
    default: "off"
    description: >-
      Set to smtp to send email (sign-up checks, password resets). You can
      also set email up in the admin panel.
  - name: FLUXER_EMAIL_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com.
  - name: FLUXER_EMAIL_SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port.
  - name: FLUXER_EMAIL_SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: FLUXER_EMAIL_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: FLUXER_EMAIL_SMTP_TLS_MODE
    group: Email (SMTP)
    default: ""
    description: >-
      implicit (usually port 465), starttls (usually 587), opportunistic or
      none. Left out, port 465 uses implicit and other ports starttls.
  - name: FLUXER_EMAIL_FROM_EMAIL
    group: Email (SMTP)
    default: ""
    description: >-
      The address email comes from. Left out, it is noreply@ and the host in
      PUBLIC_URL.
  - name: FLUXER_EMAIL_FROM_NAME
    group: Email (SMTP)
    default: ""
    description: >-
      The sender name on email. Left out, it is the server's name.
  - name: FLUXER_LIVEKIT_NODE_IP
    group: Voice and video
    default: ""
    description: >-
      The public IP that calls connect to. Left out, it is the IP in
      PUBLIC_URL, or (with a domain) your public IP found through STUN.
  - name: FLUXER_LIVEKIT_TURN_SERVERS
    group: Voice and video
    default: "[]"
    description: >-
      TURN servers for calls behind a tunnel, as JSON, like
      [{"host":"turn.example.com","port":3478,"protocol":"udp","username":"fluxer","credential":"a-long-password"}].
  - name: FLUXER_ADMIN_SSO_ISSUER
    group: Admin panel sign-in
    default: ""
    description: >-
      An OpenID Connect issuer URL for signing in to the admin panel with
      your own identity provider.
  - name: FLUXER_ADMIN_SSO_CLIENT_ID
    group: Admin panel sign-in
    default: ""
    description: >-
      The client ID from your identity provider.
  - name: FLUXER_ADMIN_SSO_CLIENT_SECRET
    group: Admin panel sign-in
    default: ""
    description: >-
      The client secret from your identity provider.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much the API and worker log: trace, debug, info, warn, error or
      fatal.
  - name: RUST_LOG
    group: Logs
    default: info
    description: >-
      How much the Rust services (media, push, admin, ...) log, like debug
      or warn.
---

# Fluxer

Fluxer is a free and open source instant messaging and VoIP chat app, Discord-style: communities, channels, direct messages, voice and video. This is Fluxer in a single container, with PostgreSQL, Valkey, NATS, Meilisearch, SeaweedFS file storage and LiveKit inside, one web port and one data folder. Every key and password is made for you on first start.

## Features

- Communities with text and voice channels, roles and invites
- Direct messages and group chats, reactions, link previews and search
- File uploads, custom emoji and stickers
- Voice and video calls and screen sharing through LiveKit (needs HTTPS)
- Admin panel at `/admin`, and the Fluxer desktop and mobile apps can connect to your server

## How to use

1. Set `PUBLIC_URL` to your ZimaOS IP (or your HTTPS domain) before you install.
2. Open Fluxer from your dashboard.
3. Enter the setup token from the app's logs to create the admin account.
4. Make a community and invite your friends with an invite link.
5. The admin panel is at `http://[ZIMAOS-IP-ADDRESS]:6692/admin`.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6692`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6692`. Fluxer only works at the one address you give it; until you set it, it shows a "set PUBLIC_URL" page.

Over plain http, chat, uploads and the admin panel work, but browsers turn off the microphone, camera, screen sharing, passkeys and notifications. For those, use HTTPS: point a reverse proxy (Nginx Proxy Manager, Caddy, a Cloudflare tunnel) with your own domain at `http://[ZIMAOS-IP-ADDRESS]:6692` and set `PUBLIC_URL` to the domain, like `https://chat.example.com`. Let the proxy accept uploads up to 512 MB and keep websockets open.

Calls connect straight to ports 6693 (TCP) and 6694 (UDP), not through the proxy. Keep those numbers, and forward both in your router to call from outside your home. Behind a tunnel, calls need a TURN server (`FLUXER_LIVEKIT_TURN_SERVERS`).

The first start takes about five minutes. The setup token is in the app's logs, in the box marked CREDENTIALS, printed again on every start. Fluxer runs about 20 services, so give it at least 4 GB of memory. More settings (email, GIF search, sign-in rules) are in the Variables tab; add them in the app settings. The keys in `/data/state/secrets.env` must never change once Fluxer has data, so back up the whole data folder.
