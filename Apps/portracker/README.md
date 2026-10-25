---
site: https://github.com/mostafa-wahied/portracker
services:
  - { name: Dashboard, path: /, icon: grid }
variables:
  - name: RECOVERY_MODE
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true if you forgot your password. After a restart, a recovery
      code that works for 15 minutes appears in the app log. Take it out
      again afterwards.
  - name: CORS_ORIGIN
    group: Server
    default: ""
    description: >-
      Browser addresses allowed to call portracker, comma-separated, like
      https://ports.example.com. Only needed behind a reverse proxy that
      changes the host name.
  - name: INCLUDE_UDP
    group: Scanning
    default: "false"
    description: >-
      Set to true to list UDP ports too. This can add a lot of noise.
  - name: MAX_INTERNAL_PORTS_PER_CONTAINER
    group: Scanning
    default: "100"
    description: >-
      The most unpublished ports listed for one container. Containers with
      more still show their published ports.
  - name: CACHE_TIMEOUT_MS
    group: Scanning
    default: "60000"
    description: >-
      How long scan results are kept before scanning again, in milliseconds.
  - name: DISABLE_CACHE
    group: Scanning
    default: "false"
    description: >-
      Set to true to scan on every page load. Slower; mostly for testing.
  - name: TRUENAS_API_KEY
    group: TrueNAS
    default: ""
    description: >-
      A TrueNAS API key (System Settings, API Keys) to also show TrueNAS
      apps, VMs and system details.
  - name: TRUENAS_WS_BASE
    group: TrueNAS
    default: ""
    description: >-
      Your TrueNAS address, like ws://192.168.1.100:80. Leave it out to find
      it by itself.
  - name: TRUENAS_TIMEOUT_MS
    group: TrueNAS
    default: "90000"
    description: >-
      How long to wait for TrueNAS details, in milliseconds. Raise it to
      120000 or more if you have many apps or VMs and see timeouts.
  - name: DEBUG
    group: Logs
    default: "false"
    description: >-
      Set to true for detailed logs while you look for a problem.
---

# portracker

portracker scans your host and your Docker containers and builds a live map of every port in use, so messy spreadsheets and surprise port conflicts stop happening.

## Features

- Finds ports on the host and in Docker containers by itself, and shows internal and published ports apart
- Add other portracker servers as peers to see every server, container and VM on one dashboard
- Built-in login with a first-run setup wizard (no OIDC or other sign-in providers yet)
- One small container with a built-in SQLite database

## How to use

1. Open portracker from your dashboard.
2. Follow the setup wizard and make your admin username and password.
3. portracker starts scanning right away. There is nothing else to set up to see host and Docker ports.
4. To watch more machines, install portracker there too and add it as a peer from the Settings gear.

## Before you install

There is nothing you must set. `SESSION_SECRET` comes filled with a random value that keeps you signed in across restarts. The app starts in a few seconds; open `http://your-zimaos-ip:6158` and follow the setup wizard. portracker gets read-only access to Docker and sees the host's processes, which is how it finds ports. If you forget your password, add `RECOVERY_MODE=true` in the app settings and find the recovery code in the app log. UDP scanning, TrueNAS and other settings are in the Variables tab; add them in the app settings.
