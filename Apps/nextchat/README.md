---
source: https://github.com/ChatGPTNextWeb/NextChat
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: OPENAI_API_KEY
    group: Server keys
    default: ""
    description: >-
      An OpenAI key for everyone (set CODE too).
  - name: CODE
    group: Security
    default: ""
    description: >-
      Access passwords, comma separated, needed to use the server keys.
  - name: BASE_URL
    group: Server keys
    default: ""
    description: >-
      An OpenAI-compatible address instead of OpenAI, like
      http://192.168.1.20:6844 for Ollama.
  - name: ANTHROPIC_API_KEY
    group: Server keys
    default: ""
    description: >-
      An Anthropic key for everyone.
  - name: GOOGLE_API_KEY
    group: Server keys
    default: ""
    description: >-
      A Google Gemini key for everyone.
  - name: DEEPSEEK_API_KEY
    group: Server keys
    default: ""
    description: >-
      A DeepSeek key for everyone.
  - name: CUSTOM_MODELS
    group: Models
    default: ""
    description: >-
      Models to add or hide, like +llama3.2,-gpt-4.
  - name: DEFAULT_MODEL
    group: Models
    default: ""
    description: >-
      The model new chats start with.
  - name: HIDE_USER_API_KEY
    group: Security
    default: ""
    description: >-
      Set to 1 to stop people entering their own keys.
  - name: DISABLE_GPT4
    group: Models
    default: ""
    description: >-
      Set to 1 to hide GPT-4 models.
---

# NextChat

NextChat is a clean chat app for AI models. Bring your own key for OpenAI, Anthropic, Google, DeepSeek and others, or use local models, and keep your chats in your browser. Masks (prompt templates) and Markdown make it handy for everyday work.

## Features

- OpenAI, Anthropic, Google Gemini, DeepSeek, Moonshot and other providers
- Masks with your own prompts, and a prompt library
- Markdown, code highlighting, LaTeX and Mermaid
- Chats kept in your browser, with export and sync to WebDAV or Upstash
- Optional access password when you set server keys

## How to use

1. Open NextChat, press Settings and enter your API key and provider.
2. Start chatting.

## Before you install

NextChat keeps chats in the browser you use and has no accounts. Without server keys, each person enters their own API key in Settings. If you add a key in the app settings (Variables tab), set CODE to an access password too, or anyone on your network can use your key. For Ollama on this ZimaOS, set BASE_URL to http://[ZIMAOS-IP-ADDRESS]:6844 and add the model with CUSTOM_MODELS.
