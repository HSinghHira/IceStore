---
site: https://www.traccar.org
source: https://github.com/traccar/traccar
screenshots: [Live map]
variables:
  - name: WEB_URL
    group: Server
    default: ""
    description: >-
      The address people open Traccar at, like http://192.168.1.20:6742. Used for links in emails.
  - name: GEOCODER_ENABLE
    group: Server
    default: "true"
    description: >-
      Set to false to stop turning positions into street addresses.
  - name: MAIL_SMTP_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for email alerts and password resets.
  - name: MAIL_SMTP_PORT
    group: Email (SMTP)
    default: "25"
    description: >-
      The mail server's port.
  - name: MAIL_SMTP_STARTTLS_ENABLE
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to use STARTTLS.
  - name: MAIL_SMTP_SSL_ENABLE
    group: Email (SMTP)
    default: "false"
    description: >-
      Set to true to use SSL/TLS from the start (usually port 465).
  - name: MAIL_SMTP_USERNAME
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server user name.
  - name: MAIL_SMTP_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server password.
  - name: MAIL_SMTP_FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender address, like traccar@example.com.
---

# Traccar

Traccar is your own GPS tracking server. See where your phones, cars, bikes and pets are on a live map, look back at past trips, and get alerts when a device enters an area, speeds or goes offline.

## Features

- Live map of all your devices, and trip history
- Works with the free Traccar Client phone app and over 200 GPS tracker types
- Geofences, with alerts when a device enters or leaves
- Reports: trips, stops, summaries and charts
- Alerts by email, the web page or push
- Users and groups, with who can see what

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6742` and register. The first account is the admin.
2. Install Traccar Client on your phone. Set its server to `http://[ZIMAOS-IP-ADDRESS]:6743` and note its device ID.
3. In Traccar, add a device with that ID. It shows up on the map.

## Before you install

Nothing needs to be set first. Register right after installing: the first account becomes the admin. Phones with Traccar Client send to port 6743, GT06 trackers to 6744 and Teltonika trackers to 6745. Other tracker types use other ports (see Traccar's device list); add them to the app's ports in ZimaOS. To track devices away from home, forward the tracker port on your router or use a VPN. Email alerts and the other settings are in the Variables tab; add them in the app settings.
