# syntax=docker/dockerfile:1.7
#
# Norish all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# The weekly bumper (update-upstream.yml) keeps the FROM lines current.
#
# Services inside:
#   postgres   built-in (PGDG postgresql-17, same major as upstream's postgres:17-alpine)
#   redis      built-in (Debian's redis-server: real-time events and job queues)
#   obscura    chroot   (Norish's headless browser for URL imports, on 9222)
#   norish     chroot   (the app on 3000: runs its own migrations on start)
#   gateway    built-in (nginx on 8080)

FROM norishapp/norish:v0.25.1-beta AS img-norish
FROM norishapp/obscura:0.2.4-norish.2 AS img-obscura

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

# Chroot services: the whole upstream filesystem, one folder each.
COPY --from=img-norish / /opt/rootfs/norish/
COPY --from=img-obscura / /opt/rootfs/obscura/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="norish" \
      org.opencontainers.image.description="Norish recipe app in a single container" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/v1/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
