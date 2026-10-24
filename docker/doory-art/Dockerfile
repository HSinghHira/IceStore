# syntax=docker/dockerfile:1.7
#
# Doory Art (Doory) all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# To bump a version, change the tags on the FROM lines below and rebuild.
#
# Services inside:
#   postgres   built-in (PGDG postgresql-16, same major as upstream's postgres:16-alpine)
#   api        chroot   (doory-backend: gunicorn on 8000, migrations and first-run content)
#   realtime   chroot   (the same rootfs as api: uvicorn on 8001, WebSockets for co-editing)
#   mcp        chroot   (the same rootfs as api: uvicorn on 8002, only when MCP_ENABLED=true)
#   gateway    built-in (nginx on 8080: serves the doory-frontend files and proxies the rest,
#                        like upstream's web container)
#
# Left out: Redis (only needed for more than one realtime worker) and the optional
# ai-server (upstream publishes no image for it).

FROM ghcr.io/shaongitbd/doory-backend:0.2.0 AS img-api
FROM ghcr.io/shaongitbd/doory-frontend:0.2.0 AS img-web

# The published backend image has no ffmpeg (upstream's own compose build adds it by
# default). Add it so video clips work, and add the first-admin helper.
FROM img-api AS api-rootfs
USER root
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ffmpeg; \
    rm -rf /var/lib/apt/lists/*
COPY ensure-admin.py /opt/aio/ensure-admin.py

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

# Chroot services api, realtime and mcp all run in this one filesystem
# (Python 3.14 on Debian, with headless Chromium for server-side export).
COPY --from=api-rootfs / /opt/rootfs/api/

# The gateway serves the built web app and upstream's security headers directly.
COPY --from=img-web /usr/share/nginx/html/ /srv/doory-web/
COPY --from=img-web /etc/nginx/snippets/security-headers.conf /etc/nginx/snippets/doory-security-headers.conf

# Doory's licence (Attribution Assurance License) asks binary redistributions to carry it.
ADD https://raw.githubusercontent.com/shaongitbd/doory/v0.2.0/LICENSE /usr/share/doc/doory/LICENSE

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc \
    && chmod 644 /usr/share/doc/doory/LICENSE

LABEL org.opencontainers.image.title="doory-art" \
      org.opencontainers.image.description="Doory design editor in a single container" \
      org.opencontainers.image.licenses="AAL" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=600s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/v1/health/ || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
