---
site: https://trypost.it
source: https://github.com/trypostit/trypost
services:
  - { name: Web App, path: /, icon: globe }
  - { name: MCP Server, path: /mcp, icon: plug }
screenshots: [Calendar, Queues, Ideas board, Insights]
variables:
  - name: ADMIN_NAME
    group: Sign-up and accounts
    default: "Admin"
    description: >-
      The name of the first account, made on the first start.
  - name: GOOGLE_AUTH_ENABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to show "Sign in with Google". Uses GOOGLE_CLIENT_ID and
      GOOGLE_CLIENT_SECRET.
  - name: GITHUB_AUTH_ENABLED
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to show "Sign in with GitHub". Uses GITHUB_CLIENT_ID and
      GITHUB_CLIENT_SECRET.
  - name: GITHUB_CLIENT_ID
    group: Sign-up and accounts
    default: ""
    description: >-
      Client ID of your GitHub OAuth app. Its callback is
      PUBLIC_URL/auth/github/callback.
  - name: GITHUB_CLIENT_SECRET
    group: Sign-up and accounts
    default: ""
    description: >-
      Client secret of your GitHub OAuth app.
  - name: MAIL_MAILER
    group: Email (SMTP)
    default: "log"
    description: >-
      Set to smtp to send emails (invites, password resets, notes). With log,
      emails only go to the app's log file.
  - name: MAIL_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: MAIL_PORT
    group: Email (SMTP)
    default: "2525"
    description: >-
      Your email server port, usually 587 or 465.
  - name: MAIL_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: MAIL_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: MAIL_SCHEME
    group: Email (SMTP)
    default: ""
    description: >-
      smtps for port 465. Leave it out for port 587 (STARTTLS is used when
      the server offers it).
  - name: MAIL_FROM_ADDRESS
    group: Email (SMTP)
    default: "hello@example.com"
    description: >-
      The address emails are sent from.
  - name: MAIL_FROM_NAME
    group: Email (SMTP)
    default: "TryPost"
    description: >-
      The sender name on emails.
  - name: LINKEDIN_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      LinkedIn app client ID. Every network's callback is
      PUBLIC_URL/accounts/<network>/callback, like
      http://192.168.1.20:6190/accounts/linkedin/callback. Bluesky, Mastodon
      and Telegram need no app keys.
  - name: LINKEDIN_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      LinkedIn app client secret.
  - name: X_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      X (Twitter) app client ID. Callback: PUBLIC_URL/accounts/x/callback.
  - name: X_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      X (Twitter) app client secret.
  - name: FACEBOOK_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      Meta app ID for Facebook pages.
  - name: FACEBOOK_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      Meta app secret for Facebook pages.
  - name: INSTAGRAM_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      Instagram app ID.
  - name: INSTAGRAM_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      Instagram app secret.
  - name: THREADS_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      Threads app ID.
  - name: THREADS_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      Threads app secret.
  - name: TIKTOK_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      TikTok app client key.
  - name: TIKTOK_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      TikTok app client secret.
  - name: GOOGLE_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      Google OAuth client ID, for YouTube and Sign in with Google. Callbacks:
      PUBLIC_URL/accounts/youtube/callback and PUBLIC_URL/auth/google/callback.
  - name: GOOGLE_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      Google OAuth client secret.
  - name: GOOGLE_BUSINESS_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      Google OAuth client ID for Google Business Profile.
  - name: GOOGLE_BUSINESS_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      Google OAuth client secret for Google Business Profile.
  - name: PINTEREST_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      Pinterest app ID.
  - name: PINTEREST_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      Pinterest app secret.
  - name: DISCORD_CLIENT_ID
    group: Social networks
    default: ""
    description: >-
      Discord application ID.
  - name: DISCORD_CLIENT_SECRET
    group: Social networks
    default: ""
    description: >-
      Discord application secret.
  - name: DISCORD_BOT_TOKEN
    group: Social networks
    default: ""
    description: >-
      The token of your Discord bot, which posts to your channels.
  - name: TELEGRAM_BOT_TOKEN
    group: Social networks
    default: ""
    description: >-
      The token of your Telegram bot, from BotFather.
  - name: TELEGRAM_BOT_USERNAME
    group: Social networks
    default: ""
    description: >-
      Your Telegram bot's user name, without the @.
  - name: AI_TEXT_PROVIDER
    group: AI
    default: "openai"
    description: >-
      Which AI writes and rewrites posts: openai, anthropic, gemini or
      openrouter. Add that provider's API key too. Leave every key out to
      turn the AI assistant off.
  - name: OPENAI_API_KEY
    group: AI
    default: ""
    description: >-
      Your OpenAI API key.
  - name: ANTHROPIC_API_KEY
    group: AI
    default: ""
    description: >-
      Your Anthropic API key.
  - name: GEMINI_API_KEY
    group: AI
    default: ""
    description: >-
      Your Google Gemini API key.
  - name: OPENROUTER_API_KEY
    group: AI
    default: ""
    description: >-
      Your OpenRouter API key.
  - name: ELEVENLABS_API_KEY
    group: AI
    default: ""
    description: >-
      Your ElevenLabs API key, for AI voice-overs.
  - name: UNSPLASH_ACCESS_KEY
    group: Media sources
    default: ""
    description: >-
      Your Unsplash access key, to pick photos from Unsplash.
  - name: UNSPLASH_SECRET_KEY
    group: Media sources
    default: ""
    description: >-
      Your Unsplash secret key.
  - name: CANVA_CLIENT_ID
    group: Media sources
    default: ""
    description: >-
      Canva Connect app client ID, to bring in Canva designs.
  - name: CANVA_CLIENT_SECRET
    group: Media sources
    default: ""
    description: >-
      Canva Connect app client secret.
  - name: APP_LOCALE
    group: Server
    default: "en"
    description: >-
      The default language, like en, pt, es, fr or de. Each person can
      change their own in their profile.
  - name: POST_HISTORY_RETENTION_DAYS
    group: Server
    default: "730"
    description: >-
      How many days to keep the edit history of posts.
  - name: LOG_LEVEL
    group: Logs
    default: "debug"
    description: >-
      How much TryPost writes to its log: debug, info, warning or error.
---

# TryPost

TryPost plans, schedules and publishes posts to every social network. Write them in a composer with a live preview, or let AI agents do it through MCP and the REST API. This is TryPost in a single container, with PostgreSQL and Redis inside, one port and one data folder. Secret keys and the first account are made for you on first start.

## Features

- Instagram, TikTok, LinkedIn, X, YouTube, Facebook, Threads, Bluesky, Pinterest, Mastodon, Google Business, Telegram and Discord
- Composer that adapts each post per network, with a live preview
- Calendar and per-channel queues with posting times
- Approvals, workspaces for each brand or client, and team members
- MCP server with 80+ tools and a REST API with webhooks
- Ideas board, labels, signatures and insights per channel
- Every feature of TryPost Cloud, no paid tiers
- PostgreSQL and Redis inside

## How to use

1. Open TryPost from your dashboard.
2. Sign in with `ADMIN_EMAIL` and the password from the app log.
3. Connect a channel, then write your first post and schedule it.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6190`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6190`, or use your https address. Images, videos and every social network's sign-in are linked from it. Until it is set, TryPost only opens on the server itself and shows a note everywhere else.

Set `ADMIN_EMAIL` to your own email. Leave `ADMIN_PASSWORD` blank to get a random one, shown in the app log in the box marked CREDENTIALS. Self-hosted TryPost has no open sign-up: invite your team from Settings, Members.

To post to a network, make a developer app with that network and add its keys from the Variables tab (Bluesky, Mastodon and Telegram need none). The callback address for each is `http://[ZIMAOS-IP-ADDRESS]:6190/accounts/<network>/callback`. Some networks only accept https callbacks and public image addresses, so Instagram, TikTok and a few others need TryPost on a public https address. Email (SMTP), AI and the other settings are in the Variables tab too; add them in the app settings. The first start takes about 3 minutes.
