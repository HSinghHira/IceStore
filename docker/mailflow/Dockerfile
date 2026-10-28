# syntax=docker/dockerfile:1.7
#
# MailFlow all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# To bump a version, change the tags on the FROM lines below and rebuild.
#
# Services inside:
#   postgres  built-in (PostgreSQL 16, as in upstream's compose)
#   redis     built-in (sessions and cache)
#   backend   chroot   (ghcr.io/maathimself/mailflow-backend: Node API on 127.0.0.1:3000)
#   gateway   built-in (nginx on 8080: serves the web app and proxies /api, /ws,
#                       /oauth, /auth/oidc and /carddav to the backend)
#
# Upstream's frontend image is nginx plus the built React app. Only the built
# files are taken from it; the gateway serves them, so there is one nginx, not two.
# Keep both tags the same: frontend and backend are released together.

FROM ghcr.io/maathimself/mailflow-backend:4.1.0 AS img-backend
FROM ghcr.io/maathimself/mailflow-frontend:4.1.0 AS web-dist

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

# Chroot service: the whole backend image (Node 22 on Alpine).
COPY --from=img-backend / /opt/rootfs/backend/

# The built web app, served by the gateway.
COPY --from=web-dist /usr/share/nginx/html/ /srv/mailflow-web/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="mailflow" \
      org.opencontainers.image.description="MailFlow webmail (API, web app, PostgreSQL and Redis) in a single container" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
