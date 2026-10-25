# syntax=docker/dockerfile:1.7
#
# Stoat Chat all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# The weekly bumper (update-upstream.yml) keeps the FROM lines current.
# Upstream's self-hosted compose: https://github.com/stoatchat/self-hosted
#
# Services inside:
#   redis      built-in (Debian redis-server; upstream uses Valkey, same protocol)
#   mongo      chroot   (MongoDB, upstream's database)
#   rabbit     chroot   (RabbitMQ, upstream's message broker)
#   silo       built-in (the Silo binary, extracted from pgsty/silo; S3 file storage)
#   s3init     built-in (one-off: creates the revolt-uploads bucket)
#   api        chroot   (revolt-delta, the API)
#   events     chroot   (revolt-bonfire, the websocket)
#   autumn     chroot   (revolt-autumn, file uploads)
#   january    chroot   (revolt-january, link previews and image proxy)
#   gifbox     chroot   (revolt-gifbox, the GIF picker proxy)
#   crond      chroot   (revolt-crond, cleanup jobs)
#   pushd      chroot   (revolt-pushd, push notifications)
#   voice      chroot   (revolt-voice-ingress, voice call events from LiveKit)
#   livekit    chroot   (LiveKit, voice and video)
#   gateway    built-in (nginx on 8080: the web app's files plus upstream's
#                        Caddyfile routes)
#
# The web app is static files (upstream serves them with a small Node
# server); they are copied out of the for-web image and served by nginx.

FROM ghcr.io/stoatchat/api:v0.16.2 AS img-api
FROM ghcr.io/stoatchat/events:v0.16.2 AS img-events
FROM ghcr.io/stoatchat/file-server:v0.16.2 AS img-autumn
FROM ghcr.io/stoatchat/proxy:v0.16.2 AS img-january
FROM ghcr.io/stoatchat/gifbox:v0.16.2 AS img-gifbox
FROM ghcr.io/stoatchat/crond:v0.16.2 AS img-crond
FROM ghcr.io/stoatchat/pushd:v0.16.2 AS img-pushd
FROM ghcr.io/stoatchat/voice-ingress:v0.16.2 AS img-voice
FROM ghcr.io/stoatchat/livekit-server:v1.9.14 AS img-livekit
# Upstream pins mongo:8 "until 9 is supported".
# auto-update: keep-major
FROM mongo:8.3.13 AS img-mongo
# auto-update: keep-major
FROM rabbitmq:4.4.0 AS img-rabbit
FROM pgsty/silo:RELEASE.2026-10-18T00-00-00Z AS img-silo

# for-web is tagged by git commit (607a0ce = stoat-for-web v0.16.2), and its
# CI pushes some commits for one architecture only. The files are the same
# on every architecture, so the amd64 image is used for both builds.
# auto-update: hold
FROM --platform=linux/amd64 ghcr.io/stoatchat/for-web:607a0ce AS web-dist

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
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl redis-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

COPY --from=silo-bin /out/silo /usr/local/bin/silo

# Chroot services: the whole upstream filesystems.
COPY --from=img-api     / /opt/rootfs/api/
COPY --from=img-events  / /opt/rootfs/events/
COPY --from=img-autumn  / /opt/rootfs/autumn/
COPY --from=img-january / /opt/rootfs/january/
COPY --from=img-gifbox  / /opt/rootfs/gifbox/
COPY --from=img-crond   / /opt/rootfs/crond/
COPY --from=img-pushd   / /opt/rootfs/pushd/
COPY --from=img-voice   / /opt/rootfs/voice/
COPY --from=img-livekit / /opt/rootfs/livekit/
COPY --from=img-mongo   / /opt/rootfs/mongo/
COPY --from=img-rabbit  / /opt/rootfs/rabbit/

# The web app, built with placeholders that aio-init fills in on every start.
COPY --from=web-dist /app/dist /opt/stoat-web/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="stoatchat" \
      org.opencontainers.image.description="Stoat Chat (formerly Revolt) in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080 6168 6169/udp
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=240s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/ || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
