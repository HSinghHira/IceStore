# syntax=docker/dockerfile:1.7
#
# kovi for IceStore. Upstream (git.sysmd.uk/mdaleo404/kovi) publishes no
# image; this is its own Dockerfile built from one release tag: Node 22,
# Debian's Calibre for cover lookups, and kovi's files (it has no npm
# dependencies). One start script gives the data folder to the node user.
#
# To update, change KOVI_REF below (and x-casaos.version in the compose
# file), bump AIO_VERSION in build-kovi.yml and rebuild.

ARG KOVI_REF=2026.10.09

# auto-update: keep-major
FROM node:22.23.4-trixie-slim
ARG KOVI_REF

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends calibre ca-certificates curl; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack \
           /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
           /usr/local/bin/yarn /usr/local/bin/yarnpkg /usr/local/bin/pnpm

ADD https://git.sysmd.uk/mdaleo404/kovi/archive/${KOVI_REF}.tar.gz /tmp/kovi.tar.gz
RUN set -eux; \
    mkdir -p /tmp/src /app; \
    tar -xzf /tmp/kovi.tar.gz -C /tmp/src --strip-components=1; \
    cd /tmp/src; \
    cp -a package.json server.mjs lib public plugins LICENSE /app/; \
    rm -rf /tmp/src /tmp/kovi.tar.gz; \
    mkdir -p /app/data/uploads /app/data/covers; \
    chown -R node:node /app

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="kovi" \
      org.opencontainers.image.description="kovi ${KOVI_REF}, built from upstream's release" \
      org.opencontainers.image.version="${KOVI_REF}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENV HOST=0.0.0.0 PORT=3000 DATA_PATH=/app/data TZ=UTC CALIBRE_COVER_RESOLVER=auto
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:3000/ || exit 1
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["node", "server.mjs"]
