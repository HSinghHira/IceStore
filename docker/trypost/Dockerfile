# syntax=docker/dockerfile:1.7
#
# TryPost all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# Shared files come from docker/_common, so build with:
#   docker buildx build --build-context common=docker/_common docker/trypost
# To bump a version, change the tag on the FROM line below and rebuild.
#
# Services inside:
#   postgres   built-in (PGDG postgresql-16, same major as upstream's postgres:16-alpine)
#   redis      built-in (queue, cache and Horizon)
#   trypost    chroot   (the upstream image as-is: its entrypoint runs the
#                        migrations, then its own supervisord starts php-fpm,
#                        nginx on 80, Reverb, Horizon and the scheduler)
#   admin      built-in one-off: makes the first account (self-hosted
#                        TryPost has no open sign-up)
#   gateway    built-in (nginx on 8080)

FROM ghcr.io/trypostit/trypost:2.0.1 AS img-trypost

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
        postgresql-16 redis-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot service: the whole upstream filesystem (PHP, nginx, the app).
COPY --from=img-trypost / /opt/rootfs/trypost/

# Two changes to the upstream files, nothing else:
#  1. Reverb (websockets) moves from 8080 to 8081, because 8080 is the
#     gateway's port. Upstream's nginx proxies /app/ and /apps/ to it.
#  2. The browser bundle has the websocket address baked in at build time
#     (localhost:8080). It now uses the address the page was opened on, so
#     live updates work from every device and behind https.
RUN set -eu; r=/opt/rootfs/trypost; \
    sed -i 's/--port=8080/--port=8081/' "$r/etc/supervisor/conf.d/supervisord.conf"; \
    sed -i 's#127\.0\.0\.1:8080#127.0.0.1:8081#g' "$r/etc/nginx/http.d/default.conf"; \
    grep -q -- '--port=8081' "$r/etc/supervisor/conf.d/supervisord.conf"; \
    grep -q '127.0.0.1:8081' "$r/etc/nginx/http.d/default.conf"; \
    n=0; \
    for f in "$r"/var/www/html/public/build/assets/*.js; do \
      if grep -q 'wsHost:`localhost`,wsPort:`8080`' "$f"; then \
        sed -i 's/wsHost:`localhost`,wsPort:`8080`,wssPort:`8080`,forceTLS:!1/wsHost:location.hostname,wsPort:location.port||80,wssPort:location.port||443,forceTLS:location.protocol===`https:`/g' "$f"; \
        n=$((n + 1)); \
      fi; \
    done; \
    if [ "$n" = 0 ]; then echo "WARNING: websocket address not found in the TryPost bundle; live updates only work on localhost"; fi

COPY create-admin.php /opt/rootfs/trypost/usr/local/share/icestore/create-admin.php

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="trypost" \
      org.opencontainers.image.description="TryPost social media scheduler in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=240s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/up || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
