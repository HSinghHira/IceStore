---
site: https://degoog-org.github.io/docs/
services:
  - { name: Search, path: /, icon: search }
  - { name: Settings, path: /settings, icon: server }
screenshots: [Home, Extension store, Plugins]
variables:
  - name: DEGOOG_PUBLIC_INSTANCE
    group: Security
    default: ""
    description: >-
      Set to true if strangers on the internet will use your instance. It
      trims the Settings page and locks every change behind the password.
  - name: DEGOOG_SETTINGS_PATH
    group: Security
    default: "settings"
    description: >-
      The address of the Settings page, like /settings. Change it to hide the
      page somewhere less obvious. Public instances use admin.
  - name: DEGOOG_DANGEROUSLY_NO_PASSWORD
    group: Security
    default: "false"
    description: >-
      Set to true to turn off the Settings password completely. Only do this
      if nobody else can reach deGoog, because extensions run code on the
      server.
  - name: DEGOOG_OUTGOING_ALLOWED_HOSTS
    group: Security
    default: ""
    description: >-
      Comma-separated list of hostnames deGoog may contact. Leave it out to
      allow any.
  - name: DEGOOG_ANUBIS_MAX_DIFFICULTY
    group: Security
    default: "4"
    description: >-
      Highest Anubis proof-of-work level deGoog will solve when a site asks
      for it (up to 6).
  - name: DEGOOG_BASE_URL
    group: Server
    default: ""
    description: >-
      The public address of deGoog, like https://search.example.com, or a
      sub-path. Set it when you put deGoog behind your own domain.
  - name: DEGOOG_DISTRUST_PROXY
    group: Server
    default: "1"
    description: >-
      Set to 0 when deGoog is behind a reverse proxy, so it trusts the
      visitor IP and https headers the proxy sends.
  - name: DEGOOG_BODY_SIZE
    group: Server
    default: "3072"
    description: >-
      Largest request body in KB that public pages accept. 0 removes the
      limit.
  - name: DEGOOG_WIZARD
    group: Server
    default: ""
    description: >-
      Set to false to skip the first-run setup wizard.
  - name: DEGOOG_DEFAULT_SEARCH_LANGUAGE
    group: Search and language
    default: ""
    description: >-
      Search language to use when a visitor has not picked one, like en.
  - name: DEGOOG_I18N
    group: Search and language
    default: ""
    description: >-
      Force the page language for everyone, like en or de. Leave it out to
      follow each browser's language.
  - name: DEGOOG_AUTOCOMPLETE_TIMEOUT_MS
    group: Search and language
    default: "8000"
    description: >-
      How long, in milliseconds, an autocomplete provider has to answer.
  - name: DEGOOG_SLOT_TIMEOUT_MS
    group: Search and language
    default: "10000"
    description: >-
      How long, in milliseconds, a panel plugin has to answer before it is
      skipped.
  - name: DEGOOG_BETA_STORE
    group: Extensions
    default: ""
    description: >-
      Set to 1 to install extensions from the develop branch of store
      repositories instead of the stable one.
  - name: DEGOOG_CACHE_TTL_MS
    group: Cache
    default: "43200000"
    description: >-
      How long, in milliseconds, search and autocomplete results are kept.
      The default is 12 hours.
  - name: DEGOOG_CACHE_SHORT_TTL_MS
    group: Cache
    default: "120000"
    description: >-
      How long, in milliseconds, results are kept when some engines failed.
      The default is 2 minutes.
  - name: DEGOOG_CACHE_MAX_ENTRIES
    group: Cache
    default: "1000"
    description: >-
      Most entries kept in each in-memory cache.
  - name: DEGOOG_VALKEY_URL
    group: Cache
    default: ""
    description: >-
      Address of your own Valkey or Redis server for a shared cache, like
      redis://192.168.1.50:6379. Leave it out to use the built-in memory
      cache.
  - name: DEGOOG_POSTGRES
    group: Database
    default: ""
    description: >-
      Address of your own Postgres database for the search index, like
      postgres://degoog:password@192.168.1.50:5432/degoog. Leave it out to use
      the built-in SQLite file.
  - name: DEGOOG_POSTGRES_SSLMODE
    group: Database
    default: ""
    description: >-
      SSL mode for Postgres, like require or disable. By default it is
      require for network hosts with a password.
  - name: LOG_LEVEL
    group: Logs
    default: "info"
    description: >-
      How much deGoog writes to the log: fatal, error, warn, info, log or
      debug.
  - name: NO_COLOR
    group: Logs
    default: ""
    description: >-
      Set to any value to remove colours from the log.
---

# deGoog

deGoog asks many search engines at once and merges their results into one ranked list. It is a lighter, more modular alternative to SearXNG that you can extend with your own engines, plugins and themes.

## Features

- Results from every search engine you turn on, with duplicates removed and scores combined
- Plugins: custom search engines, bang commands, panels above, below or beside the results, and custom transports (curl, FlareSolverr or your own)
- Built-in store to install engines, plugins and themes without editing files
- Everything kept in the app data folder

## How to use

1. Open deGoog from your dashboard.
2. Follow the first-run setup wizard.
3. Open Settings (the gear icon) and sign in with your settings password.
4. Turn on the search engines you want and browse the Store for more engines, plugins and themes.

## Before you install

You can type a password in `DEGOOG_SETTINGS_PASSWORDS`; it opens the Settings page. If you leave it empty, deGoog makes a new password every time it starts and prints it in the app log under "Sign in to settings with:". Always set a password before letting other people reach deGoog, because extensions installed from Settings run code on the server. More settings, like public mode, a Valkey cache or a Postgres index, are in the Variables tab and are added in the app settings. deGoog starts in a few seconds.
