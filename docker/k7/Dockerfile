# syntax=docker/dockerfile:1.7
#
# K7 all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# Shared files come from docker/_common, so build with:
#   docker buildx build --build-context common=docker/_common docker/k7
# To bump a version, change the tag on the FROM line below and rebuild.
#
# Services inside:
#   postgres   built-in (PGDG postgresql-18, same major as upstream's postgres:18-alpine)
#   k7         chroot   (the upstream .NET image as-is: Ubuntu noble, ffmpeg,
#                        VAAPI drivers; its entrypoint drops to appuser via gosu)
#   gateway    built-in (nginx on 8080)

FROM ghcr.io/kaybi-gh/k7:1.17.2 AS img-k7

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
        postgresql-18 nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot service: the whole upstream filesystem (.NET runtime, ffmpeg, /k7).
COPY --from=img-k7 / /opt/rootfs/k7/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="k7" \
      org.opencontainers.image.description="K7 media server in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/alive || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
