---
site: https://livebook.dev
source: https://github.com/livebook-dev/livebook
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: LIVEBOOK_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The password (at least 12 characters). Made on first start and
      kept in the data folder when left out.
  - name: LIVEBOOK_SECRET_KEY_BASE
    group: Security
    default: ""
    description: >-
      The key that signs sessions. Made on first start; changing it
      signs everyone out.
  - name: LIVEBOOK_DEFAULT_RUNTIME
    group: Runtime
    default: "standalone"
    description: >-
      standalone runs each notebook in its own process; embedded runs
      them inside Livebook.
  - name: LIVEBOOK_TOKEN_ENABLED
    group: Sign-in
    default: ""
    description: >-
      Set to false to turn off the password (anyone on your network
      could run code).
---

# Livebook

Livebook is a notebook for Elixir: write code, Markdown and charts in one document, explore data, build small apps and work with AI models. Several people can edit the same notebook at once.

## Features

- Code, Markdown, charts, tables and maps in one notebook
- Smart cells for databases, charts, maps and AI models
- Real-time collaboration on the same notebook
- Turn notebooks into apps you can share
- Notebooks saved as plain .livemd files

## How to use

1. Open Livebook and type the password from the CREDENTIALS box in the app's logs.
2. Make a new notebook in /data and start writing code.

## Before you install

The password is made on first start and shown in the app's logs, in the box marked CREDENTIALS. Notebooks run code inside the container with access to /data, so only share it with people you trust. Charts and widgets load from a second port (6868); keep LIVEBOOK_IFRAME_PORT the same as that published port.
