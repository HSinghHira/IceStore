---
name: ZimaBrain CE
source: https://github.com/Jacko88888/zimabrain-ce
services:
  - { name: Web UI, path: /, icon: monitor }
screenshots: [Dashboard, Diagnostics, Report]
variables:
  - name: ZIMABRAIN_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      A fixed login password. Leave it out to pick one on the first screen
      instead (it is kept as a hash in the app folder).
  - name: ZIMABRAIN_SECRET_KEY
    group: Sign-in
    default: ""
    description: >-
      The key that signs logins. Leave it out: one is made on first start
      and kept in the app folder. Changing it signs everyone out.
  - name: ZIMABRAIN_MONITOR_ENABLED
    group: Monitor
    default: "true"
    description: >-
      Set to false to stop the background samples (CPU, memory, disks,
      containers) used for the incident history.
  - name: ZIMABRAIN_MONITOR_INTERVAL_SECONDS
    group: Monitor
    default: "60"
    description: >-
      How often the background monitor takes a sample, in seconds.
  - name: ZIMABRAIN_MONITOR_RETENTION_DAYS
    group: Monitor
    default: "7"
    description: >-
      How many days of monitor samples to keep.
---

# ZimaBrain CE

ZimaBrain CE is a local diagnostic assistant that reads real evidence from your ZimaOS box (disks, containers, mounts and network) before it tells you what is wrong or what to run next. It runs on your box and needs no cloud account.

## Features

- Verifier-first: checks real system evidence before it answers, instead of guessing
- Layered checks for Docker, containers, bind mounts, disk health, filesystem usage, network exposure, SMB shares and permissions
- Knows the official ZimaOS manuals, verified app install guides and a third-party app store index
- Suggests safe commands, and avoids risky fixes unless the evidence clearly supports them
- Keeps reports, trend history and restart incident history in the app folder

## How to use

1. Open ZimaBrain CE from your dashboard.
2. Pick a password on the first screen. You log in with it from then on.
3. Check the top badge and layer map to see that it started well.
4. Ask a question about your system, or pick a layer (disks, containers, network...) to check.
5. Read the evidence and the suggested safe commands before you run anything yourself.

## Before you install

ZimaBrain CE needs deep access to your box: it runs as a privileged container, sees the host's processes, and has read-only access to Docker, `/proc`, `/sys` and the host name. Only install it on a box you trust and keep it on your home network. There is nothing to set first: you pick a login password on the first screen, and the session key is made on first start. The first start takes about 30 seconds. Monitor settings and a fixed password are in the Variables tab; add them in the app settings. It runs on amd64 (Intel and AMD) only.
