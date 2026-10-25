---
name: Stoat Chat
site: https://stoat.chat
source: https://github.com/stoatchat/self-hosted
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API, path: /api/, icon: server }
screenshots: [Server, Channels, Messages, Voice, Settings, Profile, Mobile]
variables:
  - name: REVOLT__API__REGISTRATION__INVITE_ONLY
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so people need an invite code to make an account. Make
      codes in the database, as upstream's guide shows.
  - name: REVOLT__API__USERS__MIN_USERNAME_LENGTH
    group: Sign-up and accounts
    default: "2"
    description: >-
      The shortest user name people can pick.
  - name: REVOLT__API__SECURITY__CAPTCHA__HCAPTCHA_KEY
    group: Sign-up and accounts
    default: "0x0000000000000000000000000000000000000000"
    description: >-
      Your hCaptcha secret key, to stop bots signing up. The default is
      hCaptcha's test key, which always passes.
  - name: REVOLT__API__SECURITY__CAPTCHA__HCAPTCHA_SITEKEY
    group: Sign-up and accounts
    default: 10000000-ffff-ffff-ffff-000000000001
    description: >-
      Your hCaptcha site key, together with the secret key above.
  - name: REVOLT__API__SMTP__HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. With it, new accounts must
      confirm their email and people can reset passwords. Leave it out to
      skip email checks.
  - name: REVOLT__API__SMTP__PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port.
  - name: REVOLT__API__SMTP__USE_TLS
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false for a mail server without TLS.
  - name: REVOLT__API__SMTP__USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: REVOLT__API__SMTP__PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: REVOLT__API__SMTP__FROM_ADDRESS
    group: Email (SMTP)
    default: noreply@example.com
    description: >-
      The sender address on emails. Most mail servers need this to be an
      address they own.
  - name: STOAT_VOICE_IP
    group: Voice and video
    default: ""
    description: >-
      The IP address browsers send call audio and video to. Leave it out to
      use the IP in PUBLIC_URL, or your public IP when PUBLIC_URL is a
      domain.
  - name: REVOLT__FEATURES__LIMITS__DEFAULT__VIDEO_RESOLUTION
    group: Voice and video
    default: "[1280, 720]"
    description: >-
      The largest video size in calls, like [1920, 1080].
  - name: REVOLT__API__SECURITY__TENOR_KEY
    group: Features
    default: ""
    description: >-
      A Tenor API key, to turn on the GIF picker.
  - name: REVOLT__FEATURES__WEBHOOKS_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to let people make webhooks in channels.
  - name: REVOLT__FEATURES__LIMITS__DEFAULT__FILE_UPLOAD_SIZE_LIMIT__ATTACHMENTS
    group: Features
    default: "20000000"
    description: >-
      The largest attachment, in bytes. Also raise
      REVOLT__FEATURES__LIMITS__GLOBAL__BODY_LIMIT_SIZE above it.
  - name: REVOLT__FEATURES__LIMITS__GLOBAL__BODY_LIMIT_SIZE
    group: Features
    default: "20000000"
    description: >-
      The largest upload request, in bytes.
  - name: REVOLT__FEATURES__LIMITS__DEFAULT__SERVERS
    group: Features
    default: "100"
    description: >-
      How many servers each person can make or join.
  - name: REVOLT__FEATURES__LEGAL_LINKS__TERMS_OF_SERVICE
    group: Features
    default: ""
    description: >-
      A link to your terms of service, shown at sign-up.
  - name: REVOLT__FEATURES__LEGAL_LINKS__PRIVACY_POLICY
    group: Features
    default: ""
    description: >-
      A link to your privacy policy, shown at sign-up.
  - name: RUST_LOG
    group: Logs
    default: info
    description: >-
      How much the Stoat services log: error, warn, info or debug.
---

# Stoat Chat

Stoat Chat (formerly Revolt) is an open-source chat platform for communities, friends and teams: servers, channels, direct messages and voice. This is Stoat in a single container, with MongoDB, Redis, RabbitMQ, Silo file storage and LiveKit inside, one web port and one data folder. Every key (file encryption, push notifications, LiveKit) is made for you on first start.

## Features

- Servers, channels, roles, direct messages and group chats
- File uploads, emojis, link previews and a GIF picker
- Voice and video calls through LiveKit (needs HTTPS in the browser)
- Bots and webhooks
- Only the web port and LiveKit's two media ports are published

## How to use

1. Open Stoat from your dashboard.
2. Make your account. The first account is a normal account; Stoat has no separate admin login.
3. Make a server and invite your friends with an invite link.
4. For voice and video, open Stoat over HTTPS.

## Before you install

`PUBLIC_URL` starts as `http://localhost:6167`. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6167`. Text chat works over plain HTTP, but browsers only allow the microphone and camera over HTTPS, so for voice and video put Stoat behind a reverse proxy with your own domain and set `PUBLIC_URL` to it. Keep ports 6168 (TCP) and 6169 (UDP) the same inside and outside, and forward them in your router to call from outside your home. MongoDB needs a 64-bit CPU with AVX (Intel or AMD) or ARM v8.2 and newer, so it won't run on older Celeron boards such as the ZimaBoard 1. The first start takes about three minutes. Invite-only sign-up, email, the GIF picker and every other Revolt.toml setting are in the Variables tab as `REVOLT__SECTION__KEY` variables; add them in the app settings.
