# syntax=docker/dockerfile:1.7
#
# Trackie all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# The weekly bumper (update-upstream.yml) keeps the FROM lines current.
#
# Services inside:
#   postgres   built-in (PGDG postgresql-17, same major as upstream's postgres:17; Logto's database)
#   logto      chroot   (the Logto sign-in server and its admin console, from
#                        upstream's compose.logto.yml)
#   trackie    chroot   (the Trackie / Actual Budget sync server and web app)
#   gateway    built-in (nginx: 8080 Trackie, 8081 Logto, 8082 Logto admin console)
#
# amd64 only: ghcr.io/trackie-nz/trackie has no arm64 image.

FROM ghcr.io/trackie-nz/trackie:26.9.0-trackie.2 AS img-trackie
FROM svhd/logto:1.45.0 AS img-logto

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
        postgresql-17 nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystems.
COPY --from=img-trackie / /opt/rootfs/trackie/
COPY --from=img-logto / /opt/rootfs/logto/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="trackie" \
      org.opencontainers.image.description="Trackie (Actual Budget, NZ) with its Logto sign-in server in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080 8081 8082
STOPSIGNAL SIGTERM

# Healthy once the sign-in server is up: Trackie itself waits until you have
# registered it in Logto (see the install tips).
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/icestore-health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
