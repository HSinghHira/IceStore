---
site: https://gotenberg.dev
source: https://github.com/gotenberg/gotenberg
services:
  - { name: Health, path: /health, icon: check }
variables:
  - name: API_TIMEOUT
    group: API
    default: "30s"
    description: >-
      How long one conversion may take
  - name: API_ENABLE_BASIC_AUTH
    group: API
    default: "false"
    description: >-
      Set to true to require a user name and password
      (GOTENBERG_API_BASIC_AUTH_USERNAME and
      GOTENBERG_API_BASIC_AUTH_PASSWORD).
  - name: GOTENBERG_API_BASIC_AUTH_USERNAME
    group: API
    default: ""
    description: >-
      The user name when basic auth is on.
  - name: GOTENBERG_API_BASIC_AUTH_PASSWORD
    group: API
    default: ""
    description: >-
      The password when basic auth is on.
  - name: CHROMIUM_MAX_QUEUE_SIZE
    group: Chromium
    default: "0"
    description: >-
      How many web page conversions may wait at once (0 means no limit).
  - name: LIBREOFFICE_RESTART_AFTER
    group: LibreOffice
    default: "10"
    description: >-
      Restart LibreOffice after this many conversions to keep memory
      low.
  - name: LOG_LEVEL
    group: Logging
    default: "info"
    description: >-
      How much is logged: error, warn, info or debug.
---

# Gotenberg

Gotenberg is a document conversion service for your other apps and scripts. Send it a web page, HTML, Markdown or an Office file over HTTP and get a PDF back. Paperless-ngx, Docmost and many other apps can use it.

## Features

- Web pages and HTML to PDF with Chromium, including headers and footers
- Word, Excel, PowerPoint and over 100 other formats to PDF with LibreOffice
- Merge and split PDFs, and convert them to PDF/A or PDF/UA
- Screenshots of web pages as PNG, JPEG or WebP
- Webhooks for long conversions and a health endpoint

## How to use

1. Point your app at http://[ZIMAOS-IP-ADDRESS]:6820 with your ZimaOS IP (for example Paperless-ngx's PAPERLESS_TIKA_GOTENBERG_ENDPOINT).
2. Or send a file yourself: curl -F files=@report.docx http://[ZIMAOS-IP-ADDRESS]:6820/forms/libreoffice/convert -o report.pdf

## Before you install

Gotenberg is a service for other apps and has no web page of its own; open http://[ZIMAOS-IP-ADDRESS]:6820/health to see that it runs. It has no password by default, so keep it on your home network, or turn on basic auth in the Variables tab. Gotenberg's settings are command-line flags; the variables listed here are the ones it also reads from the environment.
