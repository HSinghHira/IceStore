---
site: https://dawarich.app
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API Docs, path: /api-docs, icon: code }
screenshots: [Map, Timeline, Stats, Trips, Family]
variables:
  - name: APPLICATION_HOSTS
    group: Server
    default: ""
    description: >-
      The addresses Dawarich may be opened at, comma separated, like
      dawarich.example.com,192.168.1.20. Leave it out to allow any address.
  - name: ALLOW_EMAIL_PASSWORD_REGISTRATION
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true so anyone can make an account with email and password.
      Otherwise only people you invite (family) can join.
  - name: ALLOW_EMAIL_PASSWORD_LOGIN
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to hide the email and password form when OIDC sign-in is
      on, so people can only sign in with OIDC.
  - name: SMTP_SERVER
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Leave it out to send no emails.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server's port, usually 587, or 465 for TLS from the start.
  - name: SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address on emails, like dawarich@example.com.
  - name: SMTP_DOMAIN
    group: Email (SMTP)
    default: ""
    description: >-
      The domain Dawarich says hello as to the mail server. Most servers
      don't need it.
  - name: SMTP_SSL
    group: Email (SMTP)
    default: ""
    description: >-
      Set to true for TLS from the start. It turns on by itself with port
      465.
  - name: SMTP_STARTTLS
    group: Email (SMTP)
    default: "true"
    description: >-
      Set to false to not use STARTTLS on ports other than 465.
  - name: SMTP_AUTHENTICATION
    group: Email (SMTP)
    default: plain
    description: >-
      How to log in to the mail server: plain, login, cram_md5, or none for
      a server that needs no login.
  - name: SMTP_OPENSSL_VERIFY_MODE
    group: Email (SMTP)
    default: ""
    description: >-
      Set to none to skip checking the mail server's certificate, for a
      server on your network with a self-signed one.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your sign-in provider (Authentik, Authelia, Pocket
      ID, Keycloak...). Leave it out to keep OIDC sign-in off.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret. Leave it out for a public client with
      OIDC_PKCE_ENABLED set to true.
  - name: OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's issuer address, like
      https://auth.example.com/application/o/dawarich/.
  - name: OIDC_REDIRECT_URI
    group: Sign in with OIDC
    default: ""
    description: >-
      Your Dawarich address plus /users/auth/openid_connect/callback. Add
      the same address in your provider.
  - name: OIDC_PROVIDER_NAME
    group: Sign in with OIDC
    default: Openid Connect
    description: >-
      The name on the sign-in button, like Authentik.
  - name: OIDC_AUTO_REGISTER
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false so only people who already have an account (same email)
      can sign in with OIDC.
  - name: OIDC_PKCE_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true when your provider needs PKCE (Pocket ID does).
  - name: STORE_GEODATA
    group: Place names
    default: "true"
    description: >-
      Set to false to not keep reverse geocoding results.
  - name: PHOTON_API_HOST
    group: Place names
    default: ""
    description: >-
      A Photon server for place names, like photon.komoot.io or your own.
      Can also be set in Dawarich under Settings, Instance.
  - name: PHOTON_API_KEY
    group: Place names
    default: ""
    description: >-
      The API key for the Photon server, if it needs one.
  - name: PHOTON_API_USE_HTTPS
    group: Place names
    default: "false"
    description: >-
      Set to true when the Photon server uses HTTPS.
  - name: PHOTON_API_LANGUAGE
    group: Place names
    default: ""
    description: >-
      The language for place names from Photon, like en or de.
  - name: NOMINATIM_API_HOST
    group: Place names
    default: ""
    description: >-
      A Nominatim server for place names, instead of Photon.
  - name: NOMINATIM_API_KEY
    group: Place names
    default: ""
    description: >-
      The API key for the Nominatim server, if it needs one.
  - name: NOMINATIM_API_USE_HTTPS
    group: Place names
    default: "true"
    description: >-
      Set to false when the Nominatim server has no HTTPS.
  - name: GEOAPIFY_API_KEY
    group: Place names
    default: ""
    description: >-
      A Geoapify API key, to use Geoapify for place names.
  - name: LOCATIONIQ_API_KEY
    group: Place names
    default: ""
    description: >-
      A LocationIQ API key, to use LocationIQ for place names.
  - name: REVERSE_GEOCODING_RPS
    group: Place names
    default: ""
    description: >-
      The most place-name requests per second. Set it for services with a
      limit, like 1 for public Nominatim.
  - name: REVERSE_GEOCODING_CONCURRENCY
    group: Place names
    default: ""
    description: >-
      How many background jobs may look up place names at the same time.
  - name: STORAGE_BACKEND
    group: File storage
    default: local
    description: >-
      Where imports and exports are kept: local (the data folder) or s3.
  - name: AWS_ACCESS_KEY_ID
    group: File storage
    default: ""
    description: >-
      The S3 access key, when STORAGE_BACKEND is s3.
  - name: AWS_SECRET_ACCESS_KEY
    group: File storage
    default: ""
    description: >-
      The S3 secret key.
  - name: AWS_REGION
    group: File storage
    default: ""
    description: >-
      The S3 region, like us-east-1.
  - name: AWS_BUCKET
    group: File storage
    default: ""
    description: >-
      The S3 bucket name.
  - name: AWS_ENDPOINT_URL
    group: File storage
    default: ""
    description: >-
      The S3 server address, for S3-compatible storage like MinIO or Garage.
      Leave it out for Amazon S3.
  - name: VIDEO_RETENTION_DAYS
    group: Route videos
    default: "30"
    description: >-
      Delete route video files older than this many days. 0 keeps them
      forever.
  - name: VIDEO_MAX_PER_USER
    group: Route videos
    default: "10"
    description: >-
      Keep at most this many route videos per person. 0 means no limit.
  - name: BACKGROUND_PROCESSING_CONCURRENCY
    group: Performance
    default: "2"
    description: >-
      How many background jobs (imports, place names, stats) run at once.
      Raise it on a fast box.
  - name: VECTOR_TILES_QUERY_TIMEOUT_MS
    group: Performance
    default: "5000"
    description: >-
      How long one map tile query may take, in milliseconds. Raise it if
      very long date ranges don't show on the map.
  - name: SKIP_VISITS_FLEET_REDETECT
    group: Performance
    default: ""
    description: >-
      Set to 1 to skip finding visits again across all history after some
      updates. Each person can still start it under Visits.
---

# Dawarich

Dawarich keeps your location history on your own server, like Google Timeline (Location History). Send points from your phone, import your old Google data, and see where you've been on a map. This is Dawarich in a single container, with PostgreSQL (with PostGIS) and Redis inside, one port and one data folder. All secret keys and the first password are made for you on first start.

## Features

- Map of everywhere you've been, with a timeline per day
- Track your phone with the Dawarich app (iOS, Android), OwnTracks, Overland, GPSLogger or Home Assistant
- Import Google Takeout and Timeline, GPX, GeoJSON, OwnTracks and photo locations from Immich or Photoprism
- Visits and places, trips, countries and cities, yearly stats
- Share your location with family, and make route videos and posters
- Your data stays on your server; export it any time

## How to use

1. Open Dawarich from your dashboard.
2. Sign in as `demo@dawarich.app` with the password from the app logs (the line "Dawarich login is").
3. Change the email and password in Account settings.
4. Import your old data under Imports, or connect a phone app with the API key from Account settings and the server `http://[ZIMAOS-IP-ADDRESS]:6175`.

## Before you install

`PUBLIC_URL` starts as `http://localhost:6175`. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6175`, so links in emails work; Dawarich itself opens from any address. Leave `ADMIN_PASSWORD` empty to get a new password: it is in the app logs on the line "Dawarich login is" and in `admin-password.txt` in the data folder. The first start takes about five minutes. Email, OIDC sign-in, place names (reverse geocoding), S3 storage and the other settings are in the Variables tab; add them in the app settings. Plan for 1 to 4 GB of memory, more with large imports. To sync Strava activities into Dawarich, install Strava to Dawarich from IceStore too.
