---
site: https://mealie.io/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API docs, path: /docs, icon: code }
screenshots: [Recipe page, Importing a recipe, Meal planner, Shopping list]
variables:
  - name: TOKEN_TIME
    group: Server
    default: "48"
    description: >-
      How many hours people stay signed in.
  - name: DAILY_SCHEDULE_TIME
    group: Server
    default: "23:45"
    description: >-
      When the daily jobs run, like meal plan reminders, as HH:MM.
  - name: SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your email server, like smtp.gmail.com, for invites and password
      resets.
  - name: SMTP_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your email server port, usually 587 or 465.
  - name: SMTP_AUTH_STRATEGY
    group: Email (SMTP)
    default: TLS
    description: >-
      TLS for port 587, SSL for port 465, or NONE.
  - name: SMTP_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your email server.
  - name: SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your email server.
  - name: SMTP_FROM_EMAIL
    group: Email (SMTP)
    default: ""
    description: >-
      The address emails are sent from.
  - name: SMTP_FROM_NAME
    group: Email (SMTP)
    default: Mealie
    description: >-
      The name emails are sent from.
  - name: OIDC_AUTH_ENABLED
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to sign in with Pocket ID, Authentik or another OIDC
      provider.
  - name: OIDC_CONFIGURATION_URL
    group: Sign in with OIDC
    default: ""
    description: >-
      The provider's discovery address, ending in
      /.well-known/openid-configuration.
  - name: OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your provider. The redirect address to enter there
      is your Mealie address plus /login.
  - name: OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your provider.
  - name: OIDC_PROVIDER_NAME
    group: Sign in with OIDC
    default: OAuth
    description: >-
      The name on the sign-in button.
  - name: OIDC_AUTO_REDIRECT
    group: Sign in with OIDC
    default: "false"
    description: >-
      Set to true to skip Mealie's sign-in page and go straight to the
      provider.
  - name: OIDC_ADMIN_GROUP
    group: Sign in with OIDC
    default: ""
    description: >-
      Members of this provider group become Mealie admins.
  - name: OPENAI_API_KEY
    group: AI
    default: ""
    description: >-
      An OpenAI (or compatible) API key to import recipes from photos and
      parse ingredients.
  - name: OPENAI_BASE_URL
    group: AI
    default: ""
    description: >-
      The API address of a compatible server, like your Ollama's /v1.
  - name: OPENAI_MODEL
    group: AI
    default: gpt-4o
    description: >-
      The model to use.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much Mealie writes to the log: error, warning, info or debug.
---

# Mealie

Mealie keeps your family's recipes in one place. Paste a link from any recipe site and Mealie saves the ingredients, steps and picture, then helps you plan the week's meals and make the shopping list. The database is built in, so it is one container with nothing else to set up.

## Features

- Import recipes from a link, by hand, or from a photo with AI
- Meal planner for the week, with rules for each day
- Shopping lists made from your meal plan
- Scale recipes, cooking mode and nutrition facts
- Households and groups for family and friends
- Home Assistant card, REST API and webhooks

## How to use

1. Open Mealie from your dashboard.
2. Sign in as changeme@example.com with the password from the app's logs (the box marked CREDENTIALS).
3. Follow the setup steps, then change your email and password in your profile.
4. Click Create, then Import, and paste a link to a recipe.
5. Open the Meal Planner to plan your week.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6767`. Mealie's first admin is changeme@example.com; instead of the well-known default password, this app gives it a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/mealie/data/.admin_password`. Change the email and password in your profile. Change `localhost` in `BASE_URL` to your ZimaOS IP for working links in emails. Email, sign-in with OIDC and AI are in the Variables tab and are added in the app settings. It is ready in about a minute.
