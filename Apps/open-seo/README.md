---
name: OpenSEO
site: https://openseo.so
services:
  - { name: Web App, path: /, icon: globe }
  - { name: MCP server, path: /mcp, icon: plug }
screenshots: [Keyword research]
variables:
  - name: TREG_API_TOKEN
    group: Data
    default: ""
    description: >-
      A treg.to token, instead of a DataForSEO account: the same data, paid
      per call.
  - name: OPENROUTER_API_KEY
    group: AI
    default: ""
    description: >-
      Your OpenRouter key, for SAM (the AI helper), website research and
      prompt suggestions. SAM is hidden without it.
  - name: OPENROUTER_BASE_URL
    group: AI
    default: ""
    description: >-
      Another OpenAI-compatible server instead of OpenRouter, like your
      Ollama at http://192.168.1.20:11434/v1.
  - name: OPENROUTER_MODEL
    group: AI
    default: ""
    description: >-
      The model to use on that server.
  - name: GOOGLE_CLIENT_ID
    group: Google Search Console
    default: ""
    description: >-
      Your Google OAuth client ID, to link Search Console and Analytics.
  - name: GOOGLE_CLIENT_SECRET
    group: Google Search Console
    default: ""
    description: >-
      Your Google OAuth client secret.
  - name: BETTER_AUTH_SECRET
    group: Google Search Console
    default: ""
    description: >-
      A random value of at least 32 characters that encrypts the stored
      Google tokens. Set it once and keep it.
  - name: GOOGLE_MAPS_API_KEY
    group: Features
    default: ""
    description: >-
      A Google Map Tiles API key, for the Local SEO map.
  - name: CONTEXT_API_KEY
    group: Features
    default: ""
    description: >-
      A Context.dev key, to render JavaScript pages in site audits.
  - name: CRAWLER_ACCESS_SECRET
    group: Features
    default: ""
    description: >-
      A random value of at least 32 characters, to save Shopify crawler
      signatures. Keep it once set.
  - name: ALLOWED_HOST
    group: Server
    default: ""
    description: >-
      The domain name you reach OpenSEO at through a reverse proxy, like
      seo.example.com. IP addresses always work.
  - name: OPENSEO_TELEMETRY_DISABLED
    group: Server
    default: ""
    description: >-
      Set to 1 to stop the anonymous usage counts sent to the OpenSEO team.
---

# OpenSEO

OpenSEO is an open-source alternative to Semrush and Ahrefs. Research keywords, check backlinks, track rankings and audit your site, paying DataForSEO only for what you use instead of a monthly plan.

## Features

- Keyword research with volume, difficulty and ideas
- Backlink and domain overview for any site
- Rank tracking with history, daily, weekly or monthly
- Site audits of up to 10,000 pages
- AI Visibility: how AI answers mention your brand
- SAM, an AI helper (with an OpenRouter key), and an MCP server

## How to use

1. Set `DATAFORSEO_API_KEY` before you install.
2. Open OpenSEO from your dashboard. There is no sign-in.
3. Make a project for your website.
4. Search keywords, add them to a rank tracker, or start a site audit.

## Before you install

**Set `DATAFORSEO_API_KEY` first.** Make an account at dataforseo.com, write `login:password` with your login and API password, base64-encode it and paste the result in place of `CHANGEME` (or set `TREG_API_TOKEN` in the app settings instead).

**There is no sign-in.** This is upstream's single-container Docker mode (`AUTH_MODE=local_noauth`): anyone who can open `http://[ZIMAOS-IP-ADDRESS]:6756` can use the app and your DataForSEO credit. Keep it on your home network, or put a reverse proxy with its own login in front of it. Upstream's newer standalone setup has accounts but needs five containers and https, so it is not used here.

The first start builds the app and takes about 3 minutes. More settings (OpenRouter, Google Search Console) are in the Variables tab; add them in the app settings.
