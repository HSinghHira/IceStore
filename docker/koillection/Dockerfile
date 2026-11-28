# syntax=docker/dockerfile:1.7
#
# Koillection, as upstream ships it, plus PostgreSQL 18 (PGDG) and
# supervisord, so it runs as one container. The IceStore start script keeps
# this install's secrets in /data (database password, APP_SECRET, JWT
# passphrase and keys), which upstream remakes on every start.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM koillection/koillection:1.8.6

USER root
RUN set -eux; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    mkdir -p /etc/postgresql-common; echo 'create_main_cluster = false' > /etc/postgresql-common/createcluster.conf; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    . /etc/os-release; \
    install -d /usr/share/keyrings; \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends postgresql-18 supervisor openssl util-linux procps; \
    apt-get purge -y gnupg; apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/koillection-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/koillection-svc /usr/local/lib/icestore/credentials.sh

ENV DB_DRIVER=pdo_pgsql DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME=koillection DB_USER=koillection DB_VERSION=18

LABEL org.opencontainers.image.title="koillection" \
      org.opencontainers.image.description="Koillection with PostgreSQL inside and per-install secrets" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:80/ || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
