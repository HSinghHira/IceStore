# syntax=docker/dockerfile:1.7
#
# TutorLoom all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
#
# Upstream publishes no image, so it is built here from one pinned release of
# github.com/pacewisdomhq/TutorLoom, the way upstream's Dockerfile and
# frontend/Dockerfile do. To update, change TUTORLOOM_VERSION below (and
# x-casaos.version in the compose file) and rebuild.
#
# Services inside:
#   postgres  built-in (PGDG postgresql-16, same major as upstream's postgres:16)
#   redis     built-in (Debian redis-server; cache and Celery broker)
#   api       chroot   (Django API under gunicorn; runs migrations first)
#   worker    chroot   (Celery worker; same filesystem as api)
#   setup     built-in (one-off: first organization, batch and admin account)
#   gateway   built-in (nginx on 8080: the web app, /api, /admin, /static, /media)

ARG TUTORLOOM_VERSION=v1.0.0

# The Python upstream's Dockerfile uses (python:3.14-slim). A newer Python
# needs wheels for every requirement, so it is moved by hand.
# auto-update: hold
FROM python:3.14.10-slim AS img-api

# ---- the source, at the pinned release ----
FROM debian:trixie-slim AS src
ARG TUTORLOOM_VERSION
ADD https://github.com/pacewisdomhq/TutorLoom/archive/refs/tags/${TUTORLOOM_VERSION}.tar.gz /tmp/src.tar.gz
RUN set -eux; \
    mkdir -p /src; \
    tar -xzf /tmp/src.tar.gz -C /src --strip-components=1; \
    test -f /src/manage.py; \
    test -f /src/frontend/package-lock.json

# ---- the web app (upstream's frontend/; plain files, so built once on the
# ---- build machine for every platform). /api on the same address, so it
# ---- works from any address the browser uses.
# auto-update: hold
FROM --platform=$BUILDPLATFORM node:22.23.4-slim AS web-build
COPY --from=src /src/frontend /frontend
WORKDIR /frontend
ENV VITE_API_BASE_URL=/api
RUN npm ci --no-audit --no-fund && npm run build && test -f dist/index.html

# ---- the API filesystem (upstream's Dockerfile) ----
FROM img-api AS api-rootfs
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends libpq-dev gcc pkg-config libcairo2-dev; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd --system app; \
    useradd --system --create-home --gid app app
WORKDIR /app
COPY --from=src /src/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY --from=src /src/LICENSE /src/NOTICE /src/manage.py /app/
COPY --from=src /src/lms_core /app/lms_core
COPY --from=src /src/accounts /app/accounts
COPY --from=src /src/analytics /app/analytics
COPY --from=src /src/curriculum /app/curriculum
COPY --from=src /src/gamification /app/gamification
COPY --from=src /src/organizations /app/organizations
COPY --from=src /src/rbac /app/rbac
COPY --from=src /src/settings /app/settings
# Django admin and Swagger files, served by nginx at /static/. The settings
# need these values to load; nothing connects to them here.
RUN set -eux; \
    SECRET_KEY=build DB_HOST=127.0.0.1 REDIS_URL=redis://127.0.0.1:6379/1 \
      CELERY_BROKER_URL=redis://127.0.0.1:6379/0 DEBUG=False \
      python manage.py collectstatic --noinput >/dev/null; \
    test -d /app/staticfiles/admin; \
    mkdir -p /app/media; \
    chown -R app:app /app/staticfiles /app/media

# ---- the final image ----
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    mkdir -p /etc/postgresql-common; echo 'create_main_cluster = false' > /etc/postgresql-common/createcluster.conf; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    install -d /usr/share/keyrings; \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt trixie-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        postgresql-16 redis-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# Chroot services: api and worker share one filesystem.
COPY --from=api-rootfs / /opt/rootfs/api/
COPY --from=web-build /frontend/dist/ /opt/tutorloom-web/

COPY meta/ /opt/meta/
# The Python image's own start command is just "python3". Run TutorLoom as
# upstream's image does: in /app, as the "app" user (the commands are set in
# run-svc.sh).
RUN set -eux; \
    jq '.Entrypoint = [] | .Cmd = [] | .WorkingDir = "/app" | .User = "app" \
        | .Env += ["PYTHONUNBUFFERED=1", "DJANGO_SETTINGS_MODULE=lms_core.settings"]' \
      /opt/meta/api.json > /tmp/api.json; \
    mv /tmp/api.json /opt/meta/api.json; \
    cp /opt/meta/api.json /opt/meta/worker.json
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="tutorloom" \
      org.opencontainers.image.description="TutorLoom (Django API, Celery worker, web app, PostgreSQL and Redis) in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/admin/login/ || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
