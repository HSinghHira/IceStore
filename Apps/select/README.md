---
name: Select
source: https://github.com/Kirby54/Select
services:
  - { name: Web App, path: /, icon: globe }
screenshots: [Overview, Approvals, Agents]
variables:
  - name: SELECT_AUTH_MODE
    group: Sign-in
    default: password
    description: >-
      password: people sign in with an email and password (the first visit
      makes the owner). token: every request needs an API token, for
      scripts. Never use local on a network.
  - name: SELECT_SESSION_DAYS
    group: Sign-in
    default: "30"
    description: >-
      How many days a sign-in lasts (1 to 365).
  - name: SELECT_SECRET_KEY
    group: Keys
    default: ""
    description: >-
      The key that encrypts provider API keys and mailbox passwords (a Fernet
      key). Made on first start and kept in select/secret.key in the data
      folder when left out.
  - name: SELECT_DEMO_STEP_DELAY_MS
    group: Demo
    default: "350"
    description: >-
      The pause between events of the demo week, in milliseconds.
---

# Select

Select runs your company's work with AI agents that earn their autonomy. Agents of any kind work in an organization you design; every result is checked by code against a delivery contract, and an agent stops needing your approval only once its checked record shows it can. Built here from upstream's source, with PostgreSQL inside.

## Features

- Agents with roles, models (Anthropic, OpenAI, Gemini, Ollama), budgets and an org chart
- Tasks from you, from incoming email or from routines; list and board
- Every result checked by code and kept with a receipt
- Autonomy per agent and task type, earned and revocable; payments, contracts, taxes and hiring always need a person
- Approvals, costs and budgets, an audit log, and a demo company with no API key needed

## How to use

1. Open Select from your dashboard.
2. Create the owner account on the first visit.
3. To look around first, open the demo company from the account menu and choose **Run demo week**.
4. Follow the guided setup: country, a starting team, an AI model, a mailbox.

## Before you install

Set `PUBLIC_URL` to the address you open Select at, like `http://192.168.1.20:6702`; it is used in invitation links, and Select opens from any address either way. Open `http://[ZIMAOS-IP-ADDRESS]:6702` after about a minute and create the owner account. AI model keys and mailboxes are added inside Select, where they are stored encrypted with the key in the data folder. Upstream calls this a 1.0.0 core release: sandboxed coding and OAuth mail are not there yet.
