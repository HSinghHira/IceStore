---
name: AI Gude
site: https://aigude.alexdoes.dev
source: https://github.com/alex0ptr/aigude
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [An Episode]
variables:
  - name: AIGUDE_FIRECRAWL_URL
    group: Service
    default: https://api.firecrawl.dev
    description: >-
      A Firecrawl of your own, like http://192.168.1.20:3002; the key is then
      optional.
  - name: AIGUDE_WORD_BUDGET
    group: Service
    default: "1400"
    description: >-
      Words per Episode when a show sets none; 1400 words are about ten
      minutes.
  - name: AIGUDE_SCRIPT_MODEL
    group: Service
    default: gemini-flash-latest
    description: >-
      The Gemini model that writes the script.
  - name: AIGUDE_TTS_MODEL
    group: Service
    default: gemini-3.8-flash-tts
    description: >-
      The Gemini model that speaks it.
  - name: AIGUDE_CRAWL_CACHE_TTL
    group: Service
    default: 240h
    description: >-
      How long a read article is kept before it is read again.
---

# AI Gude

AI Gude is your own morning podcast. You choose the news sources you follow and how the show should sound; at the times you pick, it reads what is new, writes a script in your style, speaks it with an AI voice and delivers one audio Episode with chapters, made for your phone.

## Features

- Shows built from your RSS feeds, with their own language, voice and style
- Schedules: an Episode every morning, or whenever you like
- Episodes with chapters and a list of what each one used
- Gemini writes and speaks; Firecrawl reads the articles
- Several users, each with their own shows

## How to use

1. Add your `GEMINI_API_KEY` and `FIRECRAWL_API_KEY` before you install.
2. Open AI Gude, pick the sample show and press **Generate now**.
3. Edit your shows and feeds on the config page (or in `me.toml`).

## Before you install

AI Gude needs a Google AI Studio key in `GEMINI_API_KEY` (script and voice) and a Firecrawl key in `FIRECRAWL_API_KEY` (reading articles), unless you run your own Firecrawl. **It has no sign-in**: keep it on your home network, or behind a proxy that sets the `X-Aigude-User` header, and never open its port to the internet.

On the first start upstream's sample show is put in `/DATA/AppData/aigude/users/me.toml`; change it on the config page or in that file (changes are picked up at once). Every service setting is `AIGUDE_` plus the key from upstream's `hack/aigude.toml`; the common ones are in the Variables tab.
