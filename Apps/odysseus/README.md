---
site: https://odysseus-dev.github.io/odysseus
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Chat workspace]
variables:
  - name: OLLAMA_BASE_URL
    group: Models
    default: ""
    description: >-
      The address of your Ollama server, like http://192.168.1.20:11434/v1.
      You can also add it later in Settings.
  - name: LM_STUDIO_URL
    group: Models
    default: ""
    description: >-
      The address of your LM Studio server, like http://192.168.1.20:1234.
  - name: LLM_HOST
    group: Models
    default: localhost
    description: >-
      The main computer to look for model servers on, like 192.168.1.20.
  - name: LLM_HOSTS
    group: Models
    default: ""
    description: >-
      More computers to look for model servers on, separated by commas.
  - name: OPENAI_API_KEY
    group: Models
    default: ""
    description: >-
      Your OpenAI API key, for OpenAI models.
  - name: RESEARCH_LLM_ENDPOINT
    group: Models
    default: ""
    description: >-
      A chat completions address used only for Deep Research, like
      http://192.168.1.20:8000/v1/chat/completions.
  - name: HF_TOKEN
    group: Models
    default: ""
    description: >-
      Your Hugging Face token, for downloading gated models in Cookbook.
  - name: EMBEDDING_URL
    group: Memory
    default: ""
    description: >-
      An OpenAI-compatible embeddings address. Leave it out to use the small
      built-in embedding model.
  - name: EMBEDDING_MODEL
    group: Memory
    default: ""
    description: >-
      The embeddings model name on that server.
  - name: EMBEDDING_API_KEY
    group: Memory
    default: ""
    description: >-
      The API key for that embeddings server.
  - name: FASTEMBED_MODEL
    group: Memory
    default: sentence-transformers/all-MiniLM-L6-v2
    description: >-
      The built-in embedding model to use.
  - name: TAVILY_API_KEY
    group: Web search
    default: ""
    description: >-
      Your Tavily key, to search with Tavily as well as the built-in SearXNG.
  - name: DATA_BRAVE_API_KEY
    group: Web search
    default: ""
    description: >-
      Your Brave Search API key.
  - name: SERPER_API_KEY
    group: Web search
    default: ""
    description: >-
      Your Serper (Google results) API key.
  - name: GOOGLE_API_KEY
    group: Web search
    default: ""
    description: >-
      Your Google Programmable Search API key (with GOOGLE_PSE_CX).
  - name: GOOGLE_PSE_CX
    group: Web search
    default: ""
    description: >-
      Your Google Programmable Search engine ID.
  - name: YDC_API_KEY
    group: Web search
    default: ""
    description: >-
      Your You.com API key.
  - name: GOOGLE_OAUTH_CLIENT_ID
    group: Google account (email, calendar)
    default: ""
    description: >-
      Your Google OAuth client ID, to connect Gmail and Google Calendar.
  - name: GOOGLE_OAUTH_CLIENT_SECRET
    group: Google account (email, calendar)
    default: ""
    description: >-
      Your Google OAuth client secret.
  - name: OAUTH_REDIRECT_BASE_URL
    group: Google account (email, calendar)
    default: ""
    description: >-
      The address Google sends you back to, like
      http://192.168.1.20:6753. Add it to your Google OAuth client too.
  - name: GOOGLE_OAUTH_REDIRECT_URI
    group: Google account (email, calendar)
    default: ""
    description: >-
      The full redirect address, if it differs from the one Odysseus builds
      from OAUTH_REDIRECT_BASE_URL.
  - name: ODYSSEUS_ADMIN_USER
    group: Sign-in
    default: admin
    description: >-
      The name of the admin made on first start.
  - name: ALLOWED_ORIGINS
    group: Sign-in
    default: http://localhost,http://127.0.0.1
    description: >-
      Other websites allowed to call the Odysseus API from a browser,
      separated by commas. Not needed to use Odysseus itself.
  - name: SECURE_COOKIES
    group: Sign-in
    default: ""
    description: >-
      Set to true when Odysseus is only reached over https.
  - name: COMPANION_BASE_URL
    group: Sign-in
    default: ""
    description: >-
      The address the phone companion app uses, like
      http://192.168.1.20:6753.
  - name: CLEANUP_INTERVAL_HOURS
    group: Server
    default: "24"
    description: >-
      How often old temporary files are cleaned up, in hours.
  - name: ODYSSEUS_CHAT_UPLOAD_MAX_BYTES
    group: Server
    default: "10485760"
    description: >-
      The largest file you can attach to a chat, in bytes.
  - name: ODYSSEUS_FIRST_TOKEN_TIMEOUT
    group: Server
    default: ""
    description: >-
      How many seconds to wait for a slow model's first word before giving
      up.
---

# Odysseus

Odysseus is a self-hosted AI workspace. Chat with local or online models, let agents use tools, run deep web research, and keep your documents, email, notes and calendar in one place. ChromaDB memory and SearXNG private web search are built in, so it is one container.

## Features

- Chat and agents with local models (Ollama, LM Studio, vLLM) or API models (OpenAI and compatible)
- Deep Research: multi-step web research with source reading and a written report
- Compare models side by side, blind
- Documents editor with AI edits and suggestions
- Email inbox (IMAP/SMTP), notes, tasks and a calendar with CalDAV sync
- Memory, file uploads, MCP tools, skills and two-factor sign-in

## How to use

1. Open Odysseus from your dashboard.
2. Sign in as `admin` with the password from the app's logs (the box marked CREDENTIALS).
3. Go to Settings and add a model provider: your Ollama address, like `http://192.168.1.20:11434`, or an OpenAI API key.
4. Start a chat, or open Research and ask a question.

This app has no AI model inside. Use Ollama or another model server, or an online API. Left out: ntfy and the GPU overlays.

## Before you install

You can leave `ODYSSEUS_ADMIN_PASSWORD` empty: a password is made on first start and shown in the app's logs in the box marked CREDENTIALS. Open it from other devices at `http://[ZIMAOS-IP-ADDRESS]:6753`. You need a model: install Ollama (set it to listen on all addresses) or have an API key ready. More settings (model servers, search API keys, Google account) are in the Variables tab; add them in the app settings. The first start takes about 3 minutes; the first chat downloads a small embedding model.
