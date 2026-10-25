# syntax=docker/dockerfile:1.7
#
# cobalt all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# To bump a version, change the tag on the FROM line below and rebuild.
#
# Services inside:
#   api      chroot   (ghcr.io/imputnet/cobalt: the processing API on 127.0.0.1:9000)
#   gateway  built-in (nginx on 8080: serves the web app on /, the api on /api and the
#                      api's download links on /tunnel, so everything shares one address)
#
# The web app is the official one from imputnet/cobalt/web. Upstream publishes no image
# for it, so it is built here from the same commit as the API: the API image carries the
# whole repository in /app/.git, so one FROM tag keeps both in step.

FROM ghcr.io/imputnet/cobalt:11.7.1 AS img-api

# ---- the web app, built from the API image's own source tree ----
FROM img-api AS web-build
USER root
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN apk add --no-cache git
WORKDIR /src
# Upstream CI leaves its (expired) checkout token header in the git config; drop it.
RUN set -eux; \
    cp -r /app/.git /src/.git; \
    git config --global --add safe.directory /src; \
    git config --unset-all 'http.https://github.com/.extraheader' || true; \
    git reset -q --hard HEAD; \
    test -f web/package.json
# The web app reads its API address from WEB_DEFAULT_API at build time. Make it use
# <the address the page was opened from>/api instead, so one image works on any IP
# or domain (the gateway serves the API under /api). The build fails here if
# upstream moves this line, so a bump never ships a web app pointing at nowhere.
RUN set -eux; \
    f=web/src/lib/api/api-url.ts; \
    grep -q 'return new URL(env.DEFAULT_API!).origin;' "$f"; \
    sed -i 's|return new URL(env\.DEFAULT_API!)\.origin;|return typeof location !== "undefined" ? location.origin + "/api" : new URL(env.DEFAULT_API!).origin;|' "$f"; \
    grep -q 'location.origin + "/api"' "$f"
RUN corepack enable
RUN --mount=type=cache,id=cobalt-pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --filter=./web
RUN WEB_DEFAULT_API=http://localhost:6144/ pnpm run --filter=./web build \
    && test -f web/build/404.html

# ---- the final image ----
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot service: the whole API image (Node on Alpine, with its own ffmpeg).
COPY --from=img-api / /opt/rootfs/api/

# The gateway serves the built web app directly.
COPY --from=web-build /src/web/build/ /srv/cobalt-web/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="cobalt" \
      org.opencontainers.image.description="cobalt media downloader (API and web app) in a single container" \
      org.opencontainers.image.licenses="AGPL-3.0 AND CC-BY-NC-SA-4.0" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/ || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
