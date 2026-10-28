# syntax=docker/dockerfile:1.7
#
# PullMD all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# The weekly bumper (update-upstream.yml) keeps the FROM lines current.
#
# Services inside:
#   pullmd       chroot   (the web app, API and MCP server on 3000; cache in /data)
#   trafilatura  chroot   (second HTML extractor on 8001)
#   markitdown   chroot   (PDF, Office, EPUB and YouTube conversion on 8003)
#   gateway      built-in (nginx on 8080)
#
# Left out: the Playwright sidecar (headless Chromium, about 3.7 GB). Without it
# JavaScript-heavy pages fall back to static extraction, as upstream documents.

FROM aeternalabshq/pullmd:3.16.0 AS img-pullmd
FROM aeternalabshq/pullmd-trafilatura:3.16.0 AS img-trafilatura
FROM aeternalabshq/pullmd-markitdown:3.16.0 AS img-markitdown

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystem, one folder each.
COPY --from=img-pullmd / /opt/rootfs/pullmd/
COPY --from=img-trafilatura / /opt/rootfs/trafilatura/
COPY --from=img-markitdown / /opt/rootfs/markitdown/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="pullmd" \
      org.opencontainers.image.description="PullMD in a single container" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/status || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
