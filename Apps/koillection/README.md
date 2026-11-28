---
site: https://koillection.github.io
source: https://github.com/benjaminjonard/koillection
screenshots: [Collection, Item page, Signs, Wishlist]
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API, path: /api, icon: code }
variables:
  - name: PHP_MEMORY_LIMIT
    group: PHP
    default: "512M"
    description: >-
      Memory each request may use. Raise it for very large imports.
  - name: UPLOAD_MAX_FILESIZE
    group: PHP
    default: "20M"
    description: >-
      Largest picture or file you can upload.
  - name: CORS_ALLOW_ORIGIN
    group: API
    default: ""
    description: >-
      Other web pages allowed to call the API, as a regular expression. Blank allows localhost only.
  - name: FRANKENPHP_WORKERS_NUMBER
    group: Advanced
    default: "1"
    description: >-
      PHP workers. More handles more people at once and uses more memory.
  - name: FRANKENPHP_THREADS_NUMBER
    group: Advanced
    default: "2"
    description: >-
      PHP threads.
  - name: APP_DEBUG
    group: Advanced
    default: "0"
    description: >-
      1 shows detailed error pages. Leave 0.
---

# Koillection

Koillection is a collection manager for anything you collect: books, video games, vinyl, figures, coins, stamps, cards. Each collection can have its own fields, pictures and wishlists.

## Features

- Collections and sub-collections with pictures
- Your own fields: text, numbers, dates, ratings, prices, links
- Wishlists and loans (who has what)
- Tags, templates, search and statistics
- Share collections publicly or keep them private
- Fill items from a web page with scrapers, and a full API

## How to use

1. Open Koillection and create your account. The first account becomes the admin.
2. Make a collection, like Books, and add your first items.
3. Use templates to give every item in a collection the same fields.

## Before you install

Upstream needs a separate PostgreSQL or MySQL server; this IceStore image has PostgreSQL 18 inside, so it is one app with two folders: data (database, secrets, API keys) and uploads (your pictures). Back up both. The first start takes a minute or two. Koillection has no default login: open http://[ZIMAOS-IP-ADDRESS]:7001 right after installing and create your account, which becomes the admin. Upstream makes a new app secret and JWT passphrase on every start, which signs everyone out and breaks API keys; this image keeps them in the data folder. Leave HTTPS_ENABLED at 0 unless Koillection sits behind a reverse proxy with https.
