---
site: https://beszel.dev
source: https://github.com/henrygd/beszel
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: APP_URL
    group: Server
    default: ""
    description: >-
      The address you open Beszel at, like http://192.168.1.20:6825,
      used in alert links and OAuth.
  - name: USER_CREATION
    group: Sign-in
    default: "false"
    description: >-
      Set to true to make an account for new OAuth users on their first
      sign-in.
  - name: DISABLE_PASSWORD_AUTH
    group: Sign-in
    default: "false"
    description: >-
      Set to true to only allow OAuth sign-in.
  - name: SHARE_ALL_SYSTEMS
    group: Users
    default: "false"
    description: >-
      Set to true to show every system to every user.
  - name: CSP
    group: Server
    default: ""
    description: >-
      Your own Content-Security-Policy header.
---

# Beszel

Beszel shows the CPU, memory, disk, network, temperature and container use of your servers on one dashboard, with history and alerts. This app is the hub; each machine you watch runs a tiny agent that the hub connects to.

## Features

- Live and historical charts for CPU, memory, disks, network and temperatures
- Docker and Podman container stats per machine
- Alerts by email, ntfy, Telegram, Discord and more
- Several users, each seeing their own systems, and OAuth sign-in
- Automatic backups to disk or S3

## How to use

1. Open Beszel right away and make the admin account.
2. Press Add System and copy the agent command it shows.
3. Run the agent on the machine to watch; it shows up in a few seconds.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6825 and make the admin account; until you do, anyone on your network can. This is the hub only: each machine you want to watch, this ZimaOS included, needs the Beszel agent, which the hub's Add System window gives you as a Docker command. The agent for this ZimaOS needs host networking and, for container stats, the Docker socket.
