---
site: https://github.com/zerx-lab/FluxDown
services:
  - { name: Web App, path: /, icon: globe }
---

# FluxDown

A fast, self-hosted download manager powered by a Rust engine. It handles HTTP/HTTPS, FTP, BitTorrent, HLS and more, with resume and speed control.

## Features

- Multi-protocol downloads with smart segmentation and resume
- Web UI, REST API and aria2-compatible JSON-RPC
- Built-in MCP endpoint so AI agents can manage downloads
- Finished files land in the Downloads folder on ZimaOS

## How to use

1. Open FluxDown from your dashboard.
2. Follow the setup wizard and create your access key.
3. Add a link or magnet and start downloading.
4. Find finished files in the Downloads folder.

## Before you install

Nothing needs to be set first. On first open, the setup wizard asks you to make an access key with 8 or more letters and numbers. Save it, because you need it to log in. Finished files go to `/DATA/Downloads`.
