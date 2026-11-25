---
site: https://chartdb.io
source: https://github.com/chartdb/chartdb
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: OPENAI_API_KEY
    group: AI
    default: ""
    description: >-
      Your OpenAI key, for exporting a schema to another database with
      AI.
  - name: OPENAI_API_ENDPOINT
    group: AI
    default: ""
    description: >-
      An OpenAI-compatible address instead, like your Ollama at
      http://192.168.1.20:11434/v1.
  - name: LLM_MODEL_NAME
    group: AI
    default: ""
    description: >-
      The model to use with that address.
  - name: DISABLE_ANALYTICS
    group: Server
    default: "false"
    description: >-
      Set to true to turn off usage statistics.
---

# ChartDB

ChartDB draws diagrams of your databases. Run one query it gives you in your database, paste the result, and get an editable diagram of every table and relation. Edit it, export SQL for another database, or share an image.

## Features

- Imports PostgreSQL, MySQL, MariaDB, SQL Server, SQLite, ClickHouse and CockroachDB schemas
- Editable tables, fields, relations and areas
- Export to SQL for another database, PNG, SVG and JSON
- Optional AI export with your own OpenAI key
- Diagrams are kept in your browser

## How to use

1. Open ChartDB and pick your database type.
2. Run the query it shows in your database and paste the result.
3. Edit the diagram, then export SQL or an image.

## Before you install

ChartDB has no login and keeps your diagrams in your browser's storage, so they are not shared between devices; export them to keep a copy. The AI export needs your own OpenAI key or an OpenAI-compatible server (Variables tab).
