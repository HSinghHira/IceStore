# syntax=docker/dockerfile:1.7
#
# Ghost all-in-one. CI runs ../_common/capture-meta.sh first (it fills ./meta).
# The daily bumper (update-upstream.yml) moves the tags below.
#
# Services inside:
#   mysql      chroot   (the official mysql image as-is; its entrypoint makes the
#                        database and user on first start. Ghost supports only
#                        MySQL 8 in production)
#   mailpit    chroot   (fallback mail server and viewer at /mail when no SMTP is set)
#   ghost      chroot   (the official ghost image as-is: site, members and admin on 2368)
#   gateway    built-in (nginx on 8080)
#
# Left out: Caddy (TLS), ActivityPub and Tinybird web analytics from upstream's
# ghost-docker compose.

FROM ghost:6.78.0 AS img-ghost
# auto-update: keep-major (MySQL 9 is not supported by Ghost)
FROM mysql:8.4.13 AS img-mysql
FROM axllent/mailpit:v1.34.0 AS img-mailpit

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: the whole upstream filesystems.
COPY --from=img-ghost   / /opt/rootfs/ghost/
COPY --from=img-mysql   / /opt/rootfs/mysql/
COPY --from=img-mailpit / /opt/rootfs/mailpit/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="ghost" \
      org.opencontainers.image.description="Ghost publishing with MySQL in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=240s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/ghost/api/admin/site/ || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
