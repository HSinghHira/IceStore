# syntax=docker/dockerfile:1.7
#
# SiteWatcher, as upstream publishes it, run as one container: supervisord
# starts the web dashboard and the check worker (upstream runs them as two
# services from this same image). The IceStore start script creates the
# owner account with a password made for each install, because upstream's
# `sitewatcher setup` needs a terminal.
#
# Upstream only publishes sha-<commit> tags (no version tags and no latest),
# so the bumper cannot follow it: move the tag below by hand.

FROM ghcr.io/nikkurkov/sitewatcher:sha-e2bae0f9da05bd91d695c6a6b8fb5241c37a5fc5

USER root
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends supervisor util-linux; \
    rm -rf /var/lib/apt/lists/*

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY owner.py /usr/local/lib/icestore/sitewatcher-owner.py
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

ENV DATABASE_PATH=/data/sitewatcher.db XDG_CACHE_HOME=/data/cache SITEWATCHER_WEB_BIND=0.0.0.0

LABEL org.opencontainers.image.title="sitewatcher" \
      org.opencontainers.image.description="SiteWatcher web and worker in one container, with a per-install owner login" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD python -c 'import urllib.request; urllib.request.urlopen("http://127.0.0.1:8080/healthz", timeout=3)' || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
