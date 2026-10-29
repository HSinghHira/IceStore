---
site: https://github.com/peppeg/watchsense
services:
  - { name: Web App, path: /, icon: monitor }
screenshots: [Home, Recommendations, Library, Series details]
variables:
  - name: TMDB_API_KEY
    group: TMDB
    default: ""
    description: >-
      Your free TMDB v3 API key from https://www.themoviedb.org/settings/api.
      You can also type it in Settings; a key saved there wins.
  - name: TMDB_LANGUAGE
    group: Language and region
    default: en-US
    description: >-
      Language of titles and summaries from TMDB, like en-GB or it-IT. Only
      used on the first start; change it later in Settings.
  - name: TMDB_REGION
    group: Language and region
    default: US
    description: >-
      Your country as a two-letter code, like GB or IT, for streaming services
      and charts. Only used on the first start; change it later in Settings.
  - name: WATCHSENSE_LOCALE
    group: Language and region
    default: en
    description: >-
      Language of the app and of the AI's answers: en or it. Only used on the
      first start; change it later in Settings.
  - name: LLM_BASE_URL
    group: AI model
    default: ""
    description: >-
      Address of an OpenAI-compatible AI service, like
      https://openrouter.ai/api/v1, or http://[ZIMAOS-IP-ADDRESS]:11434/v1 for
      Ollama. Values saved in Settings win.
  - name: LLM_API_KEY
    group: AI model
    default: ""
    description: >-
      The API key for that service. Not needed for a local Ollama or LM Studio.
  - name: LLM_MODEL
    group: AI model
    default: kilo-auto/free
    description: >-
      The model name, like openai/gpt-4o-mini. The default only exists on Kilo,
      so set it for any other service.
  - name: KILO_API_KEY
    group: AI model
    default: ""
    description: >-
      Older setting: a Kilo key, used only when LLM_BASE_URL and LLM_API_KEY
      are empty.
  - name: KILO_BASE_URL
    group: AI model
    default: https://api.kilo.ai/api/gateway
    description: >-
      Older setting: the Kilo address used with KILO_API_KEY.
  - name: OPENROUTER_API_KEY
    group: AI model
    default: ""
    description: >-
      Older setting: an OpenRouter key, used only when LLM_BASE_URL and
      LLM_API_KEY are empty.
  - name: SYNC_INTERVAL_HOURS
    group: Sync
    default: "12"
    description: >-
      How often, in hours, Netflix is synced on its own. A value picked in
      Settings (6, 12 or 24) wins.
  - name: WATCHSENSE_TOKEN
    group: Access and security
    default: ""
    description: >-
      A long random password to open WatchSense. Leave it out and anyone who
      can reach the address can use it. Use https too if it is reachable from
      the internet.
  - name: WATCHSENSE_SECRET_KEY
    group: Access and security
    default: ""
    description: >-
      Your own key for the saved secrets: 64 hex characters or 32 bytes in
      base64. Leave it out: WatchSense makes secret.key in the data folder on
      first start. Don't change it after you saved keys in Settings.
---

# WatchSense

WatchSense collects what you watched on Netflix, Prime Video, Stremio and Trakt, adds TMDB details and asks an AI model of your choice (cloud or local, like Ollama) what you should watch next. Your thumbs up, thumbs down and taste notes shape the next suggestions.

## Features

- Imports your history from Netflix (automatic sync, bookmarklet or CSV), Prime Video, Stremio and Trakt
- TMDB details in your language: posters, genres and where each show is streaming in your country
- Works with any OpenAI-compatible AI service: OpenRouter, OpenAI, Groq, DeepSeek, Mistral, Kilo, Ollama, LM Studio and more
- Ratings, show status and taste notes feed the next recommendations
- Export your whole history (CSV) and viewer profile (JSON) any time
- Everything in one SQLite file

## How to use

1. Open WatchSense from your dashboard.
2. Follow the Getting started list on the Home page: language and country, your TMDB key, a viewing source and an AI model.
3. Import or sync your viewing history.
4. Open For you to get recommendations, and rate them to make the next ones better.

## Before you install

Get a free TMDB API key at https://www.themoviedb.org/settings/api and pick an AI service (OpenRouter, OpenAI, a local Ollama...). You type both in Settings after install, so nothing has to be set first. From other devices, open `http://[ZIMAOS-IP-ADDRESS]:6173`. There is no login unless you add `WATCHSENSE_TOKEN`, so anyone who can reach the address can use it. For the Trakt import, put your Trakt export in the `exports/trakt` folder of the app data. Every other setting is optional and listed in the Variables tab; to use one, add it in the app settings. WatchSense is ready a few seconds after install. Back up the data folder with `secret.key` in it: the API keys you saved can't be read without it.
