---
site: https://heddohon.app
services:
  - { name: Web Player, path: /, icon: globe }
screenshots: [Album, Listening history, Lyrics, Recommendations, Sharing]
variables:
  - name: HEDDOHON_SECRET
    group: Server
    default: ""
    description: >-
      The secret that seals stored credentials and sessions, at least 32
      characters. Leave it out: the setup page makes one and keeps it in
      setup.json. Changing it signs everyone out.
  - name: HEDDOHON_SUBSONIC_URL
    group: Music servers
    default: ""
    description: >-
      Your Navidrome or Subsonic address, like http://192.168.1.20:4533.
      Leave it out to type it in the setup page instead.
  - name: HEDDOHON_SUBSONIC_LABEL
    group: Music servers
    default: Navidrome
    description: >-
      The name shown for that server.
  - name: HEDDOHON_JELLYFIN_URL
    group: Music servers
    default: ""
    description: >-
      Your Jellyfin address, like http://192.168.1.20:8096.
  - name: HEDDOHON_JELLYFIN_LABEL
    group: Music servers
    default: Jellyfin
    description: >-
      The name shown for that server.
  - name: ORIGIN
    group: Server
    default: ""
    description: >-
      The address people open, like https://music.example.com. Leave it out:
      the setup page saves it from your browser, and you can change it under
      Settings, Storage.
  - name: HEDDOHON_COOKIE_SECURE
    group: Server
    default: auto
    description: >-
      auto, true or false. Set to false if sign-in doesn't stick on a plain
      http:// address.
  - name: HEDDOHON_SESSION_HOURS
    group: Server
    default: "720"
    description: >-
      How many hours people stay signed in.
  - name: ADDRESS_HEADER
    group: Server
    default: ""
    description: >-
      Behind a reverse proxy: the header with the visitor's address, like
      X-Real-IP. Set it only when every request comes through the proxy.
  - name: HEDDOHON_COVER_CACHE_MB
    group: Storage
    default: "2048"
    description: >-
      Most space the album cover cache may use, in MB.
  - name: HEDDOHON_UPSTREAM_TIMEOUT_MS
    group: Storage
    default: "20000"
    description: >-
      How long to wait for the music server, in milliseconds.
  - name: HEDDOHON_DATABASE_URL
    group: Storage
    default: ""
    description: >-
      A PostgreSQL server instead of the built-in SQLite, like
      postgres://192.168.1.20:5432/heddohon. Use it with
      HEDDOHON_DATABASE_USER and HEDDOHON_DATABASE_PASSWORD.
  - name: HEDDOHON_DATABASE_USER
    group: Storage
    default: ""
    description: >-
      The PostgreSQL user.
  - name: HEDDOHON_DATABASE_PASSWORD
    group: Storage
    default: ""
    description: >-
      The PostgreSQL password.
  - name: HEDDOHON_SHARING
    group: Features
    default: "true"
    description: >-
      Set to false to turn off share links.
  - name: HEDDOHON_DOWNLOADS
    group: Features
    default: "true"
    description: >-
      Set to false to turn off downloads.
  - name: HEDDOHON_FOLDERS
    group: Features
    default: "true"
    description: >-
      Set to false to hide the folder view.
  - name: HEDDOHON_DEFAULT_THEME
    group: Features
    default: terminal
    description: >-
      The theme a new account starts in: terminal, liquid, paper or phosphor.
  - name: HEDDOHON_RADIO
    group: Features
    default: "true"
    description: >-
      Set to false to turn off internet radio.
  - name: HEDDOHON_REMOTE_CONTROL
    group: Features
    default: "true"
    description: >-
      Set to false so one browser can't control another.
  - name: HEDDOHON_LISTENERS
    group: Features
    default: "true"
    description: >-
      Set to false so accounts can't see what each other is playing.
  - name: HEDDOHON_PROFILES
    group: Features
    default: "true"
    description: >-
      Set to false to turn off profile pages.
  - name: HEDDOHON_MCP
    group: Features
    default: ""
    description: >-
      Set to true to let accounts connect an AI assistant (MCP) to their
      library, or false to block it. Leave it out to decide under Settings, AI.
  - name: HEDDOHON_REQUIRE_TWO_FACTOR
    group: Sign-in
    default: ""
    description: >-
      Set to true so every account must use an authenticator app or a
      passkey. Leave it out to let each account decide.
  - name: HEDDOHON_OIDC_ISSUER
    group: Sign-in
    default: ""
    description: >-
      Your OpenID Connect provider, like https://auth.example.com. Register
      Heddohon there with the redirect address <your address>/login/oidc/callback.
  - name: HEDDOHON_OIDC_CLIENT_ID
    group: Sign-in
    default: ""
    description: >-
      The client ID from your provider.
  - name: HEDDOHON_OIDC_CLIENT_SECRET
    group: Sign-in
    default: ""
    description: >-
      The client secret from your provider. Leave it out for a public client.
  - name: HEDDOHON_OIDC_LABEL
    group: Sign-in
    default: single sign-on
    description: >-
      The name on the "Sign in with" button.
  - name: HEDDOHON_LOGIN_HINT
    group: Sign-in
    default: ""
    description: >-
      A line shown on the sign-in page, like "Use your Navidrome login."
  - name: HEDDOHON_APP_NAME
    group: Sign-in
    default: Heddohon
    description: >-
      The name shown on the sign-in page.
  - name: HEDDOHON_LYRICS_LRCLIB
    group: Online services
    default: ""
    description: >-
      Set to true to fetch lyrics from lrclib.net.
  - name: HEDDOHON_AUTOEQ
    group: Online services
    default: ""
    description: >-
      Set to true to fetch AutoEq headphone corrections.
  - name: HEDDOHON_NEW_RELEASES
    group: Online services
    default: ""
    description: >-
      Set to true to look up new releases on MusicBrainz.
  - name: HEDDOHON_DISCORD
    group: Online services
    default: ""
    description: >-
      Set to true to allow Discord sharing.
  - name: HEDDOHON_LISTENBRAINZ
    group: Online services
    default: ""
    description: >-
      Set to true to allow scrobbling to ListenBrainz.
  - name: HEDDOHON_NAVIDROME_PLUGIN_TOKEN
    group: Online services
    default: ""
    description: >-
      Turns on the Heddohon plugin for Navidrome. At least 32 characters,
      not the same as HEDDOHON_SECRET. The plugin takes the same value.
  - name: HEDDOHON_LOG_LEVEL
    group: Logs
    default: error
    description: >-
      error, warn, info or debug.
  - name: HEDDOHON_LOG_FORMAT
    group: Logs
    default: ""
    description: >-
      Set to json for machine-readable logs.
---

# Heddohon

Heddohon is a web music player you host yourself, in front of the Navidrome, Subsonic or Jellyfin server you already run. The browser only talks to Heddohon, so your music server can stay private.

## Features

- Listen together: send a link and everyone hears what you play, as you play it
- Share a song, an album or a playlist with anyone, no account needed
- Your play history kept on your server: top artists, listening hours, "on this day" and daily mixes
- Original files up to FLAC 24/192, or transcoded to MP3, Opus or AAC
- Crossfade, ReplayGain, sleep timer, equaliser with AutoEq, synced lyrics, internet radio, Chromecast and AirPlay
- Four themes coloured by the artwork, and a keyboard command line (Ctrl+K)
- Two-step sign-in, passkeys and single sign-on (OIDC)

## How to use

1. Open Heddohon from your dashboard.
2. Type the setup code from the app log.
3. Type your music server's address, like `http://[ZIMAOS-IP-ADDRESS]:4533` for Navidrome.
4. Sign in with your account on the music server and press play.

## Before you install

You need a Navidrome, Subsonic or Jellyfin server with your music; Heddohon has no music of its own. Nothing has to be set before installing. After the start (a few seconds), find the setup code in the app log, open `http://[ZIMAOS-IP-ADDRESS]:6135`, type the code and your music server's address. The setup page makes the secret key and keeps it in the data folder. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default.
