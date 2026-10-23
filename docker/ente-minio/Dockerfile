# syntax=docker/dockerfile:1.7
#
# Ente - Silo S3 all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# The weekly bumper keeps the FROM lines current. Ente only publishes "latest"
# and one tag per git commit, so its two images are pinned to commit tags and
# follow "latest" (see .github/scripts/update_upstream.py).
#
# Services inside:
#   postgres   built-in (PGDG postgresql-15, same major as upstream's postgres:15)
#   silo       built-in (the Silo binary, extracted from pgsty/silo)
#   s3init     built-in (one-off: creates Ente's buckets)
#   mailpit    chroot   (catches sign-up emails; viewer at /mail/)
#   museum     chroot   (the Ente API server)
#   web        chroot   (the Ente web apps: photos on 3000, public albums on 3002)
#   quota      built-in (raises every account's storage limit; Ente's default is 10 GB)
#   gateway    built-in (nginx: 8080 photos, 8081 API, 8082 albums, 8083 S3)

FROM ghcr.io/ente/server:20fb6316bd98b1af613ef771c684d5cd46fbf371 AS img-museum
FROM ghcr.io/ente/web:817ce840de0e05ae8f817ca218795d620bc122c8 AS img-web
FROM axllent/mailpit:v1.32.0 AS img-mailpit
FROM pgsty/silo:RELEASE.2026-10-18T00-00-00Z AS img-silo

# Silo ships one static binary; it runs as a built-in service.
FROM debian:bookworm-slim AS silo-bin
COPY --from=img-silo / /silo-root
RUN set -eu; \
    bin=$(find /silo-root -maxdepth 5 -type f -perm /111 -name minio | head -n1); \
    [ -n "$bin" ] || bin=$(find /silo-root -maxdepth 5 -type f -perm /111 -name 'silo*' | head -n1); \
    [ -n "$bin" ] || { echo "could not find the silo/minio binary in the silo image"; find /silo-root -maxdepth 3 -type f -perm /111 | head -50; exit 1; }; \
    echo "using $bin"; \
    install -D "$bin" /out/silo

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
        postgresql-15 nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

COPY --from=silo-bin /out/silo /usr/local/bin/silo
COPY --from=img-museum  / /opt/rootfs/museum/
COPY --from=img-web     / /opt/rootfs/web/
COPY --from=img-mailpit / /opt/rootfs/mailpit/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="ente-minio" \
      org.opencontainers.image.description="Ente - Silo S3 in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080 8081 8082 8083
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/ping || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
