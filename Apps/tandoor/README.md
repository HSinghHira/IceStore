---
site: https://tandoor.dev/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: Admin, path: /admin/, icon: server }
  - { name: API, path: /api/, icon: code }
screenshots: [Recipe]
variables:
  - name: SECRET_KEY
    group: Server
    default: ""
    description: >-
      The key sessions are signed with. It is made on first start and kept in
      /data/secrets.env. Only set it to use your own.
  - name: ALLOWED_HOSTS
    group: Server
    default: "*"
    description: >-
      The names Tandoor answers to, comma separated, like
      recipes.example.com. * allows any.
  - name: CSRF_TRUSTED_ORIGINS
    group: Server
    default: ""
    description: >-
      Your address when you use a domain or reverse proxy, like
      https://recipes.example.com. Forms need it there.
  - name: ALLAUTH_TRUSTED_PROXY_COUNT
    group: Server
    default: "0"
    description: >-
      How many reverse proxies are in front of Tandoor.
  - name: GUNICORN_WORKERS
    group: Server
    default: "3"
    description: >-
      How many server processes to run. Fewer use less memory.
  - name: GUNICORN_THREADS
    group: Server
    default: "2"
    description: >-
      Threads per server process.
  - name: GUNICORN_TIMEOUT
    group: Server
    default: "30"
    description: >-
      Seconds before a slow request is stopped. Raise it for big imports or
      AI imports.
  - name: ENABLE_PDF_EXPORT
    group: Features
    default: "0"
    description: >-
      Set to 1 to export recipes as PDF.
  - name: ENABLE_METRICS
    group: Features
    default: "0"
    description: >-
      Set to 1 to serve Prometheus metrics at /metrics.
  - name: SORT_TREE_BY_NAME
    group: Features
    default: "0"
    description: >-
      Set to 1 to sort keywords and foods by name instead of by when they
      were made.
  - name: SPACE_AI_ENABLED
    group: AI
    default: "1"
    description: >-
      Set to 0 to turn off AI features (recipe import from photos and text).
  - name: SPACE_AI_CREDITS_MONTHLY
    group: AI
    default: "100"
    description: >-
      AI credits each space gets every month.
  - name: AI_RATELIMIT
    group: AI
    default: "60/hour"
    description: >-
      How often AI features can be used.
  - name: FDC_API_KEY
    group: AI
    default: "DEMO_KEY"
    description: >-
      Your key for the US food database (FoodData Central), for nutrition
      data.
  - name: SOCIAL_DEFAULT_GROUP
    group: Sign-in
    default: "guest"
    description: >-
      The group new people get: guest, user or admin.
  - name: SOCIAL_PROVIDERS
    group: Sign-in
    default: ""
    description: >-
      Other sign-in providers, like
      allauth.socialaccount.providers.openid_connect.
  - name: SOCIALACCOUNT_PROVIDERS
    group: Sign-in
    default: ""
    description: >-
      The settings for those providers, as JSON (see Tandoor's docs).
  - name: REMOTE_USER_AUTH
    group: Sign-in
    default: "0"
    description: >-
      Set to 1 to trust the sign-in from a proxy like Authelia.
  - name: HCAPTCHA_SITEKEY
    group: Sign-in
    default: ""
    description: >-
      hCaptcha site key, to protect the sign-up page.
  - name: HCAPTCHA_SECRET
    group: Sign-in
    default: ""
    description: >-
      hCaptcha secret.
  - name: EMAIL_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com, for invites and password
      resets.
  - name: EMAIL_PORT
    group: Email (SMTP)
    default: "25"
    description: >-
      Your email server port, usually 587 or 465.
  - name: EMAIL_HOST_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: EMAIL_HOST_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: EMAIL_USE_TLS
    group: Email (SMTP)
    default: "0"
    description: >-
      Set to 1 for STARTTLS (port 587).
  - name: EMAIL_USE_SSL
    group: Email (SMTP)
    default: "0"
    description: >-
      Set to 1 for SSL (port 465).
  - name: DEFAULT_FROM_EMAIL
    group: Email (SMTP)
    default: "webmaster@localhost"
    description: >-
      The address emails are sent from.
  - name: FRACTION_PREF_DEFAULT
    group: Defaults for new users
    default: "0"
    description: >-
      Set to 1 to show amounts as fractions.
  - name: COMMENT_PREF_DEFAULT
    group: Defaults for new users
    default: "1"
    description: >-
      Set to 0 to hide comments.
  - name: STICKY_NAV_PREF_DEFAULT
    group: Defaults for new users
    default: "1"
    description: >-
      Set to 0 so the top bar scrolls away.
---

# Tandoor Recipes

Tandoor Recipes keeps all your recipes in one place. Import them from almost any website, plan your meals for the week and get a shopping list made for you. Share it with your household. The PostgreSQL database is built in, so it is one container with nothing else to set up.

## Features

- Import recipes from websites, other apps and files
- Meal planner with a calendar
- Shopping lists made from your meal plan, shared live
- Search by name, ingredient, keyword and food
- Scales recipes and works out nutrition
- Cookbooks, ratings and cooking logs
- Spaces for your household, with invites and permissions

## How to use

1. Open Tandoor Recipes from your dashboard.
2. Make the admin account on the first page.
3. Click Import to add a recipe from a website, or Create to write your own.
4. Plan your week in Meal Plan, then open the Shopping list.
5. Invite your household from your space settings.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6770`. There is no account yet: the first page asks you to make the admin account. The secret key and the database password are made for you on first start and kept in `/DATA/AppData/tandoor/data`. Email, other sign-in providers, AI and the other settings are in the Variables tab and are added in the app settings. The first start takes a few minutes while it sets up the database.
