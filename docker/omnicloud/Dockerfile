# syntax=docker/dockerfile:1.7
#
# OmniCloud all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
#
# Upstream publishes no image and no releases, so both halves are built here
# from one pinned commit of github.com/dimartarmizi/OmniCloud. To update,
# change OMNICLOUD_COMMIT below (and x-casaos.version in the compose file) to
# a newer commit and rebuild.
#
# Services inside:
#   api       chroot   (the Node API from backend/, on the official Node image,
#                       SQLite database in /data)
#   gateway   built-in (nginx on 8080: the built web app from frontend/ on /,
#                       the API on /api and upload progress on /ws/uploads)

ARG OMNICLOUD_COMMIT=51b949a638817e54434338a737de9055628cedac

# The API's native module (better-sqlite3) is built for this Node major;
# move to a new major by hand after testing (also in the web-build stage).
# auto-update: hold
FROM node:22.23.4-bookworm-slim AS img-api

# ---- the source, at the pinned commit ----
FROM debian:bookworm-slim AS src
ARG OMNICLOUD_COMMIT
ADD https://github.com/dimartarmizi/OmniCloud/archive/${OMNICLOUD_COMMIT}.tar.gz /tmp/src.tar.gz
RUN set -eux; \
    mkdir -p /src; \
    tar -xzf /tmp/src.tar.gz -C /src --strip-components=1; \
    test -f /src/backend/package-lock.json; \
    test -f /src/frontend/package-lock.json

# ---- the API's dependencies, for the target platform (native modules) ----
FROM img-api AS api-build
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends python3 make g++; \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=src /src/backend/package.json /src/backend/package-lock.json ./
# npm install, not npm ci: upstream's backend lockfile is missing the
# @aws-sdk packages its package.json lists, so npm ci refuses to run.
# Upstream's own backend/Dockerfile uses npm install too.
RUN npm install --omit=dev --no-audit --no-fund
COPY --from=src /src/backend/src ./src
RUN node --input-type=module -e "import 'better-sqlite3'; import '@aws-sdk/client-s3'; import '@aws-sdk/lib-storage'"

# ---- the web app (static files, so built once on the build machine) ----
# Same Node as img-api; kept in step by hand.
# auto-update: hold
FROM --platform=$BUILDPLATFORM node:22.23.4-bookworm-slim AS web-build
WORKDIR /web
COPY --from=src /src/frontend/ ./
# Same build settings as upstream's docker-compose.yml: the web app calls the
# API on the address it was opened from.
ENV VITE_API_BASE_URL=/api \
    VITE_WS_BASE_URL=/ws/uploads
RUN npm ci && npm run build && test -f dist/index.html

# ---- the final image ----
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot service: the Node image with the API in /app.
COPY --from=img-api / /opt/rootfs/api/
COPY --from=api-build --chown=1000:1000 /app/ /opt/rootfs/api/app/

# The gateway serves the built web app directly.
COPY --from=web-build /web/dist/ /srv/omnicloud-web/

COPY meta/ /opt/meta/
# The Node image's own start command is just "node"; start the API instead,
# as upstream's backend/Dockerfile does (npm start = node src/server.js).
RUN set -eux; \
    jq '.Cmd = ["node", "src/server.js"] | .WorkingDir = "/app" | .User = "node" | .Env += ["NODE_ENV=production"]' \
      /opt/meta/api.json > /tmp/api.json; \
    mv /tmp/api.json /opt/meta/api.json
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="omnicloud" \
      org.opencontainers.image.description="OmniCloud (API and web app) in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
