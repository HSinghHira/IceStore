---
site: https://lemmary.app
source: https://github.com/buldezir/lemmary
services:
  - { name: Web App, path: /, icon: globe }
  - { name: MCP Server, path: /api/mcp, icon: plug }
screenshots: [Documents, Document detail, AI assisted search, Deep Research, Admin settings]
variables:
  - name: SETUP_ADMIN_EMAIL
    group: First start
    default: ""
    description: >-
      The admin email, to skip that wizard step. Used on the first start
      only.
  - name: SETUP_ADMIN_PASSWORD
    group: First start
    default: ""
    description: >-
      The admin password, with SETUP_ADMIN_EMAIL. Used on the first start
      only.
  - name: AI_SDK
    group: AI (first start)
    default: "opencode"
    description: >-
      The AI provider: opencode, mistral, openai, openrouter or anthropic.
      Used on the first start only; change it later in Admin.
  - name: AI_API_KEY
    group: AI (first start)
    default: ""
    description: >-
      The key for that provider, so the wizard skips the AI step. Used on
      the first start only.
  - name: AI_MODEL
    group: AI (first start)
    default: "deepseek-v4-flash"
    description: >-
      The general AI model for naming, tagging and search.
  - name: AI_BASE_URL
    group: AI (first start)
    default: ""
    description: >-
      Another OpenAI-compatible server, like http://192.168.1.20:11434/v1.
  - name: OCR_SDK
    group: AI (first start)
    default: ""
    description: >-
      The OCR provider for scans: mistral, google_vision, openai, docling and
      others. Leave it out to choose in the wizard.
  - name: OCR_API_KEY
    group: AI (first start)
    default: ""
    description: >-
      The key for the OCR provider.
  - name: INGEST_IMAP_ENABLED
    group: Import
    default: ""
    description: >-
      Set to 1 to import attachments from an email inbox. Set up the inbox
      in Admin, Ingest.
  - name: UPLOAD_MAX_MB
    group: Import
    default: "100"
    description: >-
      The largest PDF you can upload to split into documents, in MB.
  - name: IMPORT_ALLOW_PRIVATE
    group: Import
    default: "1"
    description: >-
      Set to 0 to stop the Paperless-ngx and Papra imports reaching servers
      on your own network.
  - name: WORKER_CONCURRENCY
    group: Processing
    default: "1"
    description: >-
      How many documents are processed at once. Keep 1 for local OCR.
  - name: VAULT_ENABLED
    group: Encryption at rest
    default: ""
    description: >-
      Set to 1 to keep only encrypted files in the data folder. The app
      then starts locked until someone signs in. Read Lemmary's encryption
      guide first.
  - name: MCP_ENABLED
    group: Server
    default: "1"
    description: >-
      Set to 0 to turn off the MCP server for AI agents at /api/mcp.
  - name: UPDATE_CHECK_ENABLED
    group: Server
    default: "1"
    description: >-
      Set to 0 to stop checking GitHub for new versions.
  - name: PASSKEY_RP_ID
    group: Server
    default: ""
    description: >-
      Your domain for passkeys, like archive.example.com. Leave it out to use
      the address you open. Changing it removes every passkey.
  - name: LOG_LEVEL
    group: Logs
    default: ""
    description: >-
      debug, info, warn or error, to copy the log to the app log.
---

# Lemmary

Lemmary is a document archive: upload scans, PDFs, Word and Excel files, and it reads them (OCR), names, dates, tags and summarises them with AI, then lets you search and ask questions across the whole library in plain language. It speaks Paperless-ngx's API, so Paperless apps work with it too.

## Features

- OCR and AI metadata: title, date, type, tags, correspondent and summary
- Full-text search, AI assisted search and Deep Research with cited answers
- Review inbox for low-confidence results and possible duplicates
- Import from a watched folder, an email inbox, a network scanner, Paperless-ngx or Papra
- Paperless-ngx compatible API and an MCP server for AI agents
- Passkeys, full backup and restore, optional encryption at rest

## How to use

1. Open Lemmary from your dashboard.
2. Follow the setup wizard: create the admin account and add your AI key.
3. Upload documents, or drop them in the consume folder.

## Before you install

Lemmary needs an AI provider for reading and naming documents; one Mistral key covers OCR, naming and search, and OpenAI, Anthropic, OpenRouter, Opencode or your own server work too. There is nothing to set before install: the setup wizard on first open creates the admin account and asks for the keys. To skip the wizard, add `SETUP_ADMIN_EMAIL`, `SETUP_ADMIN_PASSWORD` and `AI_API_KEY` from the Variables tab before the first start; they are read only once, and Lemmary's Admin page is where you change them later.

Files you drop in the consume folder (`/DATA/AppData/lemmary/consume`) are imported on their own; subfolders become tags. Lemmary is source-available under the PolyForm Noncommercial license: free for personal use, not for business use.
