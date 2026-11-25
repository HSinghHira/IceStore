---
site: https://www.openhab.org
source: https://github.com/openhab/openhab-distro
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: EXTRA_JAVA_OPTS
    group: Java
    default: ""
    description: >-
      Java options, like -Xmx1g to limit memory, or
      -Dgnu.io.rxtx.SerialPorts=/dev/ttyUSB0 for a USB stick.
  - name: OPENHAB_HTTP_PORT
    group: Server
    default: "8080"
    description: >-
      The port inside the container. Change the published port instead.
---

# openHAB

openHAB connects smart-home devices from hundreds of brands and protocols and lets you automate them with rules, from one place that runs at home. Set it up in the web app, or with text files if you prefer.

## Features

- Over 400 add-ons for Zigbee, Z-Wave, Matter, Hue, Sonos, KNX, MQTT and more
- Rules with a visual editor, Blockly, JavaScript and more
- Main UI with pages, charts and a phone app for Android and iOS
- Persistence and history graphs
- Voice, notifications and the myopenHAB cloud for remote access

## How to use

1. Open openHAB right away and make the admin account.
2. Pick your region and add-ons in the setup wizard.
3. Add things from the Inbox and build your pages.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6855 and make the admin account; until you do, anyone on your network can. The first start takes a few minutes. This app uses bridge networking, so devices that are found by broadcast (UPnP, mDNS) may not appear in the Inbox; add them by IP. USB sticks need the device added to the app (like /dev/ttyUSB0) and EXTRA_JAVA_OPTS.
