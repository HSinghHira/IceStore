---
site: https://gamevau.lt
services:
  - { name: Web UI, path: /, icon: globe }
variables:
  - name: SERVER_REGISTRATION_DISABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so nobody new can register. Do this after you have made
      your own account.
  - name: SERVER_ACCOUNT_ACTIVATION_DISABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so new accounts work at once, without an admin turning
      them on first.
  - name: SERVER_ADMIN_USERNAME
    group: Sign-up and accounts
    default: ""
    description: >-
      Makes this existing user an admin on every start. It does not create
      the account.
  - name: SERVER_ADMIN_PASSWORD
    group: Sign-up and accounts
    default: ""
    description: >-
      Sets the password of SERVER_ADMIN_USERNAME on every start. Use it to
      get back in if you forgot it, then take it out again.
  - name: USERS_REQUIRE_EMAIL
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to ask for an email when people register.
  - name: AUTH_BASIC_AUTH_ENABLED
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn off username and password sign-in, so everyone
      signs in with OAuth2.
  - name: AUTH_OAUTH2_ENABLED
    group: Sign in with OAuth2
    default: "false"
    description: >-
      Set to true to sign in with your own provider (authentik, Pocket ID,
      Keycloak). The callback URL to add there is PUBLIC_URL followed by
      /api/auth/oauth2/login.
  - name: AUTH_OAUTH2_AUTH_URL
    group: Sign in with OAuth2
    default: ""
    description: >-
      The authorization endpoint of your provider.
  - name: AUTH_OAUTH2_TOKEN_URL
    group: Sign in with OAuth2
    default: ""
    description: >-
      The token endpoint of your provider.
  - name: AUTH_OAUTH2_USERINFO_URL
    group: Sign in with OAuth2
    default: ""
    description: >-
      The userinfo endpoint of your provider.
  - name: AUTH_OAUTH2_CLIENT_ID
    group: Sign in with OAuth2
    default: ""
    description: >-
      The client ID from your provider.
  - name: AUTH_OAUTH2_CLIENT_SECRET
    group: Sign in with OAuth2
    default: ""
    description: >-
      The client secret from your provider.
  - name: AUTH_OAUTH2_SCOPES
    group: Sign in with OAuth2
    default: openid,email,profile
    description: >-
      The scopes asked for, comma separated.
  - name: AUTH_OAUTH2_CALLBACK_URL
    group: Sign in with OAuth2
    default: ""
    description: >-
      Leave it out to use PUBLIC_URL followed by /api/auth/oauth2/login.
  - name: METADATA_IGDB_CLIENT_ID
    group: Game details (IGDB)
    default: ""
    description: >-
      Your Twitch/IGDB client ID, for cover art and game details. Make one
      for free at dev.twitch.tv.
  - name: METADATA_IGDB_CLIENT_SECRET
    group: Game details (IGDB)
    default: ""
    description: >-
      Your Twitch/IGDB client secret.
  - name: METADATA_IGDB_ENABLED
    group: Game details (IGDB)
    default: "true"
    description: >-
      Set to false to stop looking games up on IGDB.
  - name: GAMES_SUPPORTED_FILE_FORMATS
    group: Games
    default: .zip,.7z,.rar
    description: >-
      The file types GameVault counts as games, comma separated.
  - name: GAMES_INDEX_INTERVAL_IN_MINUTES
    group: Games
    default: "60"
    description: >-
      How often GameVault checks the files folder for new games, in minutes.
  - name: GAMES_INDEX_USE_POLLING
    group: Games
    default: "false"
    description: >-
      Set to true if new games are not found on their own, for example when
      the games folder is a network share.
  - name: GAMES_SEARCH_RECURSIVE
    group: Games
    default: "true"
    description: >-
      Set to false to only look at the top of the files folder, not inside
      subfolders.
  - name: GAMES_SEARCH_EXCLUDE_DIR_REGEX
    group: Games
    default: ""
    description: >-
      Folders to skip, as a regular expression, like ^(tmp|incomplete)$.
  - name: GAMES_MAX_UPLOAD_SIZE
    group: Games
    default: 100 gb
    description: >-
      The largest game an admin can upload from the browser. 0 turns uploads
      off.
  - name: SAVEFILES_ENABLED
    group: Save files
    default: "true"
    description: >-
      Set to false to turn off save file syncing.
  - name: SAVEFILES_MAX_SIZE
    group: Save files
    default: 1 gb
    description: >-
      The largest save file people can upload.
  - name: SAVEFILES_MAX_SAVES
    group: Save files
    default: "10"
    description: >-
      How many saves are kept per game and user. The oldest go first.
  - name: PARENTAL_AGE_RESTRICTION_ENABLED
    group: Parental controls
    default: "false"
    description: >-
      Set to true to hide games that are rated above a user's age. People
      then give their birth date when they register.
  - name: PARENTAL_AGE_OF_MAJORITY
    group: Parental controls
    default: "18"
    description: >-
      The age at which a user sees every game.
  - name: MEDIA_MAX_SIZE
    group: Features
    default: 10 mb
    description: >-
      The largest image (cover, avatar) people can upload.
  - name: SERVER_MAX_DOWNLOAD_BANDWIDTH_IN_KBPS
    group: Features
    default: ""
    description: >-
      The top download speed per download, in KB/s. Leave it out for no
      limit.
  - name: SERVER_ONLINE_ACTIVITIES_DISABLED
    group: Features
    default: "false"
    description: >-
      Set to true so everyone always shows as offline.
  - name: SERVER_LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much GameVault writes to the log: debug, info, warn, error or off.
---

# GameVault

GameVault is a self-hosted gaming platform that lets you and your friends enjoy DRM-free games stored on your own server in an organized, Steam-like library. This is GameVault in a single container, with PostgreSQL inside, one port and one data folder plus your games folder. The database password is made for you on first start.

## Features

- Scans your games folder and finds titles, versions and file types on its own
- Cover art, screenshots and details from IGDB
- Many users with roles, online status and play time
- Save file syncing, so players can pick up where they left off on any device
- Web UI in the browser; the GameVault app for Windows downloads and installs games

## How to use

1. Open GameVault from your dashboard.
2. Register the first account. It becomes the admin.
3. Copy DRM-free games (`.zip`, `.7z` or `.rar`) into the files folder. GameVault finds them on its own.
4. Browse your library, add cover art and invite friends.
5. Players can also use the GameVault app for Windows with the address `http://your-zimaos-ip:6149`.

## Before you install

There is nothing you must set. The `/files` volume is your game library; point it at a games folder you already have if you like. The first start takes about five minutes. Open `http://your-zimaos-ip:6149` and register: the first account becomes the admin. Turn off sign-up afterwards with `SERVER_REGISTRATION_DISABLED`. `PUBLIC_URL` is only needed for OAuth2 sign-in; change `localhost` to your ZimaOS IP when you use it. Sign-up rules, IGDB keys, OAuth2 and the other settings are in the Variables tab; add them in the app settings.
