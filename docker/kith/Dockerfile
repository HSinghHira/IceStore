# syntax=docker/dockerfile:1.7
#
# Kith for IceStore, in one container: the site (gunicorn, as upstream's
# docker/Dockerfile builds it from one release tag), MariaDB 11.8 (the
# version upstream's compose file uses) and the scheduled jobs, started by
# supervisord. Upstream publishes no image.
#
# To update, change KITH_REF below (and x-casaos.version in the compose
# file), bump AIO_VERSION in build-kith.yml and rebuild. Database upgrades
# run as the site starts.

ARG KITH_REF=v0.4.5

FROM python:3.13.18-slim-trixie
ARG KITH_REF
ENV DEBIAN_FRONTEND=noninteractive PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

RUN set -eux; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    apt-get update; \
    apt-get install -y --no-install-recommends mariadb-server poppler-utils supervisor curl ca-certificates openssl tzdata procps; \
    rm -rf /var/lib/apt/lists/* /var/lib/mysql/*

# ---- upstream's docker/Dockerfile, from the release tarball ----
ADD https://github.com/dreed47/kith/archive/refs/tags/${KITH_REF}.tar.gz /tmp/kith.tar.gz
RUN set -eux; \
    mkdir -p /tmp/src /app; \
    tar -xzf /tmp/kith.tar.gz -C /tmp/src --strip-components=1; \
    cd /tmp/src; \
    pip install --no-cache-dir -r deploy/requirements.txt gunicorn==23.0.0; \
    cp -a app themes pyproject.toml LICENSE /app/; \
    rm -rf /tmp/src /tmp/kith.tar.gz /root/.cache; \
    chmod -R a+rX /app; \
    useradd --system --home /app kith

WORKDIR /app
ENV KITH_MEDIA_ROOT=/data/media KITH_INSTANCE=/data/instance KITH_STRONG_PASSWORDS=1 \
    KITH_DB_HOST=127.0.0.1 KITH_DB_PORT=3306 KITH_DB_NAME=kith KITH_DB_USER=kith \
    FLASK_APP=app

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/kith-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/kith-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="kith" \
      org.opencontainers.image.description="Kith family history site, built from upstream source, with MariaDB inside" \
      org.opencontainers.image.version="${KITH_REF}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8000
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8000/ || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
