---
site: https://norish.dev
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Dashboard, Recipe, Meal planner, Groceries]
variables:
  - name: TRUSTED_ORIGINS
    group: Server
    default: ""
    description: >-
      Other addresses Norish may be opened at, separated by commas, like
      http://localhost:6134,https://recipes.example.com. Sign-in only works
      from PUBLIC_URL and these.
  - name: DEFAULT_LOCALE
    group: Server
    default: en
    description: >-
      The language for new users, like en, de or nl.
  - name: ENABLED_LOCALES
    group: Server
    default: ""
    description: >-
      The languages people may pick, separated by commas, like en,de,nl.
      Blank allows all of them.
  - name: MAX_IMAGE_FILE_SIZE
    group: Server
    default: "10485760"
    description: >-
      The biggest recipe photo, in bytes. The default is 10 MB.
  - name: MAX_AVATAR_FILE_SIZE
    group: Server
    default: "5242880"
    description: >-
      The biggest profile picture, in bytes. The default is 5 MB.
  - name: MAX_VIDEO_FILE_SIZE
    group: Server
    default: "104857600"
    description: >-
      The biggest video upload, in bytes. The default is 100 MB.
  - name: OIDC_NAME
    group: Sign in with OIDC
    default: Nora ID
    description: >-
      The name on the sign-in button, like Authentik or Pocket ID. Read on
      the first start only; later, change sign-in in Settings, Admin.
  - name: OIDC_ISSUER
    group: Sign in with OIDC
    default: ""
    description: >-
      Your sign-in server's issuer address, like
      https://auth.example.com/application/o/norish/.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client id from your sign-in server.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your sign-in server. When OIDC, GitHub or Google
      is set on the first start, password sign-in starts off.
  - name: OIDC_WELLKNOWN
    group: Sign in with OIDC
    default: ""
    description: >-
      The discovery address, if it isn't the issuer plus
      /.well-known/openid-configuration.
  - name: OIDC_CLAIM_MAPPING_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to give admin rights and households from the groups your
      sign-in server sends.
  - name: OIDC_SCOPES
    group: Sign in with OIDC
    default: ""
    description: >-
      Extra scopes to ask for, separated by commas, like groups.
  - name: OIDC_GROUPS_CLAIM
    group: Sign in with OIDC
    default: groups
    description: >-
      The claim that holds the user's groups.
  - name: OIDC_ADMIN_GROUP
    group: Sign in with OIDC
    default: norish_admin
    description: >-
      Members of this group become server admins.
  - name: OIDC_HOUSEHOLD_GROUP_PREFIX
    group: Sign in with OIDC
    default: norish_household_
    description: >-
      Groups starting with this put people in the household of that name.
  - name: GITHUB_CLIENT_ID
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The client id of a GitHub OAuth app. Read on the first start only.
  - name: GITHUB_CLIENT_SECRET
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The client secret of that GitHub OAuth app.
  - name: GOOGLE_CLIENT_ID
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The client id of a Google OAuth client. Read on the first start only.
  - name: GOOGLE_CLIENT_SECRET
    group: Sign in with GitHub or Google
    default: ""
    description: >-
      The client secret of that Google OAuth client.
  - name: AI_ENABLED
    group: AI
    default: "false"
    description: >-
      Set to true to import recipes with AI (photos, messy pages, text). Read
      on the first start only; later, change AI in Settings, Admin.
  - name: AI_PROVIDER
    group: AI
    default: openai
    description: >-
      openai, ollama, lm-studio or generic-openai.
  - name: AI_ENDPOINT
    group: AI
    default: ""
    description: >-
      The address of your AI server, like http://192.168.1.20:11434 for
      Ollama. Not needed for OpenAI.
  - name: AI_MODEL
    group: AI
    default: gpt-6-luna
    description: >-
      The model to use.
  - name: AI_API_KEY
    group: AI
    default: ""
    description: >-
      Your API key, if the provider needs one.
  - name: AI_TEMPERATURE
    group: AI
    default: "1.0"
    description: >-
      How creative the answers are, 0 to 2.
  - name: AI_MAX_TOKENS
    group: AI
    default: "10000"
    description: >-
      The longest answer, in tokens.
  - name: AI_TIMEOUT_MS
    group: AI
    default: "300000"
    description: >-
      How long to wait for the AI, in milliseconds.
  - name: INGREDIENT_REVIEW_CONCURRENCY
    group: AI
    default: "10"
    description: >-
      How many ingredients Ask AI checks at once, 1 to 50. Lower it for a
      model on your own computer.
  - name: TRANSCRIPTION_PROVIDER
    group: Video and transcription
    default: disabled
    description: >-
      Turns speech into text for video imports: disabled, openai, ollama,
      lm-studio or generic-openai. Read on the first start only.
  - name: TRANSCRIPTION_ENDPOINT
    group: Video and transcription
    default: ""
    description: >-
      The address of your transcription server. Needed for the local ones.
  - name: TRANSCRIPTION_API_KEY
    group: Video and transcription
    default: ""
    description: >-
      API key for transcription. Blank uses AI_API_KEY.
  - name: TRANSCRIPTION_MODEL
    group: Video and transcription
    default: whisper-1
    description: >-
      The transcription model.
  - name: VIDEO_PARSING_ENABLED
    group: Video and transcription
    default: "false"
    description: >-
      Set to true to import recipes from video links. Needs AI. Read on the
      first start only.
  - name: VIDEO_MAX_LENGTH_SECONDS
    group: Video and transcription
    default: "120"
    description: >-
      The longest video Norish will import, in seconds.
  - name: YT_DLP_PROXY
    group: Video and transcription
    default: ""
    description: >-
      A proxy for video downloads, like http://user:pass@proxy:8080.
  - name: OBSCURA_NAVIGATION_TIMEOUT_MS
    group: Imports
    default: "45000"
    description: >-
      How long a link import waits for the page to load, in milliseconds.
  - name: PARSER_API_TIMEOUT_MS
    group: Imports
    default: "15000"
    description: >-
      How long the recipe reader may take, in milliseconds.
  - name: INGREDIENT_CATALOGUE_URL
    group: Imports
    default: https://raw.githubusercontent.com/openfoodfacts/openfoodfacts-server/main/taxonomies/food/ingredients.txt
    description: >-
      Where the ingredient catalogue comes from each night (Open Food
      Facts). Point it at a copy if your server has no internet.
  - name: SCHEDULER_CLEANUP_MONTHS
    group: Imports
    default: "3"
    description: >-
      How many months old meal plans are kept. Read on the first start only.
  - name: NEXT_PUBLIC_LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much goes in the app log: trace, debug, info, warn, error or fatal.
---

# Norish

Norish is a recipe app made for households. Save recipes from any site, plan your meals on a calendar and share one grocery list that updates live for everyone. This is Norish in a single container, with one port and one data folder. PostgreSQL, Redis and the Obscura page renderer are inside, and the master key and passwords are made for you on first start.

## Features

- Import recipes from a link, a photo, a video or plain text
- Households that share recipes, plans and groceries in real time
- Meal planner calendar and smart grocery lists with aisles
- Cookbooks, a pantry and a cooking mode
- Unit conversion, serving scaling and nutrition
- Works offline and installs like an app
- Optional AI import and transcription with OpenAI, Ollama or LM Studio
- Sign in with a password, OIDC (Authentik, Pocket ID...), GitHub or Google
- Fifteen languages

## How to use

1. Open Norish from your dashboard.
2. Make an account. The first account is the server owner and admin.
3. Add a recipe with Import and paste a link.
4. Invite your household and plan the week.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6134`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6134`. Sign-in only works from that address (add others in `TRUSTED_ORIGINS`). Until it is set, Norish shows a short note instead of the app. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. Sign-in providers, AI and video settings are read on the first start only; after that, change them in Norish under Settings, Admin. The first start takes about three minutes. Keep `state/secrets.env` in the data folder with your backups: it holds the master key that saved API keys are encrypted with.
