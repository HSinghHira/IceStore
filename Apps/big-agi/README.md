---
site: https://big-agi.com
source: https://github.com/enricoros/big-AGI
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: OPENAI_API_KEY
    group: Server keys
    default: ""
    description: >-
      An OpenAI key for everyone who opens this big-AGI.
  - name: ANTHROPIC_API_KEY
    group: Server keys
    default: ""
    description: >-
      An Anthropic key for everyone.
  - name: GEMINI_API_KEY
    group: Server keys
    default: ""
    description: >-
      A Google Gemini key for everyone.
  - name: OLLAMA_API_HOST
    group: Server keys
    default: ""
    description: >-
      Your Ollama for everyone, like http://192.168.1.20:6844.
  - name: OPENROUTER_API_KEY
    group: Server keys
    default: ""
    description: >-
      An OpenRouter key for everyone.
  - name: GROQ_API_KEY
    group: Server keys
    default: ""
    description: >-
      A Groq key for everyone.
  - name: MISTRAL_API_KEY
    group: Server keys
    default: ""
    description: >-
      A Mistral key for everyone.
---

# big-AGI

big-AGI is a chat app for working with many AI models at once. Compare answers from OpenAI, Anthropic, Google, Mistral, Groq, OpenRouter and your own Ollama side by side, use personas, voice, drawing and code tools.

## Features

- Many providers and local models (Ollama, LM Studio, LocalAI)
- Beam to ask several models at once and merge the best answer
- Personas, voice input and output, and image generation
- Code highlighting, diagrams and document attachments
- Chats and keys kept in your browser

## How to use

1. Open big-AGI and press Models, then add a service with your API key or your Ollama address.
2. Start chatting.

## Before you install

big-AGI has no login and keeps chats and API keys in the browser you use. Keys set in the app settings (Variables tab) are used by everyone who opens it, so only add them if you trust everyone on your network. For Ollama on this ZimaOS, use http://[ZIMAOS-IP-ADDRESS]:6844.
