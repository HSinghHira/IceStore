---
site: https://www.domoticz.com
source: https://github.com/domoticz/domoticz
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: EXTRA_CMD_ARG
    group: Server
    default: ""
    description: >-
      Extra Domoticz start options, like -loglevel normal,status,error.
  - name: WWW_PORT
    group: Server
    default: "8080"
    description: >-
      The port inside the container. Change the published port instead.
---

# Domoticz

Domoticz controls and monitors your home: lights, switches, sensors, weather stations, smart meters and more. It supports many protocols and devices, shows history graphs and runs your automations with scenes, timers and scripts.

## Features

- Z-Wave, Zigbee, RFXtrx, MQTT, Philips Hue, Tasmota, ESPHome and hundreds more devices
- Energy, gas, water and temperature history
- Scenes, timers and events with Blockly, Lua, dzVents and Python
- Notifications by email, Telegram, Pushover and more
- Phone apps and a simple web page

## How to use

1. Open Domoticz and go to Setup, Settings to set your location and a login.
2. Add your hardware in Setup, Hardware.
3. Your devices appear under Devices; add them to your dashboard.

## Before you install

Domoticz has no login at first: set a website user and password in Setup, Settings, System right away. Network devices (MQTT, Hue, Tasmota, ESPHome) work as they are. USB sticks for Z-Wave, Zigbee or RFXtrx must be added to the app as a device, like /dev/ttyUSB0, in the ZimaOS app settings.
