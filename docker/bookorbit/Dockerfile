# syntax=docker/dockerfile:1.7
#
# BookOrbit all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# To bump a version, change the tag on the FROM line below and rebuild.
#
# Services inside:
#   postgres   built-in (PGDG postgresql-18 + pgvector, same as upstream's pgvector/pgvector:pg18)
#   bookorbit  chroot   (the upstream Node/Alpine image as-is, with its own entrypoint)
#   gateway    built-in (nginx on 8080)
#
# Left out: the optional Kokoro text-to-speech container (upstream's "tts" profile).

FROM ghcr.io/bookorbit/bookorbit:3.5.0 AS img-bookorbit

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

# Chroot service: the whole upstream filesystem (Node, ffmpeg, poppler, Python venv on Alpine).
COPY --from=img-bookorbit / /opt/rootfs/bookorbit/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="bookorbit" \
      org.opencontainers.image.description="BookOrbit in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/v1/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
