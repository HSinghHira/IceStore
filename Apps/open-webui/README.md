---
site: https://openwebui.com
source: https://github.com/open-webui/open-webui
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: OLLAMA_BASE_URL
    group: Connections
    default: ""
    description: >-
      Your Ollama server, like http://192.168.1.20:6844 for IceStore's
      Ollama (use your ZimaOS IP). You can also add it later in Admin
      Settings, Connections.
  - name: WEBUI_SECRET_KEY
    group: Security
    default: ""
    description: >-
      The secret that signs sign-ins. Made on first start and kept in
      the data folder when left out.
  - name: OPENAI_API_KEY
    group: Connections
    default: ""
    description: >-
      An OpenAI key (or another service's key with OPENAI_API_BASE_URL).
  - name: OPENAI_API_BASE_URL
    group: Connections
    default: ""
    description: >-
      An OpenAI-compatible address, like https://openrouter.ai/api/v1.
  - name: ENABLE_SIGNUP
    group: Sign-in
    default: "true"
    description: >-
      Set to false to stop new sign-ups (the admin can still add users).
  - name: DEFAULT_USER_ROLE
    group: Sign-in
    default: "pending"
    description: >-
      Role for new sign-ups: pending (admin approves), user or admin.
  - name: WEBUI_AUTH
    group: Sign-in
    default: "true"
    description: >-
      Set to false for one user without sign-in (only on a fresh
      install).
  - name: ENABLE_WEB_SEARCH
    group: Features
    default: "false"
    description: >-
      Set to true to allow web search (choose the engine in admin
      settings, like SearXNG).
  - name: WEBUI_URL
    group: Server
    default: ""
    description: >-
      The address people open Open WebUI at, for links and OAuth.
---

# Open WebUI

Open WebUI is a full-featured chat app for your own AI models. Connect Ollama on your ZimaOS or any OpenAI-compatible service, chat with your documents, search the web, and share it with your family with separate accounts.

## Features

- Ollama and OpenAI-compatible connections, with model management
- Chat with documents and knowledge bases (RAG)
- Web search, image generation, voice and video calls
- Tools, functions and pipelines in Python
- Users, groups and roles, with the first account as admin

## How to use

1. Open Open WebUI right away and make the first (admin) account.
2. In Admin Settings, Connections, check your Ollama address or add an API key.
3. Pick a model and chat.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6863 and make your account; the first account is the admin, and new sign-ups wait for your approval. Then add your Ollama (IceStore's Ollama is on port 6844 at your ZimaOS IP) or an API key in Admin Settings, Connections, or set OLLAMA_BASE_URL in the app settings. The first start downloads models for document search and takes a few minutes. The image is large (several GB).
