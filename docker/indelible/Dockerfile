# syntax=docker/dockerfile:1.7
#
# Indelible all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# To bump a version, change the tags on the FROM lines below and rebuild
# (keep api, worker and renderer on the same release).
#
# Services inside:
#   postgres   built-in (PGDG postgresql-18 with pgvector, as upstream's pgvector/pgvector:pg18)
#   silo       built-in (the Silo binary, extracted from pgsty/silo: S3 storage for archived files)
#   renderer   chroot   (headless Chromium that captures pages that resist plain scraping)
#   api        chroot   (the Rust API, which also serves the web app; makes the bucket first)
#   worker     chroot   (background jobs: imports, feeds, sync, AI)
#   gateway    built-in (nginx on 8080)

FROM ghcr.io/useindelible/ind-api:0.1.1 AS img-api
FROM ghcr.io/useindelible/ind-worker:0.1.1 AS img-worker
FROM ghcr.io/useindelible/ind-renderer:0.1.1 AS img-renderer
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
        postgresql-18 postgresql-18-pgvector nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

COPY --from=silo-bin /out/silo /usr/local/bin/silo

# Chroot services: the whole upstream filesystems.
COPY --from=img-renderer / /opt/rootfs/renderer/
COPY --from=img-api      / /opt/rootfs/api/
COPY --from=img-worker   / /opt/rootfs/worker/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="indelible" \
      org.opencontainers.image.description="Indelible read-it-later library in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
