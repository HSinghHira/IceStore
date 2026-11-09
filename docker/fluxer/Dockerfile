# syntax=docker/dockerfile:1.7
#
# Fluxer all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# Shared files come from docker/_common, so build with:
#   docker buildx build --build-context common=docker/_common docker/fluxer
# The weekly bumper (update-upstream.yml) keeps the FROM lines current.
# Upstream's compose bundle: the fluxer-compose-<version>.tar.gz asset of
# each fluxer-release on https://github.com/fluxerapp/fluxer/releases
#
# Services inside (upstream's compose service name in brackets):
#   postgres     built-in (PGDG postgresql-16, same major as upstream's postgres:16-alpine)
#   valkey       built-in (Debian valkey-server)
#   nats         chroot   (NATS with JetStream, the message bus between services)
#   meilisearch  chroot   (search)
#   seaweedfs    chroot   (S3 file storage: uploads, avatars, emoji)
#   s3init       built-in (one-off: makes the buckets) [seaweedfs-init]
#   livekit      chroot   (voice and video)
#   snowflakes   chroot   (id service)
#   users        chroot   (user storage service)
#   gifs         chroot   (GIF search service)
#   messages     chroot   (message storage service)
#   unfurl       chroot   (link previews)
#   api          chroot   (the API, Node)
#   worker       chroot   (background jobs; the api image with another command,
#                          run from the api's files, so they are stored once)
#   realtime     chroot   (the Erlang websocket gateway) [gateway]
#   media        chroot   (media proxy: uploads, thumbnails) [media-proxy]
#   push         chroot   (push notifications)
#   app          chroot   (serves the web app) [app-proxy]
#   admin        chroot   (admin panel)
#   gateway      built-in (nginx on 8080: upstream's edge Caddyfile routes, and
#                          the static files of fluxer-static) [edge, static-proxy]
#
# Every Fluxer image is versioned on its own (year.monthday.build). The
# release's compose file pins them by digest; these are the same images.

FROM ghcr.io/fluxerapp/fluxer-api:2026.1109.42841 AS img-api
FROM ghcr.io/fluxerapp/fluxer-gateway:2026.1109.42842 AS img-realtime
FROM ghcr.io/fluxerapp/fluxer-media-proxy:2026.1109.42917 AS img-media
FROM ghcr.io/fluxerapp/fluxer-push:2026.1109.42836 AS img-push
FROM ghcr.io/fluxerapp/fluxer-app-proxy-self-hosted:2026.1109.42903 AS img-app
FROM ghcr.io/fluxerapp/fluxer-admin:2026.1109.42815 AS img-admin
FROM ghcr.io/fluxerapp/fluxer-snowflakes:2026.1109.42849 AS img-snowflakes
FROM ghcr.io/fluxerapp/fluxer-users:2026.1109.42852 AS img-users
FROM ghcr.io/fluxerapp/fluxer-gifs:2026.1109.42837 AS img-gifs
FROM ghcr.io/fluxerapp/fluxer-messages:2026.1109.42854 AS img-messages
FROM ghcr.io/fluxerapp/fluxer-unfurl:2026.1109.42918 AS img-unfurl
FROM livekit/livekit-server:v1.12.0 AS img-livekit
FROM getmeili/meilisearch:v1.53 AS img-meilisearch
FROM chrislusf/seaweedfs:4.52 AS img-seaweedfs
FROM nats:2.14.9-alpine AS img-nats

# fluxer-static is only files (avatars, emoji, web assets); nginx serves them.
FROM ghcr.io/fluxerapp/fluxer-static:2026.1109.42914 AS static-files

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
        postgresql-16 valkey-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystems.
COPY --from=img-api         / /opt/rootfs/api/
COPY --from=img-realtime    / /opt/rootfs/realtime/
COPY --from=img-media       / /opt/rootfs/media/
COPY --from=img-push        / /opt/rootfs/push/
COPY --from=img-app         / /opt/rootfs/app/
COPY --from=img-admin       / /opt/rootfs/admin/
COPY --from=img-snowflakes  / /opt/rootfs/snowflakes/
COPY --from=img-users       / /opt/rootfs/users/
COPY --from=img-gifs        / /opt/rootfs/gifs/
COPY --from=img-messages    / /opt/rootfs/messages/
COPY --from=img-unfurl      / /opt/rootfs/unfurl/
COPY --from=img-livekit     / /opt/rootfs/livekit/
COPY --from=img-meilisearch / /opt/rootfs/meilisearch/
COPY --from=img-seaweedfs   / /opt/rootfs/seaweedfs/
COPY --from=img-nats        / /opt/rootfs/nats/

COPY --from=static-files /srv/fluxer-static /opt/fluxer-static/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh \
    && chmod -R a+rX /opt/fluxer-static

LABEL org.opencontainers.image.title="fluxer" \
      org.opencontainers.image.description="Fluxer chat and voice in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080 6693 6694/udp
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/_health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
