---
site: https://trailbase.io
source: https://github.com/trailbaseio/trailbase
services:
  - { name: Admin Dashboard, path: /_/admin/, icon: grid }
  - { name: Record APIs, path: /api/records/v1/, icon: code }
variables:
  - name: RUST_LOG
    group: Advanced
    default: "info"
    description: >-
      Log detail: error, warn, info, debug or trace.
---

# TrailBase

TrailBase is an open app backend in one small program, like Firebase or Supabase. It gives you type-safe REST and realtime APIs over SQLite, user accounts, file uploads and an admin dashboard.

## Features

- REST and realtime APIs straight from your SQLite tables
- Built-in sign-up, sign-in and OAuth providers
- Admin dashboard with a table editor and SQL editor
- Server-side code in TypeScript or WebAssembly
- Client libraries for JS/TS, Dart, Rust, Go, C#, Swift, Kotlin and Python

## How to use

1. Open the app's log. On first start TrailBase prints the admin email and password.
2. Open the admin dashboard at http://[ZIMAOS-IP-ADDRESS]:6893/_/admin/ and sign in.
3. Make tables, then turn on a Record API for each one your app should use.

## Before you install

TrailBase makes its admin account on the first start and prints the email and password once in the app's log, so copy them right away; change the password in the dashboard afterwards. Most settings (site URL, email, OAuth providers, API rules) live in the dashboard and in config.textproto inside the traildepot folder, not in environment variables. Set the site URL to your https address when you put TrailBase behind a reverse proxy; until then sign-in cookies work over plain http.
