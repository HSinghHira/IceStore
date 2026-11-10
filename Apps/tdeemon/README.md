---
name: tdeemon
source: https://github.com/tdeemon/tdeemon
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Day, Plan, Progress, Foods]
variables:
  - name: TDEEMON_BACKUP_KEEP
    group: Server
    default: "0"
    description: >-
      How many daily database snapshots to keep in the data folder (up to
      366).
  - name: TDEEMON_LOG_LEVEL
    group: Server
    default: info
    description: >-
      debug, info, warn or error.
  - name: TDEEMON_LOG_FORMAT
    group: Server
    default: json
    description: >-
      json or text.
  - name: TDEEMON_OIDC_ISSUER
    group: Single sign-on
    default: ""
    description: >-
      An OpenID Connect provider's issuer URL (https), like your Authentik
      application. Its redirect is TDEEMON_BASE_URL followed by
      /api/v1/auth/oidc/callback.
  - name: TDEEMON_OIDC_CLIENT_ID
    group: Single sign-on
    default: ""
    description: >-
      tdeemon's client ID at the provider.
  - name: TDEEMON_OIDC_CLIENT_SECRET
    group: Single sign-on
    default: ""
    description: >-
      tdeemon's client secret at the provider.
  - name: TDEEMON_SECRET_KEY
    group: Keys
    default: ""
    description: >-
      Seals single sign-on and derives the push key. Made on first start and
      kept in .icestore/secret_key when left out.
---

# tdeemon

tdeemon is a self-hosted nutrition tracker that measures your real TDEE (the energy you burn) from what you eat and weigh, and lets an AI coach change your plan only with your yes. It is one Go program with one database file.

## Features

- Log meals, foods and recipes; daily targets and macros in a ring
- Adaptive TDEE from your weight trend, with the method shown
- An AI coach (your own model) that proposes plan changes for you to accept
- Weight, sleep, steps and resting heart rate; progress charts
- Invites for family, single sign-on, an API and a phone app view

## How to use

1. Set `TDEEMON_BASE_URL` and `ADMIN_EMAIL` before you install.
2. Copy the password from the app's logs (CREDENTIALS box) and sign in.
3. Set your goal and start logging meals and weight.
4. Invite others in **Settings › Users**.

## Before you install

**Set `TDEEMON_BASE_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6722`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6722`. Put your email in `ADMIN_EMAIL`.

tdeemon has no sign-up page. On the first start the container makes the first admin from `ADMIN_EMAIL` with a made password and shows both in the app's logs, in the box marked CREDENTIALS (upstream does this with `tdeemon user create --admin`). Change the password in Settings, then invite others from **Settings › Users**. The secret key is made on first start and kept in the data folder. More settings are in the Variables tab.
