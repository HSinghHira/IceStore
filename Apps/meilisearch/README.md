---
site: https://www.meilisearch.com
source: https://github.com/meilisearch/meilisearch
services:
  - { name: Search preview, path: /, icon: search }
variables:
  - name: MEILI_MASTER_KEY
    group: Security
    default: ""
    description: >-
      The master key, at least 16 characters. Made on first start and kept
      in .icestore-master-key in the data folder when left out. Changing it
      makes new API keys; apps using the old ones stop working.
  - name: MEILI_LOG_LEVEL
    group: Server
    default: INFO
    description: >-
      How much is logged: OFF, ERROR, WARN, INFO, DEBUG or TRACE.
  - name: MEILI_HTTP_PAYLOAD_SIZE_LIMIT
    group: Server
    default: 100MB
    description: >-
      The largest request Meilisearch accepts, like 500MB for big imports.
  - name: MEILI_MAX_INDEXING_MEMORY
    group: Indexing
    default: ""
    description: >-
      The most memory indexing may use, like 1GiB. Keep it below the app's
      memory limit (2G).
  - name: MEILI_MAX_INDEXING_THREADS
    group: Indexing
    default: ""
    description: >-
      How many CPU threads indexing may use. Left out, half of them.
  - name: MEILI_SCHEDULE_SNAPSHOT
    group: Backups
    default: ""
    description: >-
      Make a snapshot every this many seconds, like 86400 for once a day.
      Snapshots go to /meili_data/snapshots.
  - name: MEILI_TASK_WEBHOOK_URL
    group: Server
    default: ""
    description: >-
      An address that is called when a task (like an import) finishes.
  - name: MEILI_EXPERIMENTAL_ALLOWED_IP_NETWORKS
    group: Server
    default: ""
    description: >-
      Networks the embedders and webhooks may call, comma separated, like
      192.168.0.0/16 for a local AI model.
---

# Meilisearch

Meilisearch is a search engine for your own apps and websites. Send it your documents as JSON and get fast, typo-tolerant results as you type. Many self-hosted apps (like Karakeep and Linkwarden) can use it for search.

## Features

- Search-as-you-type results in under 50 ms
- Typo tolerance, synonyms, stop words and ranking rules
- Filters, facets, sorting and geo search
- Hybrid and semantic search with your own AI embedder
- API keys with their own rights and expiry

## How to use

1. Open Meilisearch and paste the master key from the CREDENTIALS box in the app's logs to try the search preview.
2. List the API keys: `curl -H "Authorization: Bearer <master key>" http://[ZIMAOS-IP-ADDRESS]:6810/keys`.
3. Point your app at `http://[ZIMAOS-IP-ADDRESS]:6810` with the **Default Search API Key** (searching) or **Default Admin API Key** (adding documents).

## Before you install

The master key is made on first start and shown in the app's logs, in the box marked CREDENTIALS; it is kept in `/DATA/AppData/meilisearch/data/.icestore-master-key`. It can do everything, so give apps one of the API keys instead. To pick your own key (at least 16 characters), add `MEILI_MASTER_KEY` in the app settings. `MEILI_ENV=development` keeps the search preview page; set it to `production` to hide it. New versions upgrade the database in place (`MEILI_UPGRADE_DB`); still, set `MEILI_SCHEDULE_SNAPSHOT` or make a dump before big upgrades if the data matters.
