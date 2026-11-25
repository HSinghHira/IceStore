---
site: https://www.langflow.org
source: https://github.com/langflow-ai/langflow
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: LANGFLOW_SUPERUSER_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The admin password. Made on first start and kept in the data
      folder when left out.
  - name: LANGFLOW_SECRET_KEY
    group: Security
    default: ""
    description: >-
      The key that encrypts saved API keys. Made on first start; never
      change it afterwards.
  - name: LANGFLOW_NEW_USER_IS_ACTIVE
    group: Sign-in
    default: "False"
    description: >-
      Set to True to let new sign-ups in without approval.
  - name: LANGFLOW_LOG_LEVEL
    group: Logging
    default: "error"
    description: >-
      How much is logged: debug, info, warning, error or critical.
  - name: LANGFLOW_WORKERS
    group: Server
    default: "1"
    description: >-
      How many worker processes run flows.
  - name: DO_NOT_TRACK
    group: Server
    default: ""
    description: >-
      Set to true to turn off usage statistics.
---

# Langflow

Langflow lets you build AI agents, RAG pipelines and chat flows by dragging components onto a canvas and wiring them together. Test them in the playground, then call them from your apps through the API or MCP.

## Features

- Visual editor with components for models, prompts, tools, memory and vector stores
- OpenAI, Anthropic, Google, Ollama and many more providers
- Playground to chat with a flow while you build it
- Every flow becomes an API endpoint and an MCP tool
- Starter templates and Python custom components

## How to use

1. Open Langflow and sign in as admin with the password from the CREDENTIALS box in the app's logs.
2. Start from a template, add your model's API key, and run it in the playground.

## Before you install

Langflow's automatic sign-in is turned off here: the admin password is made on first start and shown in the app's logs, in the box marked CREDENTIALS. Flows can run Python code inside the container, so only give accounts to people you trust. API keys you save in Langflow are encrypted with a key made on first start and kept in /DATA/AppData/langflow/data.
