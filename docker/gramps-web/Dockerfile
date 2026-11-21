# syntax=docker/dockerfile:1.7
#
# Gramps Web, as upstream ships it, plus Redis (Debian's redis-server) and
# supervisord, so the three containers of upstream's compose file (web,
# Celery worker, Redis) run in one. One IceStore start script puts every
# data folder under /data and keeps the Flask secret there (upstream's
# entrypoint makes it on first start).
#
# Gramps Web asks for the owner account on its first page.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/gramps-project/grampsweb:26.11.3

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends redis-server supervisor curl \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="gramps-web" \
      org.opencontainers.image.description="Gramps Web with its Celery worker and Redis in one container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:5000/ || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
