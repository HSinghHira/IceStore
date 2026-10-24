---
site: https://cobalt.tools/
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Paste a link and save]
variables:
  - name: DISABLED_SERVICES
    group: Server
    default: ""
    description: >-
      Sites to turn off, separated by commas, like bilibili,youtube. Leave it
      out to allow every site cobalt supports.
  - name: FORCE_LOCAL_PROCESSING
    group: Server
    default: "never"
    description: >-
      Set to always so merging and converting happen in the browser instead
      of on your server, or session for session clients only.
  - name: DURATION_LIMIT
    group: Server
    default: "10800"
    description: >-
      The longest video or audio people can save, in seconds. 10800 is three
      hours.
  - name: TUNNEL_LIFESPAN
    group: Server
    default: "90"
    description: >-
      How many seconds a download link keeps working.
  - name: PROCESSING_PRIORITY
    group: Server
    default: ""
    description: >-
      A nice value for ffmpeg, like 10. Higher numbers give it less of your
      CPU. Leave it out to run at normal priority.
  - name: HTTP_PROXY
    group: Proxy
    default: ""
    description: >-
      A proxy for all outgoing requests, like http://user:password@10.0.0.1:1337/.
  - name: HTTPS_PROXY
    group: Proxy
    default: ""
    description: >-
      A proxy for https requests only. Leave it out to use HTTP_PROXY for
      both.
  - name: NO_PROXY
    group: Proxy
    default: ""
    description: >-
      Host names that skip the proxy, separated by commas.
  - name: RATELIMIT_WINDOW
    group: Rate limits
    default: "60"
    description: >-
      The time window, in seconds, for counting save requests.
  - name: RATELIMIT_MAX
    group: Rate limits
    default: "20"
    description: >-
      How many save requests one person can make in that window.
  - name: SESSION_RATELIMIT_WINDOW
    group: Rate limits
    default: "60"
    description: >-
      The time window, in seconds, for counting new sessions.
  - name: SESSION_RATELIMIT_MAX
    group: Rate limits
    default: "10"
    description: >-
      How many sessions one person can start in that window.
  - name: TUNNEL_RATELIMIT_WINDOW
    group: Rate limits
    default: "60"
    description: >-
      The time window, in seconds, for counting downloads.
  - name: TUNNEL_RATELIMIT_MAX
    group: Rate limits
    default: "40"
    description: >-
      How many downloads one person can start in that window.
  - name: TURNSTILE_SITEKEY
    group: Protect a public instance
    default: ""
    description: >-
      The site key from Cloudflare Turnstile. Set it together with
      TURNSTILE_SECRET to make visitors pass a bot check. The JWT secret it
      needs is already made for you.
  - name: TURNSTILE_SECRET
    group: Protect a public instance
    default: ""
    description: >-
      The secret key from Cloudflare Turnstile.
  - name: JWT_EXPIRY
    group: Protect a public instance
    default: "120"
    description: >-
      How many seconds a passed bot check stays valid.
  - name: API_AUTH_REQUIRED
    group: Protect a public instance
    default: "0"
    description: >-
      Set to 1 so every request needs an API key or a passed bot check.
  - name: API_KEY_URL
    group: Protect a public instance
    default: ""
    description: >-
      Where your API keys file is. Leave it out and a keys.json in the config
      folder of the data folder is used when it exists.
  - name: CORS_WILDCARD
    group: Protect a public instance
    default: "1"
    description: >-
      Set to 0 so other websites can't use your API, only CORS_URL.
  - name: CORS_URL
    group: Protect a public instance
    default: ""
    description: >-
      The one website allowed to use your API when CORS_WILDCARD is 0.
  - name: YOUTUBE_SESSION_SERVER
    group: YouTube
    default: ""
    description: >-
      The address of a yt-session-generator you run, like
      http://192.168.1.20:8080/. Helps when YouTube blocks downloads.
  - name: YOUTUBE_SESSION_INNERTUBE_CLIENT
    group: YouTube
    default: ""
    description: >-
      The YouTube client to use with that session, like WEB_EMBEDDED.
  - name: CUSTOM_INNERTUBE_CLIENT
    group: YouTube
    default: ""
    description: >-
      Use another YouTube client instead of the default one, like IOS.
  - name: YOUTUBE_PLAYER_ID
    group: YouTube
    default: ""
    description: >-
      YouTube player IDs to use, separated by commas. Leave it out to use the
      newest one.
  - name: YOUTUBE_ALLOW_BETTER_AUDIO
    group: YouTube
    default: "0"
    description: >-
      Set to 1 to allow the better audio option. It uses up the rate limit
      faster.
  - name: ENABLE_DEPRECATED_YOUTUBE_HLS
    group: YouTube
    default: "never"
    description: >-
      Set to always or key to let requests ask for YouTube HLS streams.
---

# cobalt

cobalt saves what you love from the web. Paste a link from YouTube, TikTok, Instagram, Reddit, SoundCloud, Bluesky and many more sites, and get the file. No ads, no trackers, no paywalls. This is the official cobalt API and the official cobalt web app in a single container, with one port and one data folder.

## Features

- Saves video, audio and pictures from dozens of sites
- Pick video, audio only or muted video, plus quality and format in the settings
- Nothing is stored: files stream straight from the site to you
- Remux and convert files on your own device in the browser
- The web app always matches the API version; both come from the same upstream release
- Optional cookies for content that needs a sign-in, API keys and Cloudflare Turnstile bot protection for public instances

## How to use

1. Open cobalt from your dashboard.
2. Paste a link into the box.
3. Pick auto, audio or mute, then save the file.

## Before you install

Change `localhost` in `PUBLIC_URL` to your server's IP address (keep port 6144), because download links are made from it. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. For sites that need a sign-in, put a `cookies.json` file (see [cobalt's cookie format](https://github.com/imputnet/cobalt/blob/main/docs/examples/cookies.example.json)) in the `config` folder inside the app's data folder and restart the app; a `keys.json` there turns on API keys. The first start takes about a minute.
