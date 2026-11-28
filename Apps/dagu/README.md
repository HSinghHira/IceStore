---
site: https://dagu.cloud
source: https://github.com/dagucloud/dagu
screenshots: [Workflow editor, Overview, Start workflow]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: DAGU_AUTH_MODE
    group: Sign-in
    default: "builtin"
    description: >-
      builtin (accounts), basic (one user name and password) or none.
  - name: DAGU_AUTH_BASIC_USERNAME
    group: Sign-in
    default: ""
    description: >-
      The user name for basic sign-in.
  - name: DAGU_AUTH_BASIC_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The password for basic sign-in.
  - name: DAGU_AUTH_TOKEN_TTL
    group: Sign-in
    default: "24h"
    description: >-
      How long a sign-in lasts.
  - name: DAGU_BASE_PATH
    group: Server
    default: ""
    description: >-
      Serve Dagu under a sub-path, like /dagu.
  - name: DAGU_LOG_LEVEL
    group: Logging
    default: "info"
    description: >-
      How much is logged: debug, info, warn or error.
---

# Dagu

Dagu runs your scripts and jobs as workflows written in small YAML files, with schedules, dependencies, retries and a web page to watch, start and debug every run. It is a lightweight alternative to cron and Airflow.

## Features

- Workflows (DAGs) in YAML with steps, dependencies and conditions
- Cron schedules, retries, timeouts and parallel steps
- Web page to edit, start, stop and follow runs with live logs
- Shell, HTTP, SSH, mail and JSON steps, and sub-workflows
- Users and roles, API and a built-in MCP server

## How to use

1. Open Dagu right away and make the admin account.
2. Press New DAG, write the steps and a schedule, and save.
3. Start it and follow the log.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6853 and make the admin account; until you do, anyone on your network can. Workflows are YAML files in /DATA/AppData/dagu/data/dags and run inside the Dagu container as your ZimaOS user (PUID/PGID). Docker steps would need the Docker socket, which this app does not mount.
