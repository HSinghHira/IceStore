---
site: https://k7.kaybi.dev
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Home, Movie details, Movies, Series, Music album, Explore]
variables:
  - name: ADMIN_EMAIL
    group: Sign-up and accounts
    default: ""
    description: >-
      An email for the admin account made on first start. Leave it out to
      make the admin without an email.
  - name: Authentication__Local__RegistrationEnabled
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to let anyone make an account at /sign-up. Otherwise the
      admin adds users.
  - name: Authentication__Local__SignInEnabled
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn off user name and password sign-in, so people
      sign in with OIDC only. Turn on OIDC first.
  - name: Authentication__Oidc__Enabled
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to sign in with Authentik, Pocket ID, Authelia, Keycloak or
      another OIDC server. Set PUBLIC_URL to your real address first.
  - name: Authentication__Oidc__Authority
    group: Sign in with OIDC
    default: ""
    description: >-
      The issuer URL of your OIDC server, like
      https://auth.example.com/application/o/k7/.
  - name: Authentication__Oidc__ClientId
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your OIDC server.
  - name: Authentication__Oidc__ClientSecret
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your OIDC server. Its redirect URI is
      PUBLIC_URL followed by /api/authentication/callback/login/oidc.
  - name: Authentication__Oidc__Scopes
    group: Sign in with OIDC
    default: "openid,profile"
    description: >-
      Scopes asked from the OIDC server, separated by commas.
  - name: Authentication__Oidc__DisplayName
    group: Sign in with OIDC
    default: ""
    description: >-
      The text on the sign-in button, like Authentik.
  - name: Authentication__Oidc__AutomaticAccountCreation
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false so only people who already have a K7 account can sign in
      with OIDC.
  - name: Authentication__Oidc__WebSessionLifetime
    group: Sign in with OIDC
    default: "7.00:00:00"
    description: >-
      How long an OIDC sign-in lasts in the browser, as days.hours:minutes:seconds.
  - name: Server__Name
    group: Server
    default: ""
    description: >-
      A name for this server, shown in federation invites and in link
      previews.
  - name: Security__ForceHttps
    group: Server
    default: "false"
    description: >-
      Set to true when K7 is only used through an https reverse proxy. Keep
      false for http:// addresses, or sign-in fails.
  - name: Security__TrustPrivateProxies
    group: Server
    default: "true"
    description: >-
      Set to false to stop trusting reverse proxies on private networks.
      Then list them in Security__KnownProxies__0, __1 and so on.
  - name: Security__KnownProxies__0
    group: Server
    default: ""
    description: >-
      The IP or network of a reverse proxy to trust, like 10.0.0.5 or
      172.16.0.0/12. Add more as Security__KnownProxies__1 and so on.
  - name: AllowedHosts
    group: Server
    default: "*"
    description: >-
      The host names K7 answers to, separated by semicolons. * answers to
      all.
  - name: Cors__Origins__0
    group: Server
    default: ""
    description: >-
      Another web address allowed to call K7's API. Only needed when the web
      client is hosted somewhere else.
  - name: Security__Federation__AllowInsecurePeerHttp
    group: Federation
    default: "false"
    description: >-
      Set to true to share with other K7 servers on plain http:// addresses.
  - name: Security__Federation__BlockPrivatePeerUrls
    group: Federation
    default: "false"
    description: >-
      Set to true to refuse K7 servers on private network addresses.
  - name: Serilog__MinimumLevel__Default
    group: Logs
    default: Warning
    description: >-
      How much K7 writes to its log: Debug, Information, Warning or Error.
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    group: Logs
    default: ""
    description: >-
      An OpenTelemetry collector address to send logs and metrics to.
---

# K7

K7 is a media server you host yourself, like Plex, Jellyfin or Emby, made for a small circle of family and friends. Watch your movies and series and play your music in the browser, on Android and Android TV, Windows, iOS and Mac. This is K7 in a single container, with PostgreSQL inside, one port and one data folder. Secret keys and the admin account are made for you on first start.

## Features

- Movies, series and music libraries with artwork and editable details
- Transcoding with ffmpeg, with Intel and AMD hardware acceleration when the box has a GPU
- Playlists, smart playlists, collections, history and statistics
- Sync Play, shared profiles, remote control and Chromecast
- Two-factor sign-in, guest mode and optional OIDC single sign-on
- Works with OpenSubsonic music apps
- Import from Plex, Jellyfin and Spotify; share with friends' K7 servers (federation)

## How to use

1. Open K7 from your dashboard.
2. Sign in with the admin user name and password.
3. Go to Administration, Content, Library, New library. Pick `/media` or any folder you added.

## Before you install

Put your movies, series and music in `/DATA/Media` (in folders like `Movies`, `Series` and `Music`), or change the `/media` folder in the app settings to where they are. You can also add more folders in the app settings, at any container path like `/movies`, `/tv` or `/doc`; K7 sees each one at that path. Leave `ADMIN_PASSWORD` blank to get a random one, shown in the app log as "admin password is", or type your own with 10 or more characters, an uppercase letter, a lowercase letter and a number. Watching works from every device with the default `PUBLIC_URL`; for OIDC sign-in or federation, set it to `http://[ZIMAOS-IP-ADDRESS]:6186`, like `http://192.168.1.20:6186`, or your https address. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. The first start takes about 3 minutes. Hardware transcoding works on its own when the box has an Intel or AMD GPU; check it in Administration, Transcoding.
