---
site: https://nodered.org
source: https://github.com/node-red/node-red
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: NODE_RED_CREDENTIAL_SECRET
    group: Security
    default: ""
    description: >-
      A long random text that encrypts the passwords and tokens your
      flows save (flows_cred.json). Set it before you save any, and
      never change it afterwards.
  - name: NODE_RED_ENABLE_PROJECTS
    group: Editor
    default: "false"
    description: >-
      Set to true to turn on Projects (flows kept in Git).
  - name: NODE_RED_ENABLE_SAFE_MODE
    group: Editor
    default: "false"
    description: >-
      Set to true to start without running your flows, to fix one that
      crashes Node-RED.
  - name: FLOWS
    group: Editor
    default: "flows.json"
    description: >-
      The name of the flows file in the data folder.
  - name: NODE_OPTIONS
    group: Server
    default: ""
    description: >-
      Node.js options, like --max_old_space_size=512 to limit memory.
---

# Node-RED

Node-RED lets you build automations by dragging nodes onto a canvas and wiring them together. Connect smart-home devices, MQTT, web APIs, databases and messages, and react to events without writing a whole program.

## Features

- Browser-based flow editor with hundreds of built-in nodes
- Over 5,000 community nodes, installed from the Palette Manager
- MQTT, HTTP, WebSocket, TCP, UDP, files, timers and JavaScript functions
- Home Assistant, Zigbee2MQTT and many more through community nodes
- Dashboards and your own HTTP endpoints
- Projects with Git, and import or export flows as JSON

## How to use

1. Open Node-RED.
2. Drag nodes from the left onto the canvas, wire them and press Deploy.
3. Add more nodes with the menu, Manage palette.

## Before you install

Node-RED has no login at first: anyone on your network can change your flows, and flows can run commands inside the container. Add a login by editing adminAuth in /DATA/AppData/node-red/data/settings.js (see Securing Node-RED in the docs) and restart the app. Set NODE_RED_CREDENTIAL_SECRET before you save passwords in flows; without it Node-RED picks one itself and keeps it in the data folder.
