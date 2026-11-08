# syntax=docker/dockerfile:1.7
#
# OpenCadence for IceStore.
#
# Upstream publishes no image and no release tags yet, so it is built here
# from one pinned commit of github.com/OpenCadence/opencadence, the same way
# upstream's own Dockerfile does it (pnpm install, Next.js standalone build).
# To update, change CADENCE_REF below (and x-casaos.version in the compose
# file), bump AIO_VERSION in build-opencadence-community.yml and rebuild.
#
# OpenCadence has no login and only answers to localhost. IceStore adds one
# thing in front of it: nginx on 8080 with a password made on first start
# (see icestore-init.sh and nginx.conf).

ARG CADENCE_REF=31b9ba009b09950f0444268acbe4586f02aacd3a

# auto-update: keep-major
FROM node:22.23.4-bookworm-slim
ARG CADENCE_REF
ENV DEBIAN_FRONTEND=noninteractive     COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN set -eux;     apt-get update;     apt-get install -y --no-install-recommends nginx openssl tzdata ca-certificates;     rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/default

# ---- build (upstream's "builder" stage), then keep only what upstream's
# ---- "runner" stage keeps, all in one layer ----
ADD https://github.com/OpenCadence/opencadence/archive/${CADENCE_REF}.tar.gz /tmp/src.tar.gz
RUN set -eux;     mkdir -p /tmp/src;     tar -xzf /tmp/src.tar.gz -C /tmp/src --strip-components=1;     cd /tmp/src;     corepack enable pnpm;     pnpm install --frozen-lockfile;     NEXT_TELEMETRY_DISABLED=1 CADENCE_STANDALONE=1 pnpm build;     test -f .next/standalone/server.js;     mkdir -p /app/.next /app/scripts /app/node_modules/@next;     cp -a .next/standalone/. /app/;     cp -a .next/static /app/.next/static;     cp -a public /app/public;     cp scripts/backup.mjs /app/scripts/backup.mjs;     rm -rf /app/node_modules/@next/env;     cp -a node_modules/@next/env /app/node_modules/@next/env;     cp LICENSE NOTICE THIRD_PARTY_NOTICES.md /app/;     cd /app;     rm -rf node_modules/sharp node_modules/@img node_modules/.pnpm/sharp@* node_modules/.pnpm/@img+sharp*;     rm -rf /tmp/src /tmp/src.tar.gz /root/.cache /root/.local/share/pnpm;     install -d -m 0700 /app/data;     chown -R node:node /app

WORKDIR /app
ENV NODE_ENV=production     NEXT_TELEMETRY_DISABLED=1     HOSTNAME=127.0.0.1     PORT=3000     DATABASE_PATH=/app/data/cadence.sqlite

COPY nginx.conf /etc/nginx/icestore.conf
COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="opencadence-community" \
      org.opencontainers.image.description="OpenCadence, built from upstream source, with a password in front" \
      org.opencontainers.image.version="${CADENCE_REF}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/api/revision').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"]

ENTRYPOINT ["/usr/local/bin/icestore-init"]
