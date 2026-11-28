---
site: https://www.kavitareader.com
source: https://github.com/Kareadita/Kavita
screenshots: [Home]
services:
  - { name: Reader, path: /, icon: globe }
---

# Kavita

Kavita is a fast reading server for your manga, comics, webtoons and ebooks. Read in any browser with a reader made for each format, and keep your place across devices.

## Features

- Readers for manga, comics and webtoons (CBZ, CBR, CB7, images), EPUB and PDF
- Series grouped by folder, with covers and details from your files
- Reading lists, collections, want-to-read and progress per user
- Users with their own libraries, age ratings and rights
- OPDS feeds for reader apps, and send-to-device by email

## How to use

1. Open Kavita right away and make the admin account.
2. Add a library and pick a folder under `/DATA`, like `/DATA/Media/Comics`.
3. Kavita scans it; start reading.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6812` and make the admin account; until you do, anyone on your network can. Kavita expects one folder per series (`/DATA/Media/Comics/Series Name/...`); see the [scanner guide](https://wiki.kavitareader.com/guides/scanner/). Settings such as the base URL and cache size are in the app's **Server Settings**, stored in `/DATA/AppData/kavita/config/appsettings.json`. Email (send-to-device, password reset) is set up in **Server Settings → Email** with your own SMTP server.
