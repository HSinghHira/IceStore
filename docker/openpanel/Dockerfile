# syntax=docker/dockerfile:1.7
#
# OpenPanel all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# Shared files come from docker/_common, so build with:
#   docker buildx build --build-context common=docker/_common docker/openpanel
# To bump a version, change the tag on a FROM line below and rebuild.
#
# Services inside (from upstream's self-hosting/docker-compose.template.yml):
#   postgres    built-in (PGDG postgresql-14, same major as upstream's postgres:14-alpine)
#   redis       built-in (queues and cache, noeviction like upstream)
#   clickhouse  chroot   (the event store, upstream's image and config)
#   api         chroot   (runs the database migrations first, then the API on 3001)
#   worker      chroot   (queues and scheduled jobs, on 3002)
#   dashboard   chroot   (the web app, on 3000)
#   gateway     built-in (nginx on 8080: /api/ to the API, the rest to the dashboard)

FROM lindesvard/openpanel-api:2.3.0 AS img-api
FROM lindesvard/openpanel-worker:2.3.0 AS img-worker
FROM lindesvard/openpanel-dashboard:2.3.0 AS img-dashboard
# Same ClickHouse as upstream's compose. A new ClickHouse release can change
# how OpenPanel's queries behave, so it moves only when upstream moves it.
# auto-update: hold
FROM clickhouse/clickhouse-server:25.10.2.65 AS img-clickhouse

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
        postgresql-14 redis-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystem, one folder each.
COPY --from=img-api / /opt/rootfs/api/
COPY --from=img-worker / /opt/rootfs/worker/
COPY --from=img-dashboard / /opt/rootfs/dashboard/
COPY --from=img-clickhouse / /opt/rootfs/clickhouse/

# Upstream's ClickHouse config, users config and first-start script, which
# its compose mounts into the ClickHouse container.
COPY clickhouse-config.xml /opt/rootfs/clickhouse/etc/clickhouse-server/config.d/op-config.xml
COPY clickhouse-user-config.xml /opt/rootfs/clickhouse/etc/clickhouse-server/users.d/op-user-config.xml
COPY clickhouse-init-db.sh /opt/rootfs/clickhouse/docker-entrypoint-initdb.d/init-db.sh
RUN chmod 755 /opt/rootfs/clickhouse/docker-entrypoint-initdb.d/init-db.sh

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="openpanel" \
      org.opencontainers.image.description="OpenPanel analytics in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/healthcheck || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
