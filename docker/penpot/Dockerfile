# syntax=docker/dockerfile:1.7
#
# Penpot all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# The daily bumper (update-upstream.yml) moves the tags below.
#
# Services inside:
#   postgres   built-in (PGDG postgresql-15, same major as upstream's postgres:15)
#   redis      built-in (Debian redis-server, in place of upstream's valkey:8.1)
#   mailpit    chroot   (fallback mail server and viewer at /mail when no SMTP is set)
#   backend    chroot   (penpotapp/backend: the Java API on 6060)
#   exporter   chroot   (penpotapp/exporter: PNG/PDF/SVG exports with Chromium, on 6061)
#   frontend   chroot   (penpotapp/frontend: its own nginx, moved from 8080 to 9001,
#                        serves the app and routes /api, /assets, /ws to the others)
#   gateway    built-in (nginx on 8080: /mail, everything else to the frontend)
#
# Left out: the admin console and the MCP server (optional extras).

FROM penpotapp/backend:2.19.3 AS img-backend
FROM penpotapp/exporter:2.19.3 AS img-exporter
FROM penpotapp/frontend:2.19.3 AS img-frontend
FROM axllent/mailpit:v1.34.0 AS img-mailpit

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
        postgresql-15 redis-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystems.
COPY --from=img-backend  / /opt/rootfs/backend/
COPY --from=img-exporter / /opt/rootfs/exporter/
COPY --from=img-frontend / /opt/rootfs/frontend/
COPY --from=img-mailpit  / /opt/rootfs/mailpit/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="penpot" \
      org.opencontainers.image.description="Penpot design platform in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/readyz || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
