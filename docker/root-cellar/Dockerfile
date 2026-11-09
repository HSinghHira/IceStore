# syntax=docker/dockerfile:1.7
#
# Root Cellar for IceStore: its four household apps (Checkbook, Notes, Movies,
# Labels) in one container, started by supervisord, each on its own port as
# upstream runs them. Upstream's compose file runs each app's source folder in
# a stock node image; here the folders come from one release tag, with the
# Labels print system (CUPS and the DYMO drivers) installed in the image
# instead of on first start.
#
# To update, change RC_REF below (and x-casaos.version in the compose file),
# bump AIO_VERSION in build-root-cellar.yml and rebuild.

ARG RC_REF=v1.0.0

FROM node:22.23.4-trixie-slim
ARG RC_REF
ENV DEBIAN_FRONTEND=noninteractive NODE_ENV=production

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        supervisor curl ca-certificates tzdata \
        cups cups-client cups-filters printer-driver-dymo \
        python3 make g++; \
    rm -rf /var/lib/apt/lists/*

ADD https://github.com/Noobie3DPrinting/root-cellar/archive/refs/tags/${RC_REF}.tar.gz /tmp/rc.tar.gz
RUN set -eux; \
    mkdir -p /tmp/src /app; \
    tar -xzf /tmp/rc.tar.gz -C /tmp/src --strip-components=1; \
    cp -a /tmp/src/server/checkbook /tmp/src/server/notes /tmp/src/server/movies /tmp/src/server/labels /app/; \
    cp /tmp/src/LICENSE.txt /tmp/src/THIRD-PARTY-NOTICES.txt /app/; \
    cd /app/checkbook; npm ci --omit=dev --ignore-scripts=false --no-audit --no-fund --loglevel=error; \
    rm -rf /tmp/src /tmp/rc.tar.gz /root/.npm /var/lib/apt/lists/*; \
    test -f /app/checkbook/src/server.js; test -f /app/notes/server.js; \
    test -f /app/movies/server.js; test -f /app/labels/server.js; \
    cp -a /etc/cups /etc/cups.default

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="root-cellar" \
      org.opencontainers.image.description="Root Cellar household apps (Checkbook, Notes, Movies, Labels) in one container" \
      org.opencontainers.image.version="${RC_REF}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080 8085 8093 8095
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/ || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
