---
site: https://www.stirling.com
source: https://github.com/Stirling-Tools/Stirling-PDF
screenshots: [Tools, Light theme]
variables:
  - name: SYSTEM_DEFAULTLOCALE
    group: Server
    default: ""
    description: >-
      The language for new users, like en-GB, de-DE or fr-FR. Leave it out to follow each browser.
  - name: SYSTEM_FRONTENDURL
    group: Server
    default: ""
    description: >-
      The address people open Stirling-PDF at, like http://192.168.1.20:6736. Needed for share links and the phone QR code upload.
  - name: UI_APPNAMENAVBAR
    group: Server
    default: ""
    description: >-
      The name shown in the browser tab. Leave it out for Stirling PDF.
  - name: SECURITY_INITIALLOGIN_USERNAME
    group: Login
    default: ""
    description: >-
      With login on, the first admin's name instead of admin. Only used on the very first start.
  - name: SECURITY_INITIALLOGIN_PASSWORD
    group: Login
    default: ""
    description: >-
      With login on, the first admin's password instead of stirling. Only used on the very first start.
  - name: SYSTEM_ENABLEANALYTICS
    group: Features
    default: ""
    description: >-
      Set to false to turn off sending usage statistics to Stirling. Left out, the admin is asked on first launch.
  - name: SYSTEM_GOOGLEVISIBILITY
    group: Features
    default: "false"
    description: >-
      Set to true to let search engines list your Stirling-PDF.
  - name: JAVA_CUSTOM_OPTS
    group: Server
    default: ""
    description: >-
      Extra Java options, like -Xmx2g to give it at most 2 GB of memory.
---

# Stirling-PDF

Stirling-PDF is a PDF toolbox you run yourself. Merge, split, rotate, compress, convert, sign, redact and OCR your PDFs in the browser, and the files never leave your server.

## Features

- Over 50 tools: merge, split, reorder, rotate, compress, watermark
- Convert to and from PDF: Office files, images, HTML, Markdown
- OCR for scanned pages, in many languages
- Sign, add passwords, redact and change permissions
- Edit text in a PDF and compare two files
- Chain tools into pipelines, and a REST API for scripts
- Optional login with users, teams and OIDC

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6736` in your browser.
2. Press Add Files and pick your PDFs.
3. Pick a tool on the right, then download the result.

## Before you install

There is no login by default; keep port 6736 on your home network. To need a login, set `SECURITY_ENABLELOGIN` to `true`: the first login is `admin` with the password `stirling`, and you must pick a new password straight away. The first start takes a minute or two, and the app likes 1 to 2 GB of memory for big files and Office conversions. The language, upload limit and other settings are in the Variables tab; add them in the app settings.
