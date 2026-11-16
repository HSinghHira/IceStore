---
site: https://libretranslate.com
source: https://github.com/LibreTranslate/LibreTranslate
screenshots: [Translate text]
variables:
  - name: LT_API_KEYS
    group: API keys and limits
    default: "false"
    description: >-
      Set to true to turn on API keys. Make keys with ltmanage keys add in the app's terminal.
  - name: LT_REQUIRE_API_KEY_ORIGIN
    group: API keys and limits
    default: ""
    description: >-
      Needs an API key for every request, except from this web address (like your own site).
  - name: LT_REQ_LIMIT
    group: API keys and limits
    default: "-1"
    description: >-
      Most requests per minute from one address. -1 means no limit.
  - name: LT_CHAR_LIMIT
    group: API keys and limits
    default: "-1"
    description: >-
      Most characters in one request. -1 means no limit.
  - name: LT_BATCH_LIMIT
    group: API keys and limits
    default: "-1"
    description: >-
      Most texts in one batch request. -1 means no limit.
  - name: LT_THREADS
    group: Server
    default: "4"
    description: >-
      How many translations can run at the same time. Each one uses more memory.
  - name: LT_TRUST_FORWARDED_FOR
    group: Server
    default: "false"
    description: >-
      Set to true behind a reverse proxy, so limits count each visitor's real address.
  - name: LT_URL_PREFIX
    group: Server
    default: ""
    description: >-
      A sub-path when served behind a reverse proxy, like /translate.
  - name: LT_FRONTEND_LANGUAGE_SOURCE
    group: Web page
    default: "auto"
    description: >-
      The language the web page starts from, like en, or auto to detect it.
  - name: LT_FRONTEND_LANGUAGE_TARGET
    group: Web page
    default: "locale"
    description: >-
      The language the web page translates into, like es, or locale for the browser's language.
  - name: LT_FRONTEND_TITLE
    group: Web page
    default: ""
    description: >-
      Your own title for the web page.
  - name: LT_DISABLE_WEB_UI
    group: Web page
    default: "false"
    description: >-
      Set to true to turn off the web page and keep only the API.
  - name: LT_DISABLE_FILES_TRANSLATION
    group: Web page
    default: "false"
    description: >-
      Set to true to turn off translating files.
  - name: LT_SUGGESTIONS
    group: Web page
    default: "false"
    description: >-
      Set to true to let people suggest better translations.
  - name: LT_DEBUG
    group: Logs
    default: "false"
    description: >-
      Set to true for detailed logs.
---

# LibreTranslate

LibreTranslate translates text and documents on your own server, with no cloud service and no account. Use the web page, or point other apps at its API: many apps support it, like Immich, Paperless, Mealie, browser extensions and Home Assistant.

## Features

- Over 40 languages, all running offline on your box
- Translate text or whole files (Word, PowerPoint, PDF, text)
- Detects the source language by itself
- A simple REST API, with optional API keys and limits
- Works on the CPU; no graphics card needed

## How to use

1. Wait for the first start to finish downloading the languages.
2. Open `http://[ZIMAOS-IP-ADDRESS]:6737` in your browser.
3. Pick the languages, type or paste your text, or upload a file.
4. In other apps, use `http://[ZIMAOS-IP-ADDRESS]:6737` as the LibreTranslate address.

## Before you install

Pick your languages in `LT_LOAD_ONLY` (two-letter codes, comma separated, like `en,es,fr,de,it,ja`); it starts with English, Spanish, French and German. Leaving it blank loads every language, which is about 10 GB and needs a lot of memory. The first start downloads the models and can take 5 to 15 minutes; they are kept in the app folder after that. There is no login, so keep port 6737 on your home network or turn on API keys. Limits, API keys and the other settings are in the Variables tab; add them in the app settings.
