---
site: https://www.commafeed.com
source: https://github.com/Athou/commafeed
screenshots: [Dark mode, Light mode]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: COMMAFEED_FEED_REFRESH_INTERVAL
    group: Feeds
    default: "5m"
    description: >-
      How often feeds are checked for new items.
  - name: COMMAFEED_FEED_REFRESH_MAX_INTERVAL
    group: Feeds
    default: "4h"
    description: >-
      Longest wait between checks for feeds that rarely change.
  - name: COMMAFEED_FEED_REFRESH_HTTP_THREADS
    group: Feeds
    default: "3"
    description: >-
      How many feeds are fetched at the same time.
  - name: COMMAFEED_DATABASE_CLEANUP_ENTRIES_MAX_AGE
    group: Storage
    default: "365d"
    description: >-
      Delete articles older than this. 0 keeps them forever.
  - name: COMMAFEED_DATABASE_CLEANUP_MAX_FEED_CAPACITY
    group: Storage
    default: "500"
    description: >-
      Most articles kept for each feed.
  - name: COMMAFEED_USERS_MINIMUM_PASSWORD_LENGTH
    group: Users
    default: "4"
    description: >-
      Shortest password a user may pick.
  - name: COMMAFEED_USERS_EMAIL_ADDRESS_REQUIRED
    group: Users
    default: "false"
    description: >-
      true asks for an email address when someone signs up.
  - name: COMMAFEED_PASSWORD_RECOVERY_ENABLED
    group: Email
    default: "false"
    description: >-
      true shows a forgot-password link. Needs the Quarkus mailer settings (QUARKUS_MAILER_*).
  - name: COMMAFEED_IMAGE_PROXY_ENABLED
    group: Privacy
    default: "false"
    description: >-
      true loads article images through CommaFeed, so feed sites don't see your address.
  - name: COMMAFEED_HIDE_FROM_WEB_CRAWLERS
    group: Privacy
    default: "true"
    description: >-
      Ask search engines not to index CommaFeed.
  - name: COMMAFEED_ANNOUNCEMENT
    group: Web
    default: ""
    description: >-
      A message shown to every user at the top of the page.
  - name: COMMAFEED_HTTP_CLIENT_USER_AGENT
    group: Advanced
    default: ""
    description: >-
      The user agent sent to feed sites.
  - name: QUARKUS_HTTP_AUTH_SESSION_ENCRYPTION_KEY
    group: Advanced
    default: ""
    description: >-
      Key that keeps people signed in across restarts (16+ characters). Leave blank and IceStore makes one.
---

# CommaFeed

CommaFeed is a bloat-free feed reader inspired by Google Reader. It is a native program with a small built-in database, so it starts in a second and uses little memory.

## Features

- Four layouts, light and dark themes, keyboard shortcuts
- Categories, starred items, filters and full-text search
- OPML import and export
- Fever API for phone apps like Reeder and ReadKit
- Several users, each with their own feeds
- Translated into over 25 languages

## How to use

1. Open CommaFeed. On the first visit, make the admin account.
2. Click Subscribe and paste a site or feed address.
3. Or import your old reader's OPML file under Settings.

## Before you install

CommaFeed has no default login: the first person to open http://[ZIMAOS-IP-ADDRESS]:6887 makes the admin account, so do it right after installing. Sign-up for others is off; the admin adds users, or set COMMAFEED_USERS_ALLOW_REGISTRATIONS to true. By default CommaFeed won't fetch feeds from addresses on your home network; set COMMAFEED_HTTP_CLIENT_BLOCK_LOCAL_ADDRESSES to false to follow feeds from other apps on your ZimaOS. Upstream makes a new sign-in key on every start, which signs everyone out; this IceStore image keeps one key per install so you stay signed in. Any CommaFeed setting can be set as COMMAFEED_ plus its name in capitals (see the documentation).
