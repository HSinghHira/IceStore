---
name: Octypo
source: https://github.com/KBRglobal/octypo-engine-oss
services:
  - { name: Admin panel, path: /admin, icon: globe }
  - { name: Health, path: /health, icon: info }
screenshots: [Overview, Feeds]
variables:
  - name: OPENAI_API_KEY
    group: Models
    default: ""
    description: >-
      An OpenAI key, as a model provider (and for hero images).
  - name: GEMINI_API_KEY
    group: Models
    default: ""
    description: >-
      A Google Gemini key, as a model provider.
  - name: GROQ_API_KEY
    group: Models
    default: ""
    description: >-
      A Groq key, as a model provider.
  - name: OCTYPO_DAILY_COST_CAP_USD
    group: Models
    default: ""
    description: >-
      Stop generating for the day once model spend reaches this many dollars,
      like 5.
  - name: LANGUAGE_ENGINES_JSON
    group: Models
    default: ""
    description: >-
      A specialist OpenAI-compatible model per language, as JSON (see
      upstream's .env.example).
  - name: CONTENT_DOMAIN
    group: Content
    default: general news and analysis
    description: >-
      What your site is about; it steers every prompt.
  - name: TOPICS_JSON
    group: Content
    default: ""
    description: >-
      Topics for tagging and per-topic daily limits, as a JSON array.
  - name: SITE_URL
    group: Content
    default: ""
    description: >-
      Your public site, for IndexNow pings and rank tracking.
  - name: SITE_LANGUAGE
    group: Content
    default: en
    description: >-
      The site's language as a BCP 47 tag; sets the text direction.
  - name: ARTICLE_PATH_PREFIX
    group: Content
    default: /guides
    description: >-
      The path articles live under on your site.
  - name: AUTO_PUBLISH
    group: Publishing
    default: "false"
    description: >-
      Set to true to publish approved articles straight away instead of
      keeping them as drafts.
  - name: RSS_INTERVAL_MINUTES
    group: Schedules
    default: "30"
    description: >-
      How often feeds are checked.
  - name: RSS_GLOBAL_DAILY_LIMIT
    group: Schedules
    default: "20"
    description: >-
      The most articles written from feeds per day.
  - name: LIBRARY_DAILY_LIMIT
    group: Schedules
    default: "3"
    description: >-
      The most articles written from the document library per day.
  - name: ENABLE_GROWTH_PLANNER
    group: Schedules
    default: "false"
    description: >-
      Set to true for the autonomous growth plan (needs GROWTH_SEEDS).
  - name: ENABLE_IMAGE_GENERATION
    group: Images
    default: "true"
    description: >-
      Hero images, when OPENAI_API_KEY and the R2_* storage settings are set.
  - name: R2_S3_ENDPOINT
    group: Images
    default: ""
    description: >-
      The S3/R2 endpoint for hero images, with R2_ACCESS_KEY_ID,
      R2_SECRET_ACCESS_KEY, R2_BUCKET and R2_PUBLIC_BASE_URL.
---

# Octypo

Octypo is a self-hosted engine that turns RSS feeds and your own documents into articles checked against their sources, in any language. It picks what is worth writing about, writes it, checks it, and holds anything that fails for a person to review. PostgreSQL is inside this one container.

## Features

- Articles written natively in any of 185 languages
- Anthropic, OpenAI, Gemini, Groq, OpenRouter and more, with fallback
- Quality gates: scoring, number checks against sources, duplicate detection
- Drafts by default and a daily spend limit
- Admin panel, REST API and an Astro blog to publish to

## How to use

1. Add a model key (like `ANTHROPIC_API_KEY`) before you install.
2. Open `http://[ZIMAOS-IP-ADDRESS]:6719/admin` and sign in with the password from the app's logs.
3. Add an RSS feed under **Feeds**, or upload documents to the **Library**.
4. Review the drafts and publish.

## Before you install

Octypo needs at least one model key to write anything: put it in `ANTHROPIC_API_KEY`, or add `OPENAI_API_KEY`, `GEMINI_API_KEY` or `GROQ_API_KEY`. The admin password is made on first start and shown in the app's logs, in the box marked CREDENTIALS, unless you set `ADMIN_PASSWORD`. Articles stay drafts until you publish them. Upstream's whole list of settings is in its `.env.example`; the common ones are in the Variables tab, and any other is added the same way in the app settings.
