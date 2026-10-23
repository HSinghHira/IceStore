---
site: https://bookorbit.app
services:
  - { name: Library and readers, path: /, icon: globe }
variables:
  - name: CLIENT_URL
    group: Server
    default: ""
    description: >-
      Only if the web app is opened from a different address than
      PUBLIC_URL. Leave it out to use PUBLIC_URL.
  - name: LIBRARY_BROWSE_ROOT
    group: Server
    default: /books
    description: >-
      The top folder the library folder picker starts at. Set to / to see
      every folder in the container.
  - name: BOOK_DOCK_PATH
    group: Server
    default: ""
    description: >-
      A different folder for the Book Dock, where dropped files are added
      for you. Leave it out to use the one in the data folder.
  - name: PUID
    group: Files
    default: "1000"
    description: >-
      The user id BookOrbit writes files as. Change it if your books folder
      belongs to another user.
  - name: PGID
    group: Files
    default: "1000"
    description: >-
      The group id BookOrbit writes files as.
  - name: DISABLE_LOCAL_AUTH
    group: Sign-in
    default: "false"
    description: >-
      Set to true to turn off user name and password sign-in, once an admin
      has linked an OIDC account. Set back to false and restart if your
      sign-in provider is down.
  - name: OIDC_ALLOW_LOCAL_ISSUERS
    group: Sign-in
    default: "false"
    description: >-
      Set to true when your OIDC provider (like authentik) runs on your home
      network, at a local or private address.
  - name: NODE_MAX_OLD_SPACE_SIZE
    group: Performance
    default: auto
    description: >-
      Memory for the app in MB, or auto to size it from the container limit.
      Raise it for very large libraries (250,000+ books).
  - name: GITHUB_RELEASES_TOKEN
    group: Updates
    default: ""
    description: >-
      A GitHub token used to read BookOrbit release notes, so you don't hit
      GitHub's rate limit.
  - name: CSP_ALLOW_CLOUDFLARE_INSIGHTS
    group: Privacy
    default: "false"
    description: >-
      Set to true to allow the Cloudflare Web Analytics script, if you serve
      BookOrbit through Cloudflare with analytics on.
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much goes in the app log: debug, info, warn or error.
---

# BookOrbit

BookOrbit is a self-hosted digital library and reading platform for EPUB, MOBI, AZW3, PDF, CBZ/CBR comics and M4B/MP3 audiobooks - your own private library with sync built in. This is BookOrbit in a single container, with PostgreSQL and pgvector inside, one port and one data folder. Secret keys and the database password are made for you on first start.

## Features

- Built-in web readers for ebooks, PDFs, comics and audiobooks, with no extra plugins needed
- Three-way sync (Kobo + KOReader + BookOrbit) for reading progress and annotations
- Metadata lookup from Google Books, Amazon, Goodreads, Open Library, Audible, ComicVine and more
- Many users, with sign-in through OIDC/SSO (authentik, Keycloak, Authelia)
- OPDS catalogs and Send-to-Kindle
- Book Dock folder that adds new files for you
- The optional Kokoro text-to-speech service is left out

## How to use

1. Open BookOrbit from your dashboard.
2. The setup wizard opens. Type the setup token to create the admin account.
3. Create your first library and pick a folder under `/books`.
4. Start reading, or drop files into the Book Dock folder.
5. Add more users and connect OIDC/SSO in Settings if you need it.
6. Email (SMTP), metadata providers and other extras are set in the admin panel in the app.

## Before you install

Change `localhost` in `PUBLIC_URL` to your ZimaOS IP, like `http://192.168.1.20:6124`, so links from Kobo, OPDS and emails work on other devices. Leave `SETUP_BOOTSTRAP_TOKEN` blank to get a random one: after the first start, open the app log and find the line that says "the setup token is". Your books go in `/DATA/AppData/bookorbit/books`; to use a folder you already have, change the `/books` volume. The first start takes about two minutes. Log level, sign-in options and the other settings are in the Variables tab; add them in the app settings.
