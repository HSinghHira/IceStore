# syntax=docker/dockerfile:1.7
#
# TEF Notes all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# Shared files come from docker/_common, so build with:
#   docker buildx build --build-context common=docker/_common docker/tef-notes
# The weekly bumper (update-upstream.yml) keeps the FROM lines current.
#
# Services inside (from upstream's server/docker-compose.yml):
#   pocketbase  chroot   (PocketBase with the hooks, migrations and web app, on 8090)
#   agent       chroot   (the AI agent on 8098, under /agent)
#   stt         chroot   (speech-to-text for voice input, on 8099)
#   gateway     built-in (nginx on 8080: upstream's one-origin proxy rule)

FROM ghcr.io/spyrosbazios/tef-notes:0.8.0 AS img-pocketbase
FROM ghcr.io/spyrosbazios/tef-notes-agent:0.8.0 AS img-agent
FROM ghcr.io/spyrosbazios/tef-notes-stt:0.8.0 AS img-stt

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystems.
COPY --from=img-pocketbase / /opt/rootfs/pocketbase/
COPY --from=img-agent      / /opt/rootfs/agent/
COPY --from=img-stt        / /opt/rootfs/stt/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="tef-notes" \
      org.opencontainers.image.description="TEF Notes (PocketBase, agent and speech-to-text) in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
