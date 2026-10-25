---
site: https://useindelible.com
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: AUTH_ALLOW_SIGNUPS
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true while you let more people make an account. The first
      account can always sign up.
  - name: OIDC_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to sign in with your own OIDC provider (Authentik,
      ZITADEL, Pocket ID...).
  - name: OIDC_ISSUER_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      Your provider's issuer address, like
      https://auth.example.com/application/o/indelible/.
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
  - name: OIDC_PROVIDER_NAME
    group: Sign in with OIDC
    default: OpenID Connect
    description: >-
      The name on the sign-in button.
  - name: OIDC_SCOPES
    group: Sign in with OIDC
    default: openid,email,profile
    description: >-
      The scopes to ask for, separated by commas.
  - name: OIDC_AUTO_CREATE_USERS
    group: Sign in with OIDC
    default: "true"
    description: >-
      Set to false so only people who already have an account can sign in
      with OIDC.
  - name: NOTION_CLIENT_ID
    group: Notion sync
    default: ""
    description: >-
      The client ID of your Notion integration, for Notion export and sync.
  - name: NOTION_CLIENT_SECRET
    group: Notion sync
    default: ""
    description: >-
      The client secret of your Notion integration.
  - name: NOTION_REDIRECT_URL
    group: Notion sync
    default: "<PUBLIC_URL>/api/v1/integrations/notion/callback"
    description: >-
      The callback address to register at Notion. It is made from PUBLIC_URL,
      so you rarely need to set it.
  - name: EMAIL_FEED_DOMAIN
    group: Save by email
    default: ""
    description: >-
      The domain for newsletter addresses (<token>@this-domain). Set it only
      together with the email provider settings below.
  - name: EMAIL_LIBRARY_DOMAIN
    group: Save by email
    default: ""
    description: >-
      The domain for one-off forward addresses.
  - name: EMAIL_INGEST_PROVIDER
    group: Save by email
    default: resend
    description: >-
      The service that receives your emails and passes them on.
  - name: EMAIL_INGEST_WEBHOOK_SECRET
    group: Save by email
    default: ""
    description: >-
      The webhook signing secret from that service.
  - name: RESEND_API_KEY
    group: Save by email
    default: ""
    description: >-
      Your Resend API key.
  - name: EXTENSION_REDIRECT_URIS
    group: Browser extension
    default: ""
    description: >-
      Callback addresses for your own builds of the browser extension, comma
      separated. Leave it out for the official Chrome and Firefox
      extensions.
  - name: UPLOAD_MAX_BYTES
    group: Uploads
    default: "52428800"
    description: >-
      The largest file you can upload to your library, in bytes.
  - name: IMPORT_UPLOAD_MAX_BYTES
    group: Uploads
    default: "209715200"
    description: >-
      The largest Readwise import, in bytes.
  - name: FEED_DEFAULT_POLL_INTERVAL_MINUTES
    group: Feeds and cleanup
    default: ""
    description: >-
      How often RSS feeds are checked, in minutes.
  - name: TRASH_CLEANUP_RETENTION_DAYS
    group: Feeds and cleanup
    default: ""
    description: >-
      How many days items stay in the trash before they are deleted.
  - name: CAPTURE_LOCALE
    group: Page capture
    default: ""
    description: >-
      The language the page renderer asks websites for, like en-US.
  - name: CAPTURE_TIMEZONE
    group: Page capture
    default: ""
    description: >-
      The time zone the page renderer shows to websites, like Europe/Berlin.
  - name: IND_ENV
    group: Server
    default: development
    description: >-
      development works over plain http on your network. production needs an
      https PUBLIC_URL and is the default when PUBLIC_URL starts with
      https://.
  - name: CORS_ORIGINS
    group: Server
    default: ""
    description: >-
      Other addresses that reach this server (a LAN name and a tailnet name,
      say), comma separated. PUBLIC_URL is always allowed.
  - name: TRUSTED_PROXIES
    group: Server
    default: 127.0.0.1/32
    description: >-
      Reverse proxies whose client IP headers are trusted, comma separated.
      Add your proxy's address when you put Indelible behind one.
  - name: EGRESS_ALLOW_PRIVATE_TARGETS
    group: Security
    default: "true"
    description: >-
      Lets Indelible fetch addresses on your own network (like a local
      Ollama for Mila). On by default in development mode, off in
      production. Set to false for an instance others can reach.
  - name: WEBHOOKS_ALLOW_PRIVATE_TARGETS
    group: Security
    default: "false"
    description: >-
      Set to true to let webhooks call addresses on your own network.
  - name: RUST_LOG
    group: Logs
    default: info
    description: >-
      How much to log, like warn, info or debug.
---

# Indelible

Indelible is a self-hosted, open source knowledge library and read-it-later archiver: a private Pocket or Readwise that keeps everything you save, in full, on your own server. This is Indelible in a single container, with PostgreSQL (pgvector), Silo file storage, the page renderer and the background worker inside, one port and one data folder. Every secret key and password is made for you on first start.

## Features

- Full-content archiving of articles, PDFs and EPUBs, with a headless Chromium renderer for pages that resist simple scraping
- A focused reading view with highlights, notes and reading progress that syncs across web and mobile
- Full-text and semantic search across your whole library
- Mila, an optional AI assistant that summarizes and answers questions about your saved content, using your own AI provider key
- Save from the browser extension, RSS feeds, file uploads or a personal email address
- Syncs to Obsidian and Notion

## How to use

1. Open Indelible from your dashboard.
2. Create your account on the first visit. Sign-ups close by themselves as soon as that first account exists.
3. Save something: paste a link, upload a file, install the browser extension or add an RSS feed.
4. Open a saved item to highlight text, take notes and track your reading.
5. Turn on Mila in Settings if you want AI summaries; you add your own OpenAI-compatible API key there.

## Before you install

`PUBLIC_URL` starts as `http://localhost:6152`. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6152`; signing in only works at this exact address. Over `http://` Indelible runs in development mode so it works on your network; with an `https://` PUBLIC_URL behind your own reverse proxy it switches to production mode. The first start takes about three minutes. All secret keys are made for you and kept in the data folder. More sign-ups, OIDC sign-in, Notion sync and save-by-email are in the Variables tab; add them in the app settings.
