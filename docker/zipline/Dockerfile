# syntax=docker/dockerfile:1.7
#
# Zipline, as upstream ships it, plus:
#   - PostgreSQL 17 (Alpine's package; upstream's compose file runs
#     postgres:16 as a second container) and supervisord, so the database
#     lives in the same container;
#   - one IceStore start script that gives every install its own CORE_SECRET
#     and database password (made on first start, kept in /data).
#
# Zipline asks for the first admin account on its setup page.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/diced/zipline:4.8.4

USER root
RUN apk add --no-cache postgresql17 postgresql17-contrib supervisor setpriv openssl bash

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/zipline-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/zipline-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="zipline" \
      org.opencontainers.image.description="Zipline with PostgreSQL inside and a per-install secret" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 3000
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD wget -q --spider http://127.0.0.1:3000/api/healthcheck || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
