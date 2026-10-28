# syntax=docker/dockerfile:1.7
#
# Poke all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
#
# Services inside:
#   postgres   built-in (PGDG postgresql-17, Invidious' database)
#   invidious  chroot   (Invidious API on 3000, used by Poke from the server side)
#   companion  chroot   (Invidious companion on 8282: video streams and captions at /companion)
#   poke       chroot   (Poke itself on 6003, built from source below)
#   gateway    built-in (nginx on 8080)
#
# Poke publishes no image, so it is built from a pinned commit. Invidious
# publishes one tag per architecture (an "-arm64" twin), so the right one is
# picked by TARGETARCH. Neither has tags the weekly bumper can follow: bump
# POKE_COMMIT and the "auto-update: hold" tags by hand.

# auto-update: hold
FROM --platform=linux/amd64 quay.io/invidious/invidious:2026.10.26-1c4b41f AS invidious-amd64
# auto-update: hold
FROM --platform=linux/arm64 quay.io/invidious/invidious:2026.10.26-1c4b41f-arm64 AS invidious-arm64
FROM invidious-${TARGETARCH} AS invidious-rootfs

# auto-update: hold
FROM quay.io/invidious/invidious-companion:2026.10.18-fcb0456 AS img-companion

# ---- Poke, from source ----
# Node 18: Poke's quick.db pulls in better-sqlite3 7.x, which does not build
# on newer Node versions. Upstream's own Dockerfile uses Node 16.
# auto-update: keep-major
FROM node:18.20.8-bookworm-slim AS poke-build
ARG POKE_COMMIT=a62345721f52b8beef9fddcd5f676c802d9d44e3
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl git python3 make g++ libcurl4-openssl-dev; \
    rm -rf /var/lib/apt/lists/*
WORKDIR /poketube
# The DASH manifest route is hard-wired to poketube.fun's own Invidious;
# the sed points it at the Invidious inside this container instead.
RUN set -eux; \
    curl -fsSL "https://codeberg.org/ashleyirispuppy/poke/archive/${POKE_COMMIT}.tar.gz" \
      | tar -xz --strip-components=1; \
    sed -i 's#https://invid-api.poketube.fun/bHj665PpYhUdPWuKPfZuQGoX/api/manifest/dash/id/#http://127.0.0.1:3000/api/manifest/dash/id/#' \
      src/libpoketube/init/pages-api.js; \
    grep -q 'http://127.0.0.1:3000/api/manifest/dash/id/' src/libpoketube/init/pages-api.js; \
    npm install --omit=dev --no-audit --no-fund; \
    npm cache clean --force; \
    rm -rf .git backend-services issue_template

# auto-update: keep-major
FROM node:18.20.8-bookworm-slim AS poke-rootfs
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates libcurl4 tzdata; \
    rm -rf /var/lib/apt/lists/*
COPY --from=poke-build --chown=node:node /poketube /poketube

# ---- the base image: built-in services come from apt ----
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    mkdir -p /etc/postgresql-common; echo 'create_main_cluster = false' > /etc/postgresql-common/createcluster.conf; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    install -d /usr/share/keyrings; \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt trixie-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        postgresql-17 nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole filesystem, one folder each.
COPY --from=invidious-rootfs / /opt/rootfs/invidious/
COPY --from=img-companion / /opt/rootfs/companion/
COPY --from=poke-rootfs / /opt/rootfs/poke/

# capture-meta.sh records the companion image's start-up settings. Invidious
# and Poke have no single image to read them from, so theirs are written here.
COPY meta/ /opt/meta/
COPY invidious.meta.json /opt/meta/invidious.json
COPY poke.meta.json /opt/meta/poke.json
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="poke" \
      org.opencontainers.image.description="Poke with Invidious in a single container" \
      org.opencontainers.image.licenses="GPL-3.0-or-later AND AGPL-3.0-or-later" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=240s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/version.json || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
