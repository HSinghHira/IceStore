# syntax=docker/dockerfile:1.7
#
# tududi, as upstream ships it, plus:
#   - PostgreSQL 16 (Alpine's package, the major upstream's compose file
#     uses) and supervisord, so the database upstream runs as a second
#     container lives in the same one;
#   - one IceStore start script that gives every install its own session
#     secret, database password and admin password (made on first start,
#     kept in /data) and prints the login in a CREDENTIALS box.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM chrisvel/tududi:2.1.1

USER root
RUN apk add --no-cache postgresql16 postgresql16-contrib postgresql16-client supervisor setpriv openssl tzdata

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/tududi-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/tududi-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="tududi" \
      org.opencontainers.image.description="tududi with PostgreSQL inside and a per-install session secret and admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 3002
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1:3002/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
