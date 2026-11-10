---
name: CartVibe
source: https://github.com/wouekk/cartvibe
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Dashboard (dark), Dashboard (light), Receipts, Receipt products]
variables:
  - name: PUID
    group: Server
    default: ""
    description: >-
      Run the API as this user instead of the image's own user.
  - name: PGID
    group: Server
    default: ""
    description: >-
      The group to run the API as, with PUID.
  - name: VAPID_PUBLIC_KEY
    group: Push notifications
    default: ""
    description: >-
      The public half of a VAPID key pair, for push notifications on phones.
  - name: VAPID_PRIVATE_KEY
    group: Push notifications
    default: ""
    description: >-
      The private half of that VAPID key pair.
  - name: VAPID_SUBJECT
    group: Push notifications
    default: ""
    description: >-
      Your contact for the push services, like mailto:you@example.com.
  - name: SECRET_KEY
    group: Keys
    default: ""
    description: >-
      Signs sign-in cookies. Made on first start when left out; changing it
      signs everyone out.
  - name: ENCRYPTION_KEY
    group: Keys
    default: ""
    description: >-
      Encrypts the keys you save in the app. Made on first start when left
      out; never change it afterwards.
---

# CartVibe

CartVibe keeps your household's shopping in one place: snap a receipt and it is read for you, plan shared shopping lists, and see where the money goes. Valkey (the job queue) is inside this one container, and both keys are made for you on first start.

## Features

- Receipts read from a photo (OCR, or AI with your own key), with products and prices
- Shared shopping lists that update live for the whole family
- Dashboard: spending by category, month and tag, budgets and goals
- Barcode scanner with Nutri-Score and nutrition from Open Food Facts
- Family accounts, five languages, installs like an app on phones

## How to use

1. Open CartVibe from your dashboard and sign in with `admin` / `admin`. There is no sign-up page. Change that password right away under **Management → Users**, the key icon on your row; add family members there too.
2. Add a receipt from a photo, or start a shopping list.
3. On your phone, open the same address and add it to the Home Screen.

## Before you install

Nothing to set first. **The first sign-in is `admin` / `admin`**: CartVibe makes that account itself on the first start, so change its password straight after you sign in. `SECRET_KEY` and `ENCRYPTION_KEY` are made on the first start and kept in `/DATA/AppData/cartvibe/sqlite/.icestore`; back up the whole app folder, since without `ENCRYPTION_KEY` the AI and sign-in keys you saved can't be read. AI providers, shop logos and other options are set in CartVibe's own settings. The image is amd64 only, as upstream publishes it.
