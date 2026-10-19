---
site: https://github.com/UnifiedKings/helix
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Home, Search, Station creation, Station playback, Station tuning, Queue autofill, Add to queue, Play next, Reorder queue, Lobby]
variables:
  - name: SUBSONIC_BASE_URL
    group: Subsonic / Navidrome
    default: ""
    description: >-
      The address of your Navidrome or Subsonic server, like
      http://192.168.1.10:4533. You can also set it on Helix's Settings page.
  - name: SUBSONIC_USERNAME
    group: Subsonic / Navidrome
    default: ""
    description: >-
      Your Navidrome or Subsonic username.
  - name: SUBSONIC_PASSWORD
    group: Subsonic / Navidrome
    default: ""
    description: >-
      Your Navidrome or Subsonic password. Setting it on Helix's Settings page
      keeps it out of the app settings.
  - name: LISTENBRAINZ_TOKEN
    group: Discovery
    default: ""
    description: >-
      Your ListenBrainz API token from listenbrainz.org. Some station and
      discovery features work better with it.
  - name: HELIX_PREFETCH_AHEAD
    group: Discovery
    default: "3"
    description: >-
      How many tracks a station gets ready ahead of the one playing.
  - name: HELIX_LOBBY_YT_LINK_MAX_ITEMS
    group: Lobbies
    default: "100"
    description: >-
      The most tracks added when someone pastes a playlist or album link into a
      lobby.
  - name: HELIX_YTDLP_AUTO_UPDATE
    group: yt-dlp
    default: "true"
    description: >-
      Checks for a newer yt-dlp each time Helix starts. Set to false to only
      use the version inside the image.
  - name: HELIX_YTDLP_CHANNEL
    group: yt-dlp
    default: stable
    description: >-
      stable uses the latest stable yt-dlp. nightly also allows pre-release
      builds when a fix has not reached stable yet.
  - name: HELIX_ALLOW_NON_ADMIN_IMPORT
    group: Security
    default: "false"
    description: >-
      Set to true to let accounts that are not admins import music into the
      library. Only do this if you trust every account.
  - name: HELIX_ENABLE_CUSTOM_STATION_TYPES
    group: Security
    default: "false"
    description: >-
      Set to true to load Python station plugins from the custom_stations
      folder. That code runs inside Helix, so only use files you trust.
  - name: HELIX_ENABLE_API_DOCS
    group: Security
    default: "false"
    description: >-
      Set to true to publish the interactive API documentation.
  - name: HELIX_OIDC_ENABLED
    group: Sign in with authentik or OIDC
    default: "false"
    description: >-
      Set to true to show single sign-on on the login page. Local Helix
      accounts keep working.
  - name: HELIX_OIDC_DISPLAY_NAME
    group: Sign in with authentik or OIDC
    default: authentik
    description: >-
      The provider name shown on the login page, like authentik or Keycloak.
  - name: HELIX_OIDC_ISSUER
    group: Sign in with authentik or OIDC
    default: ""
    description: >-
      Your provider's issuer URL, like
      https://auth.example.com/application/o/helix/.
  - name: HELIX_OIDC_CLIENT_ID
    group: Sign in with authentik or OIDC
    default: ""
    description: >-
      The client ID your provider gave Helix.
  - name: HELIX_OIDC_CLIENT_SECRET
    group: Sign in with authentik or OIDC
    default: ""
    description: >-
      The client secret your provider gave Helix.
  - name: HELIX_OIDC_REDIRECT_URI
    group: Sign in with authentik or OIDC
    default: ""
    description: >-
      The callback URL, like https://helix.example.com/auth/oidc/callback. It
      must match the redirect URI set in your provider exactly.
  - name: HELIX_OIDC_SCOPES
    group: Sign in with authentik or OIDC
    default: openid profile email
    description: >-
      The scopes Helix asks for, separated by spaces.
  - name: HELIX_OIDC_USERNAME_CLAIM
    group: Sign in with authentik or OIDC
    default: preferred_username
    description: >-
      The claim used as the Helix username for a new single sign-on user.
  - name: HELIX_OIDC_GROUPS_CLAIM
    group: Sign in with authentik or OIDC
    default: groups
    description: >-
      The claim Helix reads to find a user's groups.
  - name: HELIX_OIDC_AUTO_CREATE_USERS
    group: Sign in with authentik or OIDC
    default: "true"
    description: >-
      Set to false so only people who already have a Helix account can sign
      in with single sign-on.
  - name: HELIX_OIDC_ALLOW_FIRST_USER_ADMIN
    group: Sign in with authentik or OIDC
    default: "false"
    description: >-
      Set to true to let the first single sign-on user become the admin when
      Helix has no accounts yet.
  - name: HELIX_OIDC_AUTO_LINK_BY_USERNAME
    group: Sign in with authentik or OIDC
    default: "false"
    description: >-
      Set to true to link a single sign-on user to the local account with the
      same username.
  - name: HELIX_OIDC_ADMIN_GROUP
    group: Sign in with authentik or OIDC
    default: ""
    description: >-
      The group whose members become Helix admins, like helix-admins. Used
      with HELIX_OIDC_SYNC_ROLES.
  - name: HELIX_OIDC_SYNC_ROLES
    group: Sign in with authentik or OIDC
    default: "false"
    description: >-
      Set to true to update each user's admin role from HELIX_OIDC_ADMIN_GROUP
      every time they sign in.
  - name: HELIX_LOGIN_BACKGROUND_UNSPLASH_ENABLED
    group: Login background
    default: "false"
    description: >-
      Set to true to show a random music photo from Unsplash on the login
      page. Needs HELIX_UNSPLASH_ACCESS_KEY.
  - name: HELIX_UNSPLASH_ACCESS_KEY
    group: Login background
    default: ""
    description: >-
      Your Unsplash API access key.
  - name: HELIX_LOGIN_BACKGROUND_UNSPLASH_QUERY
    group: Login background
    default: vinyl record player turntable music
    description: >-
      The words Helix searches Unsplash for.
  - name: HELIX_LOGIN_BACKGROUND_UNSPLASH_CACHE_SECONDS
    group: Login background
    default: "900"
    description: >-
      How many seconds Helix keeps the search results before it asks Unsplash
      again.
  - name: SLSKD_ENABLED
    group: slskd quality upgrades
    default: "false"
    description: >-
      Set to true to let Helix swap tracks it added for better copies found
      through your own slskd (Soulseek) server. slskd is not included.
  - name: SLSKD_URL
    group: slskd quality upgrades
    default: ""
    description: >-
      The address of your slskd server, like http://192.168.1.10:5030.
  - name: SLSKD_API_KEY
    group: slskd quality upgrades
    default: ""
    description: >-
      An API key made in slskd for Helix.
  - name: SLSKD_DOWNLOADS_PATH
    group: slskd quality upgrades
    default: ""
    description: >-
      The folder inside Helix where slskd's finished downloads appear. Add a
      volume that points at slskd's download folder first.
---

# Helix

Helix is a self-hosted music player, discovery tool and shared listening space built around a Subsonic-compatible music library, such as Navidrome.

## Features

- Search and play music from your Subsonic-compatible library
- Stations made from artists, artist collections or tags, which keep filling the queue
- Import playlists from Helix, YouTube Music, Spotify and Pandora, with a review step before anything is added
- Shared listening lobbies: join with a 5-letter code, with an optional password, and everyone hears the same thing
- Optional fulfillment: ask for music you don't have yet, and Helix fetches it, fixes its metadata and adds it to your library
- Optional sign-in with authentik or another OpenID Connect provider
- Custom station providers through a Python plugin system
- Still works, with fewer features, without a Subsonic server

## How to use

1. Open Helix from your dashboard.
2. Create the admin account on first launch.
3. If you run Navidrome or another Subsonic server, add its address, username and password on Helix's Settings page.
4. Search your library, start a station or build a queue.
5. Start a lobby to listen with others. Share the 5-letter code so they can join.
6. Turn on fulfillment and import only after your beets settings and music folder are set up the way you want.

## Before you install

Point the `/data/music` volume at your music folder, the same one Navidrome uses, or remove it if you won't import music. `HELIX_COOKIE_SECURE` is `false` so login works over plain `http://`; set it to `true` once Helix is behind HTTPS. Your Subsonic server, ListenBrainz token, single sign-on and other settings are in the Variables tab and are added in the app settings. The first start takes about a minute while Helix checks for a newer yt-dlp. This image is for amd64 only.
