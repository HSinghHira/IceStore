# syntax=docker/dockerfile:1.7
#
# Homi for IceStore, in one container. Upstream publishes no image, so this
# builds its Dockerfile.core and Dockerfile.web steps from one release tag,
# and adds what its compose.yaml runs beside them:
#
#   postgres        PostgreSQL 18 (upstream's compose uses postgres:18.6)
#   module-manager  installs and backs up household modules (port 3002)
#   core            the API (port 3001)
#   gateway         nginx on 8080: the web app, /api and /health to core
#
# The setup commands upstream runs by hand (database roles, migrations, the
# first account, the calendar and chequebook modules) run in icestore-init.
#
# To update, change HOMI_REF below (and x-casaos.version in the compose
# file), bump docker/homi/VERSION and rebuild.

ARG HOMI_REF=v1.9.3

# Homi requires Node 24 (.nvmrc, Dockerfile.core): take its patches, not a new major.
# auto-update: keep-major
FROM node:24.21.0-bookworm-slim
ARG HOMI_REF
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    mkdir -p /etc/postgresql-common; echo 'create_main_cluster = false' > /etc/postgresql-common/createcluster.conf; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    install -d /usr/share/keyrings; \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends postgresql-18 nginx supervisor openssl tzdata procps util-linux; \
    rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/*

# ---- upstream's Dockerfile.core and Dockerfile.web, from the release tarball ----
ADD https://github.com/thecybermacgyver/homi/archive/refs/tags/${HOMI_REF}.tar.gz /tmp/homi.tar.gz
RUN set -eux; \
    mkdir -p /opt/homi; \
    tar -xzf /tmp/homi.tar.gz -C /opt/homi --strip-components=1; \
    rm /tmp/homi.tar.gz; \
    cd /opt/homi; \
    corepack enable; \
    pnpm install --frozen-lockfile; \
    pnpm --filter @homi/db build; \
    pnpm --filter @homi/module-sdk build; \
    pnpm --filter @homi/ui build; \
    pnpm --filter @homi/calendar build; \
    pnpm --filter @homi/chequebook build; \
    pnpm --filter @homi/core build; \
    pnpm --filter @homi/web build; \
    mkdir -p /usr/share/homi-web; \
    cp -a apps/web/dist/. /usr/share/homi-web/; \
    cp deploy/nginx-security-headers.conf /etc/nginx/homi-security-headers.conf; \
    rm -rf /root/.cache /root/.local/share/pnpm/store; \
    chmod -R a+rX /opt/homi /usr/share/homi-web

WORKDIR /opt/homi
ENV NODE_ENV=production

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/homi-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
COPY nginx.conf /etc/nginx/homi.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/homi-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="homi" \
      org.opencontainers.image.description="Homi household app, built from upstream source, with PostgreSQL inside" \
      org.opencontainers.image.version="${HOMI_REF}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/health/ready || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
