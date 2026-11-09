# syntax=docker/dockerfile:1.7
#
# Inkling all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# Shared files come from docker/_common, so build with:
#   docker buildx build --build-context common=docker/_common docker/inkling
# The weekly bumper (update-upstream.yml) keeps the FROM line current.
#
# Services inside (from upstream's compose.yaml):
#   postgres   built-in (PGDG postgresql-16, same major as upstream's postgres:16-alpine)
#   inkling    chroot   (the upstream image: web app, API, live editing, MCP on 3000)
#   firstkey   built-in (one-off: this install's first signup key)
#   gateway    built-in (nginx on 8080)
# Left out: upstream's backup sidecar. Back up /DATA/AppData/inkling instead
# (ZimaOS backup, or a copy while the app is stopped).

FROM ghcr.io/prove1352/inkling:0.8.0 AS img-inkling

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
        postgresql-16 nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot service: the whole upstream filesystem.
COPY --from=img-inkling / /opt/rootfs/inkling/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="inkling" \
      org.opencontainers.image.description="Inkling notes in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
