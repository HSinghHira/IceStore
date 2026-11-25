---
site: https://typesense.org
source: https://github.com/typesense/typesense
services:
  - { name: Health, path: /health, icon: check }
variables:
  - name: TYPESENSE_API_KEY
    group: Security
    default: ""
    description: >-
      The admin API key. Made on first start and kept in the data folder
      when left out.
  - name: TYPESENSE_ENABLE_CORS
    group: Network
    default: "true"
    description: >-
      Set to false to refuse searches from browsers on other sites.
  - name: TYPESENSE_LOG_DIR
    group: Logging
    default: ""
    description: >-
      A folder to write logs to instead of the app's log.
  - name: TYPESENSE_THREAD_POOL_SIZE
    group: Performance
    default: ""
    description: >-
      How many threads handle requests.
---

# Typesense

Typesense is a search engine for your own apps and websites. Send it JSON documents and get instant, typo-tolerant results with filters, facets and geo search, plus vector and hybrid search for AI apps.

## Features

- Search-as-you-type with typo tolerance and synonyms
- Filters, facets, sorting, grouping and geo search
- Vector, semantic and hybrid search, with built-in embedding models
- Scoped API keys for safe searching from browsers
- Client libraries for JavaScript, Python, PHP, Ruby, Go and more

## How to use

1. Copy the admin API key from the CREDENTIALS box in the app's logs.
2. Point your app or client library at http://[ZIMAOS-IP-ADDRESS]:6866 with that key.

## Before you install

Typesense is a server for other apps and has no web page; open http://[ZIMAOS-IP-ADDRESS]:6866/health to see that it runs. The admin API key is made on first start and shown in the app's logs, in the box marked CREDENTIALS; it can do everything, so give browsers a search-only key made with it. Collections live in memory and on disk, so give the app enough memory for your data.
