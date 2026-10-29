# syntax=docker/dockerfile:1.7
#
# Monolith all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
#
# Upstream publishes no server image, so it is built here from one pinned
# release of github.com/MaxJafar/monolith, the same way upstream's
# docker/server/Dockerfile does. To update, change MONOLITH_VERSION below
# (and x-casaos.version in the compose file) and rebuild.
#
# Services inside:
#   postgres  built-in (PGDG postgresql-17, same major as upstream's postgres:17)
#   server    chroot   (the Node API, apps/api; runs upstream's migrate.sh first)
#   edge      chroot   (upstream's Go gateway: serves the web app and /api/v1,
#                       proxies the rest to server; same filesystem as server)
#   gateway   built-in (nginx on 8080, in front of edge)

ARG MONOLITH_VERSION=v0.1.22

# The Node major the whole workspace is built and run on (upstream: node:22).
# A new major needs testing first.
# auto-update: hold
FROM node:22.23.4-bookworm-slim AS img-server

FROM golang:1.27.3-bookworm AS go-toolchain

# ---- the source, at the pinned release ----
FROM debian:bookworm-slim AS src
ARG MONOLITH_VERSION
ADD https://github.com/MaxJafar/monolith/archive/refs/tags/${MONOLITH_VERSION}.tar.gz /tmp/src.tar.gz
RUN set -eux; \
    mkdir -p /src; \
    tar -xzf /tmp/src.tar.gz -C /src --strip-components=1; \
    test -f /src/pnpm-lock.yaml; \
    cd /src; \
    # what upstream's .dockerignore keeps out of its build
    find . \( -name '*.test.ts' -o -name '*.test.tsx' -o -name '*.spec.ts' -o -name '*.spec.tsx' \) -type f -delete; \
    find . -name '__tests__' -type d -prune -exec rm -rf {} +; \
    rm -rf .github database storage reference readme instructions

# ---- build the workspace and the Go gateway (upstream's "builder" stage) ----
FROM img-server AS builder
ARG MONOLITH_VERSION
COPY --from=go-toolchain /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:$PATH \
    PNPM_HOME=/pnpm \
    COREPACK_HOME=/opt/corepack \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    VITE_API_HOST=/api
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates python3 make g++; \
    rm -rf /var/lib/apt/lists/*; \
    corepack enable; corepack prepare pnpm@11.21.0 --activate
WORKDIR /monolith
COPY --from=src /src/ /monolith/
RUN --mount=type=cache,id=monolith-pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --store-dir /pnpm/store
RUN pnpm exec turbo build --filter="./packages/*" \
    && pnpm exec turbo build --continue --filter="!@monolith/site" --filter="!@monolith/desktop"
RUN pnpm exec go build -C apps/gateway -trimpath -o /monolith/monolith-gateway ./cmd/monolith \
    && test -f /monolith/apps/web/dist/index.html \
    && test -f /monolith/apps/api/dist/server.js

# ---- the runtime filesystem (upstream's "production" stage) ----
FROM img-server AS server-rootfs
ARG MONOLITH_VERSION
ENV COREPACK_HOME=/opt/corepack
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl postgresql-client chromium graphicsmagick ghostscript fonts-dejavu-core; \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/corepack /opt/corepack
COPY --from=builder --chown=node:node /monolith /monolith
RUN set -eux; \
    corepack enable; \
    chown -R node:node /opt/corepack; \
    chmod +x /monolith/docker/server/*.sh; \
    mkdir -p /monolith/storage; \
    chown node:node /monolith/storage

# ---- the final image ----
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

# Chroot services: server and edge share one filesystem.
COPY --from=server-rootfs / /opt/rootfs/server/

COPY meta/ /opt/meta/
# The Node image's own start command is just "node". Start Monolith's API and
# gateway instead, as upstream's compose file does (the commands themselves are
# set in run-svc.sh).
ARG MONOLITH_VERSION
RUN set -eux; \
    jq --arg v "${MONOLITH_VERSION#v}" \
      '.Entrypoint = [] | .Cmd = [] | .WorkingDir = "/monolith" | .User = "node" \
       | .Env += ["NODE_ENV=production", "ROOT_DIR=/monolith", "PORT=3636", \
                  "FILE_STORAGE_LOCAL_PATH=/monolith/storage", \
                  "PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium", \
                  "COREPACK_HOME=/opt/corepack", "COREPACK_ENABLE_DOWNLOAD_PROMPT=0", \
                  "PNPM_HOME=/pnpm", \
                  "MONOLITH_RELEASE_VERSION=\($v)"]' \
      /opt/meta/server.json > /tmp/server.json; \
    mv /tmp/server.json /opt/meta/server.json; \
    cp /opt/meta/server.json /opt/meta/edge.json
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="monolith" \
      org.opencontainers.image.description="Monolith (API, gateway, web app and PostgreSQL) in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/healthz || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
