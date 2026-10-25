# syntax=docker/dockerfile:1.7
#
# Homelable all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# To bump a version, change the tags on the FROM lines below and rebuild
# (keep backend and frontend on the same release).
#
# Services inside:
#   backend   chroot   (the upstream Python image as-is: API, scanner, status checks)
#   gateway   built-in (nginx on 8080: the web app from the frontend image on /,
#                       the API on /api, plus the API docs pages)
#
# The optional MCP server (for AI clients) is left out.

FROM ghcr.io/pouzor/homelable-backend:3.6.0 AS img-backend
FROM ghcr.io/pouzor/homelable-frontend:3.6.0 AS img-frontend

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# apache2-utils: htpasswd, which makes the bcrypt hash of the admin password.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl nginx supervisor jq util-linux procps openssl tzdata apache2-utils; \
    rm -rf /var/lib/apt/lists/*

# Chroot service: the whole backend image (it brings its own nmap and ping).
COPY --from=img-backend / /opt/rootfs/backend/

# The gateway serves the built web app straight from the frontend image.
COPY --from=img-frontend /usr/share/nginx/html/ /srv/homelable-web/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="homelable" \
      org.opencontainers.image.description="Homelable (API and web app) in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/v1/health || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
