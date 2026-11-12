# syntax=docker/dockerfile:1.7
#
# OpenSignup for IceStore, in one container. Upstream publishes no image and
# no releases, so this builds upstream's Dockerfile steps from one pinned
# commit of github.com/richshaw/OpenSignup, and adds what its
# docker-compose.prod.yml runs beside it:
#
#   postgres  PostgreSQL 16 (upstream's compose uses postgres:16-alpine)
#   web       the Next.js server (runs the database migrations first)
#   worker    the reminder / slot-change email worker (pg-boss)
#   mailpit   a mail viewer at /mail: organizers sign in by emailed link,
#             so until you set SMTP the emails land here
#   gateway   nginx on 8080 (and the PUBLIC_URL port)
#
# Upstream bakes NEXT_PUBLIC_* values into the build. They are built here as
# placeholder words and filled in on every start by fill-public.mjs, so the
# site name, support email, legal text and public address are app settings.
#
# To update, change OPENSIGNUP_REF below (and x-casaos.version in the compose
# file), bump AIO_VERSION in build-opensignup.yml and rebuild.

ARG OPENSIGNUP_REF=66294005d715611729e574ad5de4227cc3703935

# auto-update: keep-major
FROM node:22.22.3-alpine3.22
ARG OPENSIGNUP_REF

RUN set -eux; \
    apk add --no-cache bash sed curl openssl tzdata setpriv postgresql16 postgresql16-client nginx supervisor; \
    addgroup -S -g 1001 signup; adduser -S -u 1001 -G signup -h /app signup

# The mail viewer: one static binary from the mailpit image.
COPY --from=axllent/mailpit:v1.33.1 /mailpit /usr/local/bin/mailpit

# ---- upstream's Dockerfile (deps, builder, runner), from the pinned commit ----
ENV COREPACK_HOME=/usr/local/share/corepack NEXT_TELEMETRY_DISABLED=1
RUN corepack enable && corepack prepare pnpm@9.15.9 --activate
ADD https://github.com/richshaw/OpenSignup/archive/${OPENSIGNUP_REF}.tar.gz /tmp/opensignup.tar.gz
RUN set -eux; \
    mkdir -p /app /opt/run /opt/opensignup; \
    tar -xzf /tmp/opensignup.tar.gz -C /app --strip-components=1; \
    cd /app; \
    pnpm install --frozen-lockfile; \
    NODE_ENV=production \
    GIT_COMMIT_SHA=${OPENSIGNUP_REF} \
    NEXT_PUBLIC_INSTANCE_NAME=IcestoreOpenSignupInstanceName \
    NEXT_PUBLIC_SUPPORT_EMAIL=support@icestore-opensignup-support.invalid \
    NEXT_PUBLIC_SOURCE_URL=https://github.com/richshaw/OpenSignup \
    NEXT_PUBLIC_GOVERNING_LAW=IcestoreOpenSignupGoverningLaw \
    NEXT_PUBLIC_OPERATOR_NAME=IcestoreOpenSignupOperatorName \
    NEXT_PUBLIC_APP_URL=http://icestore-opensignup-app-url.invalid \
    pnpm build; \
    # Built in /app like upstream; the runner stage's files are put together
    # in /opt/run and take /app's place.
    cp -a .next/standalone/. /opt/run/; \
    cp -a .next/static /opt/run/.next/static; \
    cp -a public src drizzle.config.ts tsconfig.json tsconfig.worker.json package.json /opt/run/; \
    rm -rf /opt/run/node_modules; \
    mv node_modules /opt/run/node_modules; \
    mv /opt/run/.next /opt/opensignup/next; \
    cd /; rm -rf /app /tmp/opensignup.tar.gz /root/.cache /root/.local/share/pnpm; \
    mv /opt/run /app; \
    chown -R signup:signup /app

WORKDIR /app
ENV NODE_ENV=production NEXT_PUBLIC_SOURCE_URL=https://github.com/richshaw/OpenSignup \
    GIT_COMMIT_SHA=${OPENSIGNUP_REF}

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/opensignup-svc
COPY fill-public.mjs /opt/opensignup/fill-public.mjs
COPY supervisord.conf /etc/supervisor/icestore.conf
COPY nginx.conf.tpl /etc/nginx/icestore.conf.tpl
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/opensignup-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="opensignup" \
      org.opencontainers.image.description="OpenSignup sign-up sheets, built from upstream source, with PostgreSQL, the email worker and a mail viewer inside" \
      org.opencontainers.image.version="${OPENSIGNUP_REF}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/api/public/health || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
