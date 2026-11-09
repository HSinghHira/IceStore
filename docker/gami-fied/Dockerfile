# syntax=docker/dockerfile:1.7
#
# Gami.Fied all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# Shared files come from docker/_common, so build with:
#   docker buildx build --build-context common=docker/_common docker/gami-fied
# The weekly bumper (update-upstream.yml) keeps the FROM lines current.
#
# Services inside (from upstream's docker-compose.yml):
#   postgres   built-in (PGDG postgresql-17, same major as upstream's postgres:17-alpine)
#   redis      built-in (Debian redis-server, with a password as upstream)
#   migrate    built-in (one-off: upstream's migration service, in the api's files)
#   api        chroot   (gami-api on 3001)
#   worker     chroot   (gami-worker)
#   dashboard  chroot   (gami-dashboard on 3000)
#   gateway    built-in (nginx on 8080: upstream's Caddyfile.example routes)

FROM ghcr.io/gami-fied/gami-api:1.1.0 AS img-api
FROM ghcr.io/gami-fied/gami-worker:1.1.0 AS img-worker
FROM ghcr.io/gami-fied/gami-dashboard:1.1.0 AS img-dashboard

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
        postgresql-17 redis-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystems.
COPY --from=img-api       / /opt/rootfs/api/
COPY --from=img-worker    / /opt/rootfs/worker/
COPY --from=img-dashboard / /opt/rootfs/dashboard/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="gami-fied" \
      org.opencontainers.image.description="Gami.Fied gamification engine in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/login || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
