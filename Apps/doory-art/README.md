---
site: https://github.com/shaongitbd/doory
services:
  - { name: Design editor, path: /, icon: globe }
  - { name: Admin, path: /admin/, icon: server }
screenshots: [Editor, Templates, Animation, Layers, Share and export]
variables:
  - name: DJANGO_ALLOWED_HOSTS
    group: Server
    default: "*"
    description: >-
      The host names Doory answers to, separated by commas, for example
      design.example.com,192.168.1.10. Leave it out to answer on any address.
  - name: SECURE_SSL_REDIRECT
    group: Server
    default: "false"
    description: >-
      Set to true to send every visitor to https. Leave it out and it turns on
      by itself when PUBLIC_URL starts with https://.
  - name: SECURE_COOKIES
    group: Server
    default: "false"
    description: >-
      Set to true so sign-in cookies only travel over https. Leave it out and
      it turns on by itself when PUBLIC_URL starts with https://.
  - name: NUM_PROXIES
    group: Server
    default: "1"
    description: >-
      How many reverse proxies sit in front of the API. Add one for each proxy
      in front of the app's own one (for example 2 behind Nginx Proxy Manager).
  - name: WEB_CONCURRENCY
    group: Server
    default: "3"
    description: >-
      How many API worker processes run. Lower it to save memory on a small box.
  - name: LOG_LEVEL
    group: Server
    default: INFO
    description: >-
      How much the server writes to the log: DEBUG, INFO, WARNING or ERROR.
  - name: DJANGO_SECRET_KEY_FALLBACKS
    group: Server
    default: ""
    description: >-
      Old secret keys that are still accepted, separated by commas. Only needed
      if you replace the secret key in /data/state/secrets.env.
  - name: USER_STORAGE_QUOTA_BYTES
    group: Limits
    default: "2147483648"
    description: >-
      How much each person may upload, in bytes. The default is 2 GB.
  - name: MAX_DESIGNS_PER_USER
    group: Limits
    default: "5000"
    description: >-
      The most designs one person can have.
  - name: MAX_API_TOKENS_PER_USER
    group: Limits
    default: "20"
    description: >-
      The most personal access tokens one person can make.
  - name: DOORY_SYNC_ELEMENTS
    group: First-run content
    default: "true"
    description: >-
      Installs about 27,500 icons, emoji and illustrations (about 130 MB). Set
      to false to skip it. After the first time it takes about a second.
  - name: DOORY_SYNC_ELEMENTS_ARGS
    group: First-run content
    default: ""
    description: >-
      Extra options for the element download, for example
      --pack lucide phosphor-regular to install only some packs.
  - name: DOORY_ELEMENTS_BRAND_LOGOS
    group: First-run content
    default: "false"
    description: >-
      Set to true to add brand logos (Facebook, YouTube and others) on the next
      start. Logos belong to their owners; follow their brand rules.
  - name: DOORY_SYNC_FONTS
    group: First-run content
    default: "true"
    description: >-
      Downloads the open-licensed font catalogue once, on the first start. Set
      to false to skip it.
  - name: DOORY_SYNC_FONTS_ARGS
    group: First-run content
    default: ""
    description: >-
      Which font families to download. Blank means the 100 most popular. For
      example --popular 253 or --all.
  - name: DOORY_SEED_TEMPLATES
    group: First-run content
    default: "true"
    description: >-
      Adds the ten starter templates. Templates you already have are never
      changed. Set to false to skip it.
  - name: DOORY_SYNC_MODELS
    group: First-run content
    default: "true"
    description: >-
      Installs the small background-removal model (4.6 MB). Set to false to
      skip it.
  - name: DOORY_SYNC_MODELS_ARGS
    group: First-run content
    default: ""
    description: >-
      Extra options for the model download, for example --model u2net for the
      bigger, better model (176 MB).
  - name: DOORY_SYNC_AUDIO
    group: First-run content
    default: "true"
    description: >-
      Installs the music loops and sound effects that come with Doory (about
      7 MB). Set to false to skip it.
  - name: DOORY_SYNC_AUDIO_ARGS
    group: First-run content
    default: ""
    description: >-
      Extra options for the audio install, for example --pack some-pack.
  - name: EMAIL_URL
    group: Email (SMTP)
    default: consolemail://
    description: >-
      Your mail server, for example
      smtp+tls://user:password@smtp.example.com:587. Leave it out and emails
      (password resets) are only written to the app log.
  - name: DEFAULT_FROM_EMAIL
    group: Email (SMTP)
    default: Doory <no-reply@localhost>
    description: >-
      The sender of Doory's emails, for example "Doory <design@example.com>".
  - name: GOOGLE_CLIENT_ID
    group: Sign in with Google
    default: ""
    description: >-
      Your Google OAuth web client ID. Set it to show the Sign in with Google
      button.
  - name: OIDC_ISSUER
    group: Sign in with SSO (OIDC)
    default: ""
    description: >-
      The issuer URL of your sign-in provider, for example
      https://auth.example.com/application/o/doory/ for authentik.
  - name: OIDC_CLIENT_ID
    group: Sign in with SSO (OIDC)
    default: ""
    description: >-
      The client ID from your sign-in provider.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with SSO (OIDC)
    default: ""
    description: >-
      The client secret from your sign-in provider.
  - name: OIDC_BUTTON_LABEL
    group: Sign in with SSO (OIDC)
    default: Sign in with SSO
    description: >-
      The text on the sign-in button.
  - name: OIDC_SCOPES
    group: Sign in with SSO (OIDC)
    default: openid email profile
    description: >-
      The scopes Doory asks for.
  - name: OIDC_TRUST_EMAIL
    group: Sign in with SSO (OIDC)
    default: "false"
    description: >-
      Set to true so a first SSO sign-in joins an existing account with the
      same email. Only do this if your provider checks emails.
  - name: UNSPLASH_ACCESS_KEY
    group: Stock photos, videos and sounds
    default: ""
    description: >-
      Your Unsplash access key. Set it to search Unsplash photos in the editor.
  - name: PEXELS_API_KEY
    group: Stock photos, videos and sounds
    default: ""
    description: >-
      Your Pexels API key, for Pexels photos (and videos, unless
      PEXELS_VIDEO_API_KEY is set).
  - name: PIXABAY_API_KEY
    group: Stock photos, videos and sounds
    default: ""
    description: >-
      Your Pixabay API key, for Pixabay images (and videos, unless
      PIXABAY_VIDEO_API_KEY is set).
  - name: PEXELS_VIDEO_API_KEY
    group: Stock photos, videos and sounds
    default: ""
    description: >-
      A separate Pexels key for video search, so it does not use up the photo
      quota.
  - name: PIXABAY_VIDEO_API_KEY
    group: Stock photos, videos and sounds
    default: ""
    description: >-
      A separate Pixabay key for video search.
  - name: FREESOUND_API_KEY
    group: Stock photos, videos and sounds
    default: ""
    description: >-
      Your Freesound API key. Set it to show the Freesound tab in the Audio
      tool. Freesound's terms cover non-commercial use.
  - name: FREESOUND_LICENSES
    group: Stock photos, videos and sounds
    default: cc0
    description: >-
      Which Freesound licences are allowed. Use cc0,by to also allow CC BY
      sounds (the editor then shows the credits).
  - name: STOCK_PROVIDERS
    group: Stock photos, videos and sounds
    default: unsplash,pexels,pixabay
    description: >-
      Which photo providers are on, in tab order. Only ones with a key show up.
  - name: SERVER_PDF_ENABLED
    group: Export
    default: "true"
    description: >-
      Server-side PDF export with the Chromium inside. Set to false to turn it
      off.
  - name: SERVER_IMAGE_EXPORT_ENABLED
    group: Export
    default: "false"
    description: >-
      Set to true to make PNG, JPG, WebP and AVIF files on the server. It runs
      the editor's engine in the export browser.
  - name: SERVER_VIDEO_EXPORT_ENABLED
    group: Export
    default: "false"
    description: >-
      Set to true to make MP4, WebM and GIF files on the server. Needs
      SERVER_IMAGE_EXPORT_ENABLED=true too.
  - name: EXPORT_FILENAME_STYLE
    group: Export
    default: simple
    description: >-
      How downloaded files are named: simple (summer-sale-02.png) or structured
      (title, platform, size and page in the name).
  - name: IMAGE_OPTIMIZERS
    group: Export
    default: builtin
    description: >-
      Which image optimizers people can pick, separated by commas: builtin,
      tinypng, kraken or custom. Blank turns them off.
  - name: TINYPNG_API_KEY
    group: Export
    default: ""
    description: >-
      Your TinyPNG key, to offer the TinyPNG optimizer. Images are sent to
      TinyPNG.
  - name: VIDEO_ENABLED
    group: Video
    default: "true"
    description: >-
      Video clips (uploads and stock videos), using the ffmpeg inside. Set to
      false to turn them off.
  - name: MAX_VIDEO_UPLOAD_BYTES
    group: Video
    default: "209715200"
    description: >-
      The largest video clip someone can upload, in bytes. The default is
      200 MB, which is also the most the app's web server lets through.
  - name: MCP_ENABLED
    group: AI assistants (MCP)
    default: "false"
    description: >-
      Set to true to start the MCP server at /mcp, so AI assistants like
      Claude or Cursor can work on your designs. People make tokens in
      Settings.
  - name: MCP_CALLS_PER_MINUTE
    group: AI assistants (MCP)
    default: "120"
    description: >-
      How many MCP calls each person can make per minute. 0 means no limit.
  - name: BACKGROUND_REMOVAL_ENABLED
    group: AI background removal
    default: "true"
    description: >-
      Background removal in the editor. Set to false to hide it.
  - name: AI_PROVIDER_1_URL
    group: AI background removal
    default: ""
    description: >-
      The address of your own background-removal server, for better results
      than the in-browser one. AI_PROVIDER_1_STYLE, _AUTH_HEADER and
      _AUTH_VALUE (and AI_PROVIDER_2_ and up) work the same way; see Doory's
      AI providers guide.
  - name: AI_USER_PROVIDERS
    group: AI background removal
    default: "off"
    description: >-
      Who may add their own AI servers: off, staff or everyone.
---

# Doory Art

Doory is a design editor that runs in the browser. Make posters, social posts, stories, slides, invitations, resumes, thumbnails and business cards, then export them as PNG, JPG, SVG, PDF, MP4 or GIF. This is Doory in a single container, with one port and one data folder. PostgreSQL is inside, and the secret key and database passwords are made for you on first start. The optional AI server and Redis are left out.

## Features

- Start from a template or a blank page, with several pages per design
- Text effects, curved text, an open-licensed font catalogue and your own fonts
- About 27,500 icons, emoji and illustrations, shapes, QR codes
- Photo crop, masks, filters and background removal in the browser
- Animations, page transitions, music loops, sound effects and video clips
- Share links, comments, version history and live co-editing
- Brand kits with your colours, fonts and logos
- Server-side PDF export with headless Chromium inside

## How to use

1. Open Doory Art from your dashboard.
2. Sign in with the admin email and password, or create an account.
3. Pick a size or a template and start designing.
4. Use Share to make a link, or download your design.
5. Open `/admin/` as the admin to manage users, templates and settings.

## Before you install

Set `ADMIN_EMAIL` to your own email. Leave `ADMIN_PASSWORD` blank to get a random one; it is shown in the app log on the first start (look for "admin password is") and saved in `/data/state/secrets.env`. Change `localhost` in `PUBLIC_URL` to your box's IP, for example `http://192.168.1.10:6143`, so share links work from other devices. More settings, like email (SMTP), Google or SSO sign-in, stock photo keys and the MCP server, are in the Variables tab; add them in the app settings. The first start takes about ten minutes while it sets up the database and downloads icons, fonts and templates.

Doory is released under the Attribution Assurance License by Siam, creator and maintainer of Doory (https://github.com/shaongitbd/doory). The licence text is in the image at `/usr/share/doc/doory/LICENSE`.
