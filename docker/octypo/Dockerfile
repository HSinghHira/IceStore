# syntax=docker/dockerfile:1.7
#
# Octypo for IceStore, in one container: the engine from npm (`octypo`, the
# package upstream's quick start installs) and PostgreSQL 16 (upstream's
# postgres:16), started by supervisord. Upstream publishes no image.
#
# To update, change OCTYPO_VERSION (and x-casaos.version in the compose
# file), bump AIO_VERSION in build-octypo.yml and rebuild. `octypo start`
# applies new migrations itself.

ARG OCTYPO_VERSION=1.0.0

# auto-update: keep-major
FROM node:22.23.4-trixie-slim
ARG OCTYPO_VERSION
ENV DEBIAN_FRONTEND=noninteractive NODE_ENV=production

RUN set -eux; \
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
    npm install -g "octypo@${OCTYPO_VERSION}" --no-audit --no-fund; \
    npm cache clean --force; \
    command -v octypo

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="octypo" \
      org.opencontainers.image.description="Octypo engine (npm ${OCTYPO_VERSION}) with PostgreSQL inside" \
      org.opencontainers.image.version="${OCTYPO_VERSION}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:3000/health || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
