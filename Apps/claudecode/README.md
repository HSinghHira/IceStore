---
site: https://github.com/anthropics/claude-code
source: https://github.com/worph/claude-code-container
services:
  - { name: Web Terminal, path: /, icon: code }
screenshots: [Login page, Claude Code terminal]
variables:
  - name: CLAUDE_SESSION_TTL
    group: Web terminal
    default: "1800"
    description: >-
      Seconds with no browser tab open before the web terminal session is
      closed. The next visit then starts a fresh session.
  - name: DISCOVERY_PORT
    group: MCP API
    default: "9099"
    description: >-
      The UDP port of the auto-discovery beacon. Only used when MCP_ENABLED
      is true.
---

# Claude Code

Run Claude Code, Anthropic's AI coding assistant, in a browser terminal that stays open. Reach it from any device and pick up in the same workspace where you left off.

## Features

- Browser terminal for Claude Code (ttyd) with a login page
- Your session keeps running when you close the tab, and you reconnect to the same one when you come back
- Optional MCP JSON-RPC API so other Claude or automation tools can send it prompts (off by default, see `MCP_ENABLED`)
- Optional OpenAI-compatible `/v1/chat/completions` endpoint that uses the same sign-in
- Your project files, settings, sign-in and history are kept in `/DATA/AppData/claudecode`
- Works on amd64 and arm64

## How to use

1. Open Claude Code from your dashboard.
2. Enter your password on the login page. Unless you typed your own in `AUTH_PASSWORD`, it is in `/DATA/AppData/claudecode/config/password.txt` (open it with the Files app) and in the app log.
3. You are now in a terminal running `claude` in `/home/claude/workspace`.
4. If you left `ANTHROPIC_API_KEY` empty, open the one-time link Claude Code shows and sign in with your Claude Pro or Max subscription.
5. Closing the tab does not end your session. Opening the app again takes you back to it, until it has been idle for 30 minutes.

## Before you install

Put your Anthropic API key in `ANTHROPIC_API_KEY`, or leave it empty to sign in with a Claude subscription. Leave `AUTH_PASSWORD` blank and the app makes its own random password on first start, saved in `config/password.txt` in the app's folder and shown in the app log; or type your own. Leave `MCP_ENABLED` set to `false` unless another tool needs to send prompts to this container, because turning it on shares `AUTH_PASSWORD` with other containers on the same Docker network. Upstream protects the terminal with a separate Caddy container that is not bundled here, so only use this app on your home network. More settings are in the Variables tab and are added in the app settings. The app is ready in under a minute.
