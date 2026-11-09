# syntax=docker/dockerfile:1.7
#
# Select for IceStore, in one container.
#
# Upstream publishes no image, so it is built here from one release tag of
# github.com/Kirby54/Select, the way upstream's docker/api.Dockerfile and
# docker/web.Dockerfile do it (uv sync for the API and worker, a Next.js
# standalone build for the web app). PostgreSQL 16 (upstream's
# postgres:16-alpine) runs inside too; supervisord starts everything (see
# icestore-init.sh and svc.sh).
#
# To update, change SELECT_REF below (and x-casaos.version in the compose
# file), bump AIO_VERSION in build-select.yml and rebuild.

ARG SELECT_REF=v1.0.0

# Python 3.12 is what upstream pins (.python-version); held so the weekly
# bumper doesn't move it to a newer minor the lockfile wasn't made for.
# auto-update: hold
FROM python:3.12.16-slim-trixie
ARG SELECT_REF
ENV DEBIAN_FRONTEND=noninteractive PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never NEXT_TELEMETRY_DISABLED=1

# Node 22 for the web app (upstream's node:22-bookworm-slim).
COPY --from=node:22.23.4-trixie-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:22.23.4-trixie-slim /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN set -eux; \
    ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    mkdir -p /etc/postgresql-common; echo 'create_main_cluster = false' > /etc/postgresql-common/createcluster.conf; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    install -d /usr/share/keyrings; \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt trixie-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends postgresql-16 supervisor util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*; \
    pip install --no-cache-dir uv==0.11.32; \
    useradd --create-home --uid 10001 select

# ---- build: upstream's two Dockerfiles in one layer, keeping only what
# ---- their runtime stages keep ----
ADD https://github.com/Kirby54/Select/archive/refs/tags/${SELECT_REF}.tar.gz /tmp/src.tar.gz
RUN set -eux; \
    mkdir -p /tmp/src /app/apps /web; \
    tar -xzf /tmp/src.tar.gz -C /tmp/src --strip-components=1; \
    cd /tmp/src; \
    cp -a pyproject.toml uv.lock packages contracts packs /app/; \
    cp -a apps/api /app/apps/api; \
    cd /app; uv sync --frozen --no-dev --all-packages; \
    cd /tmp/src/apps/web; \
    npm ci --no-audit --no-fund; \
    npm run build; \
    test -f .next/standalone/server.js; \
    cp -a .next/standalone/. /web/; \
    cp -a .next/static /web/.next/static; \
    cp -a public /web/public; \
    cp /tmp/src/LICENSE /app/LICENSE; \
    rm -rf /tmp/src /tmp/src.tar.gz /root/.cache /root/.npm /usr/local/lib/node_modules/npm /usr/local/bin/npm; \
    chown -R select:select /web

ENV PATH="/app/.venv/bin:$PATH" \
    SELECT_DATA_DIR=/data/select \
    SELECT_CONTRACTS_DIR=/app/contracts \
    SELECT_PACKS_DIR=/app/packs \
    NODE_ENV=production

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/select-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/select-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="select" \
      org.opencontainers.image.description="Select AI agent orchestration, built from upstream source, with PostgreSQL inside" \
      org.opencontainers.image.version="${SELECT_REF}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 3000
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8000/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
