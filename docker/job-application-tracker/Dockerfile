# syntax=docker/dockerfile:1.7
#
# Job Application Tracker for IceStore.
#
# Upstream publishes no image, so it is built here from one pinned release of
# github.com/waddington/job-application-tracker, the way its README installs
# it: `uv sync` for the Python app and `pnpm build` for the web UI. To update,
# change JAT_VERSION below (and x-casaos.version in the compose file), bump
# AIO_VERSION in build-job-application-tracker.yml and rebuild.
#
# One base image: Node 22 (for the UI build) on Debian trixie, whose python3
# (3.13) runs the app. The weekly bumper keeps the Node tag current within 22.

ARG JAT_VERSION=v1.1.0

# auto-update: keep-major
FROM node:22.23.4-trixie-slim

ARG JAT_VERSION
ENV DEBIAN_FRONTEND=noninteractive \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    UV_PYTHON=/usr/bin/python3 \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends python3 python3-venv git ca-certificates tzdata; \
    rm -rf /var/lib/apt/lists/*

# ---- the source, at the pinned release ----
ADD https://github.com/waddington/job-application-tracker/archive/refs/tags/${JAT_VERSION}.tar.gz /tmp/src.tar.gz
RUN set -eux; \
    mkdir -p /app; \
    tar -xzf /tmp/src.tar.gz -C /app --strip-components=1; \
    rm /tmp/src.tar.gz; \
    test -f /app/uv.lock; \
    rm -rf /app/website /app/tests /app/docs /app/.github /app/.idea /app/.claude

WORKDIR /app

# ---- the Python app (upstream: uv sync) ----
RUN set -eux; \
    python3 -m venv /opt/uv; \
    /opt/uv/bin/pip install --no-cache-dir uv; \
    /opt/uv/bin/uv sync --frozen --no-dev; \
    rm -rf /opt/uv /root/.cache; \
    /app/.venv/bin/jat --help >/dev/null

# ---- the web UI (upstream: pnpm --dir frontend install && build) ----
RUN set -eux; \
    corepack enable; \
    cd frontend; \
    pnpm install --frozen-lockfile; \
    pnpm build; \
    test -f dist/index.html; \
    rm -rf node_modules /root/.cache /root/.local/share/pnpm

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

ENV JAT_DATA_DIR=/data \
    JAT_HOST=0.0.0.0 \
    JAT_PORT=8770 \
    PATH=/app/.venv/bin:$PATH

LABEL org.opencontainers.image.title="job-application-tracker" \
      org.opencontainers.image.description="Job Application Tracker, built from the upstream release" \
      org.opencontainers.image.version="${JAT_VERSION}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8770
VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8770/api/v1/health', timeout=4)" || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
