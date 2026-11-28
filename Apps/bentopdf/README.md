---
site: https://www.bentopdf.com
source: https://github.com/alam00000/bentopdf
screenshots: [Home]
services:
  - { name: PDF tools, path: /, icon: globe }
---

# BentoPDF

BentoPDF is a set of over 50 PDF tools: merge, split, compress, sign, edit, convert and more. Everything runs in your browser, so your files never leave your device, not even to your ZimaOS.

## Features

- Merge, split, rotate, reorder and delete pages
- Compress, protect, unlock and add watermarks
- Fill forms, sign, annotate and edit text
- Convert images, Markdown and text to PDF, and PDF to images
- OCR to make scanned PDFs searchable
- No account, no uploads, no limits

## How to use

1. Open BentoPDF and pick a tool.
2. Drop your PDF on the page, choose the options and download the result.

## Before you install

BentoPDF keeps nothing on your ZimaOS and has no login: the server only hands the page to your browser, which does all the work. Converting Word, Excel and PowerPoint files uses LibreOffice in the browser, which browsers only allow on an https page: put BentoPDF behind a reverse proxy with your own domain for those. Every other tool works over plain http. Branding, simple mode and hidden tools are set when upstream builds the image, so they can't be changed in the app settings.
