---
site: https://overtchat.com
source: https://github.com/yoloyash/overtchat
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Chat, Voice, Search with sources, Agent connections]
variables:
  - name: EXTRA_TRUSTED_ORIGINS
    group: Server
    default: ""
    description: >-
      More addresses you open OvertChat at, comma-separated, with http(s) and
      port, like https://chat.example.com. http://localhost:6139 is added for
      you.
  - name: HOST_CONNECTOR_URL
    group: Server
    default: ""
    description: >-
      The address a Host Connector on another computer uses to reach this
      server. Leave it out to use BETTER_AUTH_URL.
  - name: BETTER_AUTH_SECRET
    group: Server
    default: ""
    description: >-
      Your own sign-in key, at least 32 random characters. Leave it out: each
      install makes its own on first start and keeps it in the data folder as
      .better_auth_secret. Changing it signs everyone out.
  - name: REDIS_URL
    group: Server
    default: ""
    description: >-
      A Redis server, like redis://192.168.1.20:6379, so an answer can carry
      on after a page reload. Leave it out to run without one.
  - name: DISABLE_UPDATE_CHECK
    group: Server
    default: "false"
    description: >-
      Set to true so the admin menu doesn't check overtchat.com for new
      releases.
  - name: OVERTCHAT_REQUIRE_ADMIN_TWO_FACTOR
    group: Sign-in
    default: "false"
    description: >-
      Set to true so admin accounts must turn on two-factor sign-in.
  - name: WEB_SEARCH_PROVIDER
    group: Web search
    default: ""
    description: >-
      The search service to try first: searxng, brave or disabled. Leave it
      out to use the free search services, or to pick one in Settings.
  - name: SEARXNG_URL
    group: Web search
    default: ""
    description: >-
      Your SearXNG server, like http://192.168.1.20:6116. It must allow JSON
      results.
  - name: BRAVE_SEARCH_API_KEY
    group: Web search
    default: ""
    description: >-
      A Brave Search API key, to use Brave as the search service.
  - name: TTS_PROVIDER
    group: Text to speech
    default: ""
    description: >-
      openai-compatible to use your own text-to-speech server, or disabled.
      Setting KOKORO_URL alone also picks openai-compatible.
  - name: KOKORO_URL
    group: Text to speech
    default: ""
    description: >-
      Your Kokoro-FastAPI or other OpenAI-compatible text-to-speech server,
      like http://192.168.1.20:8880.
  - name: TTS_MODEL
    group: Text to speech
    default: kokoro
    description: >-
      The text-to-speech model name for that service. Default kokoro.
  - name: TTS_VOICE
    group: Text to speech
    default: af_heart
    description: >-
      The voice to speak with, like af_heart for Kokoro.
  - name: TTS_API_KEY
    group: Text to speech
    default: ""
    description: >-
      The API key for the text-to-speech service, if it needs one.
  - name: STT_PROVIDER
    group: Speech to text
    default: ""
    description: >-
      openai-compatible to use your own speech-to-text server, or disabled.
      Setting STT_URL alone also picks openai-compatible.
  - name: STT_URL
    group: Speech to text
    default: ""
    description: >-
      Your OpenAI-compatible speech-to-text server, like
      http://192.168.1.20:5092.
  - name: STT_MODEL
    group: Speech to text
    default: parakeet-tdt-0.6b-v3
    description: >-
      The speech-to-text model name for that service.
  - name: STT_API_KEY
    group: Speech to text
    default: ""
    description: >-
      The API key for the speech-to-text service, if it needs one.
  - name: SANDBOX_URL
    group: Code execution
    default: ""
    description: >-
      Your OvertChat code sandbox (ghcr.io/yoloyash/overtchat-sandbox), like
      http://192.168.1.20:8080, so the AI can run Python.
  - name: SANDBOX_TOKEN
    group: Code execution
    default: ""
    description: >-
      The token shared with the sandbox, if you set one there.
---

# OvertChat

OvertChat is a self-hosted home for everyday AI. Connect vLLM, llama.cpp, SGLang or Ollama-style endpoints, or a hosted provider, and start chatting. Search the web, work with files or talk by voice, with your history on your own server. Search and speech services are not bundled: add your own in the settings.

## Features

- Clean chat with readable answers, collapsible reasoning, projects, reusable files and searchable history
- Model setup and discovery for vLLM, llama.cpp and SGLang, plus hosted providers and any OpenAI-compatible endpoint
- Web search with free fallbacks (DuckDuckGo, Exa, Firecrawl), or your own SearXNG or Brave key
- Two-way voice chat with your own speech services
- Accounts for your family, each with their own chats
- Android, iOS and desktop apps that connect to your server
- Connect coding agents (Codex, Claude Code, OpenCode and more) through the Host Connector

## How to use

1. Open the app log in your dashboard and copy the setup code.
2. Open OvertChat at `http://[ZIMAOS-IP-ADDRESS]:6139` and create your admin account with the setup code.
3. Add your model endpoint in Settings.
4. Start chatting. Add accounts for your family in Settings, Users.

## Before you install

**You must set `BETTER_AUTH_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6139`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6139`, or use your https address behind a reverse proxy. Until then only `http://localhost:6139` on the box itself can sign in. After install, the app log shows "Create your administrator account with setup code ..."; use that code for the first account. A model running on the same ZimaOS is at `http://[ZIMAOS-IP-ADDRESS]:<its port>`, not localhost. Voice needs https outside localhost. Every other setting is optional and listed in the Variables tab; to use one, add it in the app settings. OvertChat is ready about a minute after install. Each install makes its own sign-in key on first start.
