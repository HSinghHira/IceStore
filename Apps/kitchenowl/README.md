---
site: https://kitchenowl.org
source: https://github.com/TomBursch/kitchenowl
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: JWT_SECRET_KEY
    group: Security
    default: ""
    description: >-
      The secret that signs sign-ins. Made on first start and kept in
      the data folder when left out.
  - name: FRONT_URL
    group: Server
    default: ""
    description: >-
      The address people open KitchenOwl at, like
      https://kitchen.example.com, for links and OIDC.
  - name: DISABLE_USERNAME_PASSWORD_LOGIN
    group: Sign-in
    default: ""
    description: >-
      Set to true to only allow OIDC sign-in.
  - name: OPEN_REGISTRATION
    group: Sign-in
    default: "false"
    description: >-
      Set to true to let anyone make an account.
  - name: OIDC_ISSUER
    group: Sign-in
    default: ""
    description: >-
      Your OpenID Connect provider (with OIDC_CLIENT_ID and
      OIDC_CLIENT_SECRET).
  - name: OIDC_CLIENT_ID
    group: Sign-in
    default: ""
    description: >-
      The OIDC client ID.
  - name: OIDC_CLIENT_SECRET
    group: Sign-in
    default: ""
    description: >-
      The OIDC client secret.
  - name: SMTP_HOST
    group: Email
    default: ""
    description: >-
      Your mail server, for password resets (with SMTP_PORT, SMTP_USER,
      SMTP_PASS and SMTP_FROM).
---

# KitchenOwl

KitchenOwl keeps your household's grocery list in sync on every phone, with recipes that add their ingredients to the list, a meal planner and an expense tracker to share costs.

## Features

- Shared shopping list that updates live, sorted by how you shop
- Recipes with import from websites, tags and servings
- Weekly meal planner that fills the shopping list
- Expense tracking and balances for shared costs
- Apps for Android, iOS and the web, with several households

## How to use

1. Open KitchenOwl right away and make the first (admin) account.
2. Make a household and invite the others.
3. In the phone app, use http://[ZIMAOS-IP-ADDRESS]:6862 as the server.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6862 and make your account; the first account is the admin, and until then anyone on your network can make it. In the KitchenOwl phone app, use that address as the server. Sign-ups by others are off unless you set OPEN_REGISTRATION=true; invite people from the household settings instead.
