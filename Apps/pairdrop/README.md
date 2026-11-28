---
source: https://github.com/schlagmichdoch/PairDrop
screenshots: [Pair devices, Transfer request, Pair permanently]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: RATE_LIMIT
    group: Server
    default: "false"
    description: >-
      Set to true to allow each device 100 requests every 5 minutes, when
      PairDrop is open to the internet.
  - name: RTC_CONFIG
    group: Connections
    default: ""
    description: >-
      A JSON file with your own STUN/TURN servers, for devices on different
      networks. Add the file as a volume and give its path here.
  - name: DEBUG_MODE
    group: Server
    default: "false"
    description: >-
      Set to true to log the IP addresses PairDrop sees, to fix device
      discovery. Not for everyday use.
---

# PairDrop

PairDrop sends files and messages between phones, tablets and computers on your home network, straight from the browser. Open the page on two devices, and they see each other. No app, no account and no upload to the cloud.

## Features

- Devices on your network find each other by themselves
- Files go straight from device to device (WebRTC)
- Send text messages and links too
- Pair devices with a code to send between networks
- Public rooms with a short code for one-off sharing

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6814` on two devices on your network.
2. Tap the other device's icon and pick files, or right-click (long-press on phones) to send text.

## Before you install

PairDrop keeps nothing on your ZimaOS: files go from device to device, or through the server only when `WS_FALLBACK` is on and a direct connection fails. Over plain http, sending files and text works; the copy button, notifications, remembering paired devices and installing it as an app need https, through a reverse proxy with your own domain. Devices on other networks need a TURN server (`RTC_CONFIG`). This image is built by [linuxserver.io](https://docs.linuxserver.io/images/docker-pairdrop/).
