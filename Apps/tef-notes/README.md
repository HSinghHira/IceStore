---
name: TEF Notes
source: https://github.com/spyrosbazios/tef-notes
services:
  - { name: Web App, path: /, icon: globe }
  - { name: PocketBase admin, path: /_/, icon: server }
screenshots: [Home, Overview]
variables:
  - name: TEF_NOTES_MODEL
    group: AI assistant
    default: ""
    description: >-
      The model to use. Left out, the provider's default; Ollama needs a model
      you have pulled.
  - name: TEF_NOTES_LLM_URL
    group: AI assistant
    default: ""
    description: >-
      The provider's API address, if not its own (for example another region).
  - name: TEF_NOTES_OLLAMA_URL
    group: AI assistant
    default: ""
    description: >-
      Your Ollama server with TEF_NOTES_PROVIDER=ollama, like
      http://192.168.1.20:11434.
  - name: TEF_NOTES_TYPESAFE_KEY
    group: AI assistant
    default: ""
    description: >-
      A JEV (typesafe) key for automatic tags and clip suggestions.
  - name: TEF_NOTES_EXA_KEY
    group: AI assistant
    default: ""
    description: >-
      An Exa key, so the assistant can search the web.
  - name: TEF_NOTES_MCP
    group: AI assistant
    default: "0"
    description: >-
      Set to 1 to serve the note and task tools to other agents (Claude Code,
      Cursor...) at /agent/mcp.
  - name: TEF_NOTES_STT
    group: Voice input
    default: http://127.0.0.1:8099
    description: >-
      Set it empty to turn voice input off (nothing is downloaded then).
  - name: TEF_NOTES_VAPID_SUBJECT
    group: Reminders
    default: ""
    description: >-
      A mailto: or https address the push services may reach you at. Task
      reminders on phones are off until it is set.
  - name: TEF_NOTES_PUSH_KEY
    group: Reminders
    default: ""
    description: >-
      Your own VAPID private key. Left out, one is made on first start.
---

# TEF Notes

TEF Notes is a self-hosted home for notes and tasks: a web app you can install on your phone that works offline, a Chrome clipper, a CLI and an optional AI assistant that reads, writes and searches your notes. PocketBase, the assistant and voice input run inside this one container.

## Features

- Notes with tags, images and attachments; tasks with Today, Upcoming and a calendar
- Works offline and installs as an app on Android (needs https)
- Optional AI assistant with the provider you choose (DeepSeek, Anthropic, OpenAI, Ollama and more) and search by meaning
- Voice input with speech-to-text on your server
- Task reminders as push notifications, a CLI and an MCP server

## How to use

1. Open TEF Notes from your dashboard.
2. Write notes and add tasks; they sync to every device.
3. For the assistant, set your provider's key in the app settings.

## Before you install

**TEF Notes has no sign-in.** Anyone who can reach the port can read and change your notes, so keep it on your home network or behind a VPN like Tailscale, and never open it to the internet. The PocketBase admin UI at `/_/` has its own login: on the first start PocketBase prints a one-time link in the logs to create it.

For the AI assistant set `TEF_NOTES_PROVIDER` and your key in `TEF_NOTES_LLM_KEY`; leave the key empty to use it without AI. Over plain http the web app works, but the microphone and "Install app" need https. Voice input downloads a speech model (~460 MB) the first time you use it. More settings are in the Variables tab.
