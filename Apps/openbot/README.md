---
site: https://openbot.run
source: https://github.com/nightly-labs/openbot
services:
  - { name: Web App, path: /, icon: globe }
---

# OpenBot

OpenBot runs your AI agents on your ZimaOS. Each agent has its own workspace, conversation and memory, can use a browser and a virtual display, and keeps working when your computer is off. You use the server from the OpenBot desktop app, the phone app or openbot.run/app.

## Features

- Persistent agents that keep their workspace, conversation and identity across restarts
- Many providers, like Claude Code, Codex, Gemini, OpenCode and Hermes Agent
- Browser and computer use in the app's sandbox
- Channels where several agents work in one room
- Routines that run on a schedule, and teams that share the server

## How to use

1. Open OpenBot on your ZimaOS and sign in with your OpenBot account (email and code).
2. Open the OpenBot app or openbot.run/app with the same account and pick this server.
3. Connect a provider on the server, then create your first agent.

## Before you install

OpenBot needs a free OpenBot account: open the app from your dashboard and sign in with your email and the code sent to it, then use the OpenBot desktop app, the phone app or openbot.run/app with the same account. Your agents' conversations and files stay in /DATA/AppData/openbot/data, but OpenBot connects out to its account service, to the relay that lets your devices reach the server, and to the AI providers you connect. Connect the provider on the server itself. Upstream protects the container with its own seccomp profile; a store app cannot ship that file, so this app runs with Docker's seccomp filter turned off, the way the Electron sandbox needs. Agents work inside the container and do not see your ZimaOS files.
