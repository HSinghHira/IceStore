# syntax=docker/dockerfile:1.7
#
# Spliit, as upstream ships it, plus:
#   - PostgreSQL 17 (Alpine's package; upstream's compose file runs postgres
#     as a second container) and supervisord, so the database lives in the
#     same container;
#   - one IceStore start script that gives every install its own database
#     password (made on first start, kept in /data).
#
# Spliit has no accounts: each group is shared by its link.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/spliit-app/spliit:1.30.0

USER root
RUN apk add --no-cache postgresql17 postgresql17-contrib supervisor setpriv openssl bash

# Spliit reads its language from a NEXT_LOCALE cookie and loads
# messages/<value>.json without checking it. Browsers share cookies between
# every port of one address, so another app on the same ZimaOS (any
# next-intl app) that sets NEXT_LOCALE=en crashes every Spliit page with
# "Cannot find module '../../messages/en.json'". Give Spliit a cookie of its
# own; grep fails the build if the name ever changes upstream.
RUN files=$(grep -rl NEXT_LOCALE /usr/app/.next) \
 && sed -i 's/NEXT_LOCALE/SPLIIT_LOCALE/g' $files \
 && ! grep -rq NEXT_LOCALE /usr/app/.next

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/spliit-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/spliit-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="spliit" \
      org.opencontainers.image.description="Spliit with PostgreSQL inside and a per-install database password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 3000
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1:3000/ || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
