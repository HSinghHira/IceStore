---
source: https://github.com/thecybermacgyver/homi
services:
  - { name: Web App, path: /, icon: grid }
screenshots: [Dashboard, Calendar, Chequebook]
variables:
  - name: HOMI_BOOTSTRAP_NAME
    group: First start
    default: "Household Owner"
    description: >-
      The first administrator's name. Used once, so add it before the first
      start.
  - name: HOMI_BOOTSTRAP_HOUSEHOLD
    group: First start
    default: "Our Home"
    description: >-
      The name of your household. Used once, on the first start.
  - name: HOMI_BOOTSTRAP_LOCALE
    group: First start
    default: "en-CA"
    description: >-
      Your language and region for dates and numbers, such as en-US or en-NZ.
      Used once, on the first start.
  - name: HOMI_BOOTSTRAP_TIME_ZONE
    group: First start
    default: ""
    description: >-
      The household's time zone, such as Pacific/Auckland. Leave empty to use
      your ZimaOS time zone. Used once, on the first start.
  - name: HOMI_CALENDAR_PUBLIC_BASE_URL
    group: Calendar
    default: ""
    description: >-
      The address Calendar puts in its links. Set it to your https address if
      those links show the wrong one.
  - name: HOMI_MODULE_DIRECTORY_URL
    group: More modules
    default: ""
    description: >-
      The https GitHub address of a signed module list, for installing more
      modules in the app. Set it together with the trusted keys.
  - name: HOMI_MODULE_DIRECTORY_TRUSTED_KEYS
    group: More modules
    default: ""
    description: >-
      The public keys that module list is signed with, as JSON from its
      publisher. Set it together with the list address.
  - name: HOMI_GITHUB_TOKEN
    group: More modules
    default: ""
    description: >-
      A GitHub access token, needed only to download modules from private
      releases.
---

# Homi

Homi is a private home for your household: a shared family calendar, a household chequebook and more modules you can add, used in the browser and as an app on your phone. Everything runs on your ZimaOS.

## Features

- Shared household calendar
- Household chequebook to track money in and out
- Members with their own accounts, added by the administrator
- Installable modules, managed in the app
- Works as an app on your phone (add it to the home screen)

## How to use

1. Set up an https reverse proxy, such as Nginx Proxy Manager, with your own domain. Point it at `http://[ZIMAOS-IP-ADDRESS]:6879`, then set `PUBLIC_URL` to the proxy's https address.
2. Open the app logs and find the box marked **CREDENTIALS**. It has your email and first password.
3. Open your https address, sign in and change your password in Homi.
4. Open **Settings** → **Manage modules** and turn on Calendar and Chequebook.
5. Add your family under **Settings** → **Members** → **Add member**. Give each person their email and temporary password yourself; Homi does not send them.

## Before you install

**Homi requires https. Set `PUBLIC_URL` first.** It starts as `https://homi.example.com`: replace that with the https address of your own reverse proxy (such as Nginx Proxy Manager or a Cloudflare tunnel), pointed at `http://[ZIMAOS-IP-ADDRESS]:6879`. Homi only accepts sign-ins from this exact address. On plain `http://[ZIMAOS-IP-ADDRESS]:6879` the browser can't register the device, save changes or add events, and phone install and offline use don't work.

Set `HOMI_BOOTSTRAP_EMAIL` to your email. Leave `HOMI_BOOTSTRAP_PASSWORD` empty to have a password made for you, shown in the **CREDENTIALS** box in the app logs. Calendar and Chequebook are installed for you; other modules, including some shown in the screenshots, are not included and need the module settings in the Variables tab. The first start takes a minute or two. To back up Homi, stop the app and copy `/DATA/AppData/homi/data`. More optional settings are in the Variables tab; add them in the app settings, and add the first-start ones before the first start.
