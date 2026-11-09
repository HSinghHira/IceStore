---
name: Root Cellar
source: https://github.com/Noobie3DPrinting/root-cellar
services:
  - { name: Checkbook, path: /, icon: table }
  - { name: Notes, path: /, icon: file-code, port: 6712 }
  - { name: Movies, path: /, icon: monitor, port: 6713 }
  - { name: Labels, path: /, icon: tag, port: 6714 }
screenshots: [All four apps, Checkbook, Notes, Movies, Labels]
---

# Root Cellar

Root Cellar is a set of household apps for your home server, all in one container: a shared checkbook with bills, private and shared notes, a movie collection tracker and a DYMO label maker. Each app has its own address and works offline on phones and computers.

## Features

- Checkbook: a shared register with balances, reconciling and bills (payment plans, autopay, "safe to spend")
- Notes: private notes for each person plus a shared notebook, with search, tags and history
- Movies: your Blu-ray and DVD collection and wishlist; scan a barcode with your phone
- Labels: design labels in any browser and print to a DYMO LabelWriter, or download a PDF

## How to use

1. Checkbook opens from your dashboard (port 6711).
2. Notes is on port 6712, Movies on 6713 and Labels on 6714.
3. On phones, open each address and add it to the Home Screen.

## Before you install

Nothing to set first. The four apps are at `http://[ZIMAOS-IP-ADDRESS]:6711` (Checkbook), `:6712` (Notes), `:6713` (Movies) and `:6714` (Labels); the app's logs list them in the box marked CREDENTIALS. Root Cellar is made for your home network: to use it away from home, use a VPN like Tailscale rather than opening the ports.

To print labels, plug a DYMO LabelWriter into the box and give the app access to it: in the app settings, add the volume `/dev/bus/usb` (same path inside) and turn on privileged mode. Download PDF works without a printer. The print setup is kept in `labels/cups` in the data folder.
