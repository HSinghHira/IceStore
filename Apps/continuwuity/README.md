---
site: https://continuwuity.org
source: https://forgejo.ellis.link/continuwuation/continuwuity
services:
  - { name: Matrix API, path: /, icon: server }
screenshots: [Chatting in a Matrix app]
variables:
  - name: CONTINUWUITY_ALLOW_REGISTRATION
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false so nobody new can register. Even when true, people need a
      registration token.
  - name: CONTINUWUITY_REGISTRATION_TOKEN
    group: Sign-up and accounts
    default: ""
    description: >-
      A fixed token new people must type to register. You can also make
      tokens in the admin room with !admin token.
  - name: CONTINUWUITY_SUSPEND_ON_REGISTER
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so new accounts (after the first admin) are read-only
      until an admin lets them in.
  - name: CONTINUWUITY_NEW_USER_DISPLAYNAME_SUFFIX
    group: Sign-up and accounts
    default: "🏳️‍⚧️"
    description: >-
      Text added after every new user's display name. Set it to an empty
      value to add nothing.
  - name: CONTINUWUITY_AUTO_JOIN_ROOMS
    group: Sign-up and accounts
    default: "[]"
    description: >-
      Rooms new users join on their own, like ["#welcome:matrix.example.com"].
  - name: CONTINUWUITY_ALLOW_DEACTIVATION
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false so users cannot delete their own accounts.
  - name: CONTINUWUITY_EMERGENCY_PASSWORD
    group: Sign-up and accounts
    default: ""
    description: >-
      Lets you sign in as the server's own bot account to fix a locked-out
      admin. Remove it again when you are done.
  - name: CONTINUWUITY_WELL_KNOWN__CLIENT
    group: Server and delegation
    default: ""
    description: >-
      The HTTPS address Matrix apps should use, like
      https://matrix.example.com. Served at /.well-known/matrix/client.
  - name: CONTINUWUITY_WELL_KNOWN__SERVER
    group: Server and delegation
    default: ""
    description: >-
      Where other servers reach you, with a port, like
      matrix.example.com:443. Served at /.well-known/matrix/server.
  - name: CONTINUWUITY_WELL_KNOWN__SUPPORT_EMAIL
    group: Server and delegation
    default: ""
    description: >-
      A contact email shown at /.well-known/matrix/support.
  - name: CONTINUWUITY_WELL_KNOWN__SUPPORT_MXID
    group: Server and delegation
    default: ""
    description: >-
      A contact Matrix user shown at /.well-known/matrix/support, like
      @admin:matrix.example.com.
  - name: CONTINUWUITY_MAX_REQUEST_SIZE
    group: Server and delegation
    default: "20971520"
    description: >-
      The biggest upload in bytes. 20971520 is 20 MB.
  - name: CONTINUWUITY_ALLOW_FEDERATION
    group: Federation and rooms
    default: "true"
    description: >-
      Set to false to keep the server private, with no contact with other
      Matrix servers.
  - name: CONTINUWUITY_TRUSTED_SERVERS
    group: Federation and rooms
    default: '["matrix.org"]'
    description: >-
      Servers trusted to share other servers' signing keys.
  - name: CONTINUWUITY_ALLOW_ENCRYPTION
    group: Federation and rooms
    default: "true"
    description: >-
      Set to false to stop new encrypted rooms.
  - name: CONTINUWUITY_ALLOW_ROOM_CREATION
    group: Federation and rooms
    default: "true"
    description: >-
      Set to false so only admins can make rooms.
  - name: CONTINUWUITY_ALLOW_PUBLIC_ROOM_DIRECTORY_OVER_FEDERATION
    group: Federation and rooms
    default: "false"
    description: >-
      Set to true to let other servers see your public room list.
  - name: CONTINUWUITY_LOCKDOWN_PUBLIC_ROOM_DIRECTORY
    group: Federation and rooms
    default: "false"
    description: >-
      Set to true so only admins can add rooms to the public room list.
  - name: CONTINUWUITY_FORBIDDEN_REMOTE_SERVER_NAMES
    group: Federation and rooms
    default: "[]"
    description: >-
      Servers to block completely, like ["badserver.example"].
  - name: CONTINUWUITY_ALLOW_OUTGOING_PRESENCE
    group: Federation and rooms
    default: "false"
    description: >-
      Set to true to share online status with other servers.
  - name: CONTINUWUITY_URL_PREVIEW_DOMAIN_EXPLICIT_ALLOWLIST
    group: Federation and rooms
    default: "[]"
    description: >-
      Sites allowed to make link previews, like ["*"] for all. Empty means
      no link previews.
  - name: CONTINUWUITY_TURN_URIS
    group: Voice and video
    default: "[]"
    description: >-
      Your TURN server for calls, like ["turn:turn.example.com:3478?transport=udp"].
  - name: CONTINUWUITY_TURN_SECRET
    group: Voice and video
    default: ""
    description: >-
      The shared secret of your TURN server.
  - name: CONTINUWUITY_SMTP__CONNECTION_URI
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtps://user:password@smtp.example.com:465
      (write @ in the user name as %40). Turns on password-reset emails.
  - name: CONTINUWUITY_SMTP__SENDER
    group: Email (SMTP)
    default: ""
    description: >-
      The sender on emails, like Matrix <matrix@example.com>.
  - name: CONTINUWUITY_SMTP__REQUIRE_EMAIL_FOR_REGISTRATION
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to let anyone register with just an email address.
  - name: CONTINUWUITY_SMTP__REQUIRE_EMAIL_FOR_TOKEN_REGISTRATION
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true so people who register with a token must also give an
      email.
  - name: CONTINUWUITY_OAUTH__OIDC__DISCOVERY_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      Your sign-in provider's address, like https://pocketid.example.com.
      When set, only Matrix apps with the new OAuth login can sign in.
  - name: CONTINUWUITY_OAUTH__OIDC__CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The Client ID of the app you made for Continuwuity in your provider.
  - name: CONTINUWUITY_OAUTH__OIDC__CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The Client Secret of that app.
  - name: CONTINUWUITY_OAUTH__OIDC__PROVIDER_NAME
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's name shown to users, like Pocket ID.
  - name: CONTINUWUITY_LOG
    group: Logs
    default: info
    description: >-
      How much to log: error, warn, info, debug or trace.
---

# Continuwuity (Matrix)

Continuwuity is a community-run Matrix homeserver written in Rust, a lean and actively maintained alternative to Synapse that runs well on small hardware. Chat with your own people, or with anyone on the Matrix network, from any Matrix app.

## Features

- Fast, memory-safe Rust server for small and medium homeservers
- Federates with the whole Matrix network, or keep it private
- Bridges (appservices) to Discord, Telegram and more
- Built-in RocksDB database, no second container
- Manage users and rooms from an admin room inside Matrix, no web dashboard needed

## How to use

1. Before you install, set `CONTINUWUITY_SERVER_NAME` to your Matrix domain. It can not be changed later.
2. To talk to other Matrix servers, point that domain at your server and put an HTTPS reverse proxy in front of port 6146.
3. Start the app and open its logs. Find the one-time registration token printed on first start.
4. Open a Matrix app (Element, Cinny, FluffyChat), choose your server, and register the first account with that token.
5. The first account is the admin and is invited to the admin room. Manage the server from there.

## Before you install

Set `CONTINUWUITY_SERVER_NAME` to your Matrix domain, like `matrix.example.com`, or for home use only to your ZimaOS IP and port, like `192.168.1.20:6146`. It can never be changed without deleting all data. If your domain is served from another host or port, add `CONTINUWUITY_WELL_KNOWN__CLIENT` and `CONTINUWUITY_WELL_KNOWN__SERVER` from the Variables tab. The server starts in a few seconds; the one-time registration token for the first account is in the app logs. More settings, like sign-up rules, federation and email, are in the Variables tab; add them in the app settings. List settings are written like `["matrix.org"]`.
