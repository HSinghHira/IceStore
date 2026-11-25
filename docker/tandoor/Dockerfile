# syntax=docker/dockerfile:1.7
#
# Tandoor Recipes, as upstream ships it, plus:
#   - PostgreSQL 17 (Alpine's package; upstream's compose file runs
#     postgres:16 as a second container) and supervisord, so the database
#     lives in the same container;
#   - one IceStore start script that gives every install its own SECRET_KEY
#     and database password (made on first start, kept in /data).
#
# Tandoor asks for the first admin account on its setup page.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM vabene1111/recipes:2.7.8

USER root
RUN apk add --no-cache postgresql17 postgresql17-contrib supervisor setpriv openssl tzdata bash curl

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/tandoor-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/tandoor-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="tandoor" \
      org.opencontainers.image.description="Tandoor Recipes with PostgreSQL inside and a per-install secret key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 80
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:80/accounts/login/ || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/icestore-init"]
CMD []
