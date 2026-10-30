# syntax=docker/dockerfile:1.7
#
# Dawarich all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# The weekly bumper (update-upstream.yml) moves the tag on the FROM line below.
#
# Services inside:
#   postgres   built-in (PGDG postgresql-17 + PostGIS 3, same major as upstream's postgis/postgis:17-3.5)
#   redis      built-in (Debian redis-server; Sidekiq jobs and cache)
#   dawarich   chroot   (the upstream Rails image as-is: web app, API and Sidekiq jobs in one process)
#   admin      built-in (one-off: replaces the seeded demo password with this install's own)
#   gateway    built-in (nginx on 8080)

FROM freikin/dawarich:1.19.0 AS img-dawarich

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
        postgresql-17 postgresql-17-postgis-3 redis-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot service: the whole upstream filesystem.
COPY --from=img-dawarich / /opt/rootfs/dawarich/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="dawarich" \
      org.opencontainers.image.description="Dawarich in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/v1/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
