---
site: https://reelsaw.com
source: https://github.com/osbytes/reelsaw
services:
  - { name: Web App, path: /, icon: globe }
  - { name: MCP Server, path: /api/mcp, icon: plug }
screenshots: [Project workspace, Clip editor, Transcript fixes]
variables:
  - name: SIGNUP_MODE
    group: Sign-up and accounts
    default: "approval"
    description: >-
      open lets anyone sign up, approval makes new accounts wait for an admin,
      closed turns sign-up off. The first account is always the admin.
  - name: ANTHROPIC_API_KEY
    group: AI providers
    default: ""
    description: >-
      Anthropic key, for AI_MODEL=anthropic:claude-sonnet-4-5. Anthropic has
      no speech-to-text, so pair it with another TRANSCRIPTION_MODEL.
  - name: GOOGLE_GENERATIVE_AI_API_KEY
    group: AI providers
    default: ""
    description: >-
      Google Gemini key, for AI_MODEL=google:gemini-2.5-flash.
  - name: GROQ_API_KEY
    group: AI providers
    default: ""
    description: >-
      Groq key, for groq: language models and
      TRANSCRIPTION_MODEL=groq:whisper-large-v3-turbo.
  - name: DEEPGRAM_API_KEY
    group: AI providers
    default: ""
    description: >-
      Deepgram key, for TRANSCRIPTION_MODEL=deepgram:nova-3.
  - name: ASSEMBLYAI_API_KEY
    group: AI providers
    default: ""
    description: >-
      AssemblyAI key, for TRANSCRIPTION_MODEL=assemblyai:best.
  - name: AI_GATEWAY_API_KEY
    group: AI providers
    default: ""
    description: >-
      Vercel AI Gateway key: every cloud vendor as gateway:<vendor>/<model>.
  - name: OPENAI_COMPATIBLE_BASE_URL
    group: Your own AI server
    default: ""
    description: >-
      Your Ollama or other OpenAI-compatible server, like
      http://192.168.1.20:11434/v1. Then use AI_MODEL=compat:qwen2.5:7b.
  - name: OPENAI_COMPATIBLE_API_KEY
    group: Your own AI server
    default: ""
    description: >-
      The key for that server; ollama for Ollama.
  - name: OPENAI_BASE_URL
    group: Your own AI server
    default: ""
    description: >-
      Point the openai provider at a local server, like Speaches for
      speech-to-text: http://192.168.1.20:8000/v1, with
      TRANSCRIPTION_MODEL=openai:Systran/faster-whisper-small and
      OPENAI_API_KEY=local.
  - name: TRANSCRIPT_ALIGN_MODEL
    group: Models
    default: ""
    description: >-
      A second speech-to-text model that re-aligns cuts. Leave it out to use
      TRANSCRIPTION_MODEL.
  - name: ANALYZE_JUDGE_MODEL
    group: Models
    default: ""
    description: >-
      A different language model that scores and compares the moments.
  - name: EMAIL_DRIVER
    group: Email
    default: "none"
    description: >-
      smtp or resend, for approval notices, password resets and "clips are
      ready" notes.
  - name: EMAIL_FROM
    group: Email
    default: ""
    description: >-
      The sender, like Reelsaw <no-reply@example.com>.
  - name: SMTP_URL
    group: Email
    default: ""
    description: >-
      Your email server, like smtps://user:pass@smtp.example.com:465.
  - name: RESEND_API_KEY
    group: Email
    default: ""
    description: >-
      Your Resend key, with EMAIL_DRIVER=resend.
  - name: REQUIRE_EMAIL_VERIFICATION
    group: Email
    default: "false"
    description: >-
      Set to true so people confirm their email before they can sign in.
  - name: MAX_UPLOAD_MB
    group: Videos
    default: "4096"
    description: >-
      The largest video you can upload, in MB.
  - name: MAX_SOURCE_FILE_MB
    group: Videos
    default: "8192"
    description: >-
      The largest file a link may download, in MB.
  - name: ALLOW_PRIVATE_SOURCE_URLS
    group: Videos
    default: "false"
    description: >-
      Set to true to make clips from links on your own network, like a NAS.
  - name: RENDER_CONCURRENCY
    group: Videos
    default: ""
    description: >-
      How many clips render at the same time. Lower it on a small box.
  - name: PEXELS_API_KEY
    group: Stock media
    default: ""
    description: >-
      Free Pexels key: stock photos and videos in Library, Browse.
  - name: PIXABAY_API_KEY
    group: Stock media
    default: ""
    description: >-
      Free Pixabay key: stock images, videos and music.
  - name: FREESOUND_API_KEY
    group: Stock media
    default: ""
    description: >-
      Free Freesound key: sound effects.
  - name: MCP_OAUTH
    group: Server
    default: "false"
    description: >-
      Set to true so claude.ai and Claude Desktop connectors sign in to the
      MCP server through the browser. API keys always work.
  - name: UPDATE_CHECK
    group: Server
    default: "true"
    description: >-
      Set to false to stop asking GitHub for new releases.
  - name: LOG_LEVEL
    group: Logs
    default: "info"
    description: >-
      debug, info, warn or error.
---

# Reelsaw

Reelsaw turns long videos into vertical 9:16 shorts. Paste a YouTube link or upload a video: it transcribes it, asks an AI for the best moments, cuts out fillers and renders clips with face-tracked framing and word-highlight captions. This is Reelsaw in a single container, with PostgreSQL inside, one port and one data folder. The AI runs at a provider you choose, or on your own Ollama.

## Features

- Any AI provider: OpenAI, Anthropic, Google, Groq, Deepgram, or local Ollama and Whisper servers
- Picks and ranks the most clippable moments, with an optional topic
- Smart 9:16 framing: follows the speaker, splits two people, stacks slides and webcam
- Captions with highlighted words, hook overlay, filler cuts you can accept or undo
- Clip editor with timeline, layers, music, intros, outros and templates
- Export with titles and captions, share links, webhooks and an MCP server for AI agents
- PostgreSQL inside

## How to use

1. Open Reelsaw from your dashboard and sign up. The first account is the admin.
2. Paste a YouTube link or upload a video.
3. Wait for the clips, then edit, download or share them.

## Before you install

**You must set `PUBLIC_URL` first.** It starts as `http://[ZIMAOS-IP-ADDRESS]:6690`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6690`, or use your https address. Sign-in only works on that address; until it is set, Reelsaw only opens on the server itself and shows a note everywhere else.

**You must also set an AI provider**, or Reelsaw stops at start and the page says so. With the default models that is `OPENAI_API_KEY`. For another provider, change `AI_MODEL` and `TRANSCRIPTION_MODEL` and add its key from the Variables tab; for your own Ollama, set `OPENAI_COMPATIBLE_BASE_URL` and `AI_MODEL=compat:<model>`. The speech-to-text model must return word times. After the first start, admins can switch models and enter keys in Settings, System, Models.

There is no password to set: the first person to sign up is the admin, and later sign-ups wait for approval (`SIGNUP_MODE`). Videos and renders take a lot of disk space. Email and the other settings are in the Variables tab; add them in the app settings. The first start takes about 2 minutes.
