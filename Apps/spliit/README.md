---
site: https://spliit.app/
services:
  - { name: Web app, path: /, icon: globe }
screenshots: [Spliit]
variables:
  - name: BASE_URL
    group: Server
    default: "http://localhost:6787"
    description: >-
      The address you open Spliit at, like http://192.168.1.20:6787. Used in
      shared links and the web app manifest.
  - name: ENABLE_GROUP_DELETION
    group: Features
    default: "false"
    description: >-
      Set to true to let people delete groups.
  - name: ENABLE_EXPENSE_DOCUMENTS
    group: Features
    default: "false"
    description: >-
      Set to true to attach receipt images (needs the S3 settings below).
  - name: S3_UPLOAD_KEY
    group: Features
    default: ""
    description: >-
      S3 access key, for receipt images.
  - name: S3_UPLOAD_SECRET
    group: Features
    default: ""
    description: >-
      S3 secret key.
  - name: S3_UPLOAD_BUCKET
    group: Features
    default: ""
    description: >-
      S3 bucket name.
  - name: S3_UPLOAD_REGION
    group: Features
    default: ""
    description: >-
      S3 region, like us-east-1.
  - name: S3_UPLOAD_ENDPOINT
    group: Features
    default: ""
    description: >-
      S3 server address, for providers other than AWS.
  - name: ENABLE_RECEIPT_EXTRACT
    group: AI
    default: "false"
    description: >-
      Set to true to fill in expenses from a photo of the receipt (needs
      receipt images and OPENAI_API_KEY).
  - name: ENABLE_CATEGORY_EXTRACT
    group: AI
    default: "false"
    description: >-
      Set to true to suggest a category from the expense's title (needs
      OPENAI_API_KEY).
  - name: OPENAI_API_KEY
    group: AI
    default: ""
    description: >-
      Your OpenAI API key, or a key for OPENAI_BASE_URL.
  - name: OPENAI_BASE_URL
    group: AI
    default: ""
    description: >-
      An OpenAI-compatible server, like a local Ollama. Leave it out for
      OpenAI.
  - name: ANALYTICS_PROVIDER
    group: Analytics
    default: ""
    description: >-
      plausible or umami, to count visits. Leave it out for none.
---

# Spliit

Spliit keeps track of shared costs: trips, rent, dinners and groceries. Add who paid what, and it works out who owes whom and the fewest payments to settle up. There are no accounts: share a group's link and everyone in it can add expenses. The PostgreSQL database is built in, so it is one container with nothing else to set up.

## Features

- Groups with any number of people, shared by a link
- Split evenly, by shares, by percent or by amount
- Balances and the simplest way to pay each other back
- Categories, notes, recurring expenses and statistics
- Many currencies and languages
- Export to CSV and JSON, and an installable web app

## How to use

1. Open Spliit from your dashboard.
2. Click Create a group, name it and add the people in it.
3. Share the group's link with them.
4. Add expenses as they happen, then open Balances to settle up.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6787`. Set `DEFAULT_CURRENCY_CODE` to your currency. There are no accounts: anyone who has a group's link can open and change it, so share links only with the people in the group. The database password is made for you on first start and kept in `/DATA/AppData/spliit/data`. Receipt images, AI features and the other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
