---
site: https://github.com/technomancer702/nodecast-tv
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: OIDC_ISSUER_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      The issuer URL of your OIDC provider (Authentik, Keycloak and others).
      Copy it exactly, with any trailing slash.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID your provider gave Nodecast TV.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret your provider gave Nodecast TV.
  - name: OIDC_CALLBACK_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      Where your provider sends people back after sign-in, like
      http://192.168.1.10:6112/api/auth/oidc/callback.
  - name: APP_ORIGIN
    group: Reverse proxy
    default: ""
    description: >-
      The outside address when Nodecast TV is behind a reverse proxy, like
      https://tv.example.com.
  - name: TRUST_PROXY
    group: Reverse proxy
    default: ""
    description: >-
      The IP or CIDR of a reverse proxy that is not on your local network.
      Local and private networks are trusted already.
  - name: AUTH_COOKIE_SECURE
    group: Reverse proxy
    default: ""
    description: >-
      Set to true to force secure cookies when HTTPS ends at your proxy.
  - name: ALLOW_LOCAL_MEDIA_URLS
    group: Sources
    default: "false"
    description: >-
      Set to true to allow providers on localhost.
---

# Nodecast TV

Nodecast TV is a self-hosted, web-based IPTV player for Live TV, an interactive EPG, and VOD Movies and Series. It is a lightweight Xtream Codes / M3U client built for large libraries and smooth playback.

## Features

- Live TV with fast channel zapping, category grouping and search
- Interactive EPG grid guide with a 24h timeline and search
- Movies and Series sections with posters and episode lists
- Favorites for channels, movies and series
- Admin and viewer accounts, plus optional OIDC single sign-on
- Hardware-accelerated transcoding (NVIDIA, AMD, Intel QuickSync, VAAPI)
- 5.1 to stereo audio downmix presets

## How to use

1. Open Nodecast TV from your dashboard.
2. Create your admin account.
3. Go to Settings, Content Sources and add your Xtream Codes or M3U provider.
4. Click "Refresh Sources" to load channels, movies and series.
5. Change transcoding and audio settings anytime under Settings, Transcoding.

## Before you install

Nothing needs to be set first. Create your admin account right after install. For single sign-on, add the `OIDC_*` settings from the Variables tab in the app settings; new SSO users start as viewers and an admin has to promote them. Behind an HTTPS reverse proxy, forward the `X-Forwarded-Proto` header. Hardware transcoding needs your GPU device added to the container in the app settings.
