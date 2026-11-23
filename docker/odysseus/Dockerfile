# syntax=docker/dockerfile:1.7
#
# Odysseus all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# The daily bumper (update-upstream.yml) moves the tags below.
#
# Services inside:
#   chromadb   chroot   (chromadb/chroma: vectors for memory and document search, on 8000)
#   searxng    chroot   (searxng/searxng: private web search for research, on 8888)
#   odysseus   chroot   (the upstream image as-is: web UI and API on 7000)
#   gateway    built-in (nginx on 8080)
#
# Left out: ntfy (push notifications) and the GPU / host-Docker overlays.

FROM ghcr.io/odysseus-dev/odysseus:1.0.3 AS img-odysseus
FROM chromadb/chroma:1.5.9 AS img-chromadb
FROM searxng/searxng:2026.10.24-ef0ec03da AS img-searxng

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystems.
COPY --from=img-odysseus / /opt/rootfs/odysseus/
COPY --from=img-chromadb / /opt/rootfs/chromadb/
COPY --from=img-searxng  / /opt/rootfs/searxng/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="odysseus" \
      org.opencontainers.image.description="Odysseus AI workspace with ChromaDB and SearXNG in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=240s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
