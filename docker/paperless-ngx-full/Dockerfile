# syntax=docker/dockerfile:1.7
#
# Paperless-ngx with everything upstream's docker-compose.postgres-tika.yml
# runs next to it, in one container:
#   - PostgreSQL 18 (PGDG) as the database and Redis (Debian's redis-server)
#     as the task broker, both s6 services next to Paperless's own;
#   - Apache Tika (reads Office files and emails) and Gotenberg (turns them
#     into PDFs with LibreOffice and Chromium), each as the whole upstream
#     image under /opt/rootfs/<name>, started with chroot by an s6 service;
#   - one IceStore start script that gives every install its own
#     PAPERLESS_SECRET_KEY, database password and admin password (made on
#     first start, kept in the data folders) and prints the login in a
#     CREDENTIALS box.
#
# Paperless itself runs exactly as upstream ships it: the start script ends
# with `exec /init`, so s6-overlay is still PID 1.
#
# The weekly bumper (update-upstream.yml) moves the three tags below.
# Paperless-ngx pins Gotenberg 8 and Tika 3 in its own compose files.

# auto-update: keep-major
FROM gotenberg/gotenberg:8.40.0 AS img-gotenberg
# auto-update: keep-major
FROM apache/tika:3.3.3.1 AS img-tika

# The settings each image starts with (its ENV), so the s6 services can start
# Gotenberg and Tika with exactly those, whatever a new release changes.
FROM img-gotenberg AS env-gotenberg
RUN env | grep -Ev '^(HOSTNAME|PWD|SHLVL|_)=' > /tmp/image.env
FROM img-tika AS env-tika
RUN env | grep -Ev '^(HOSTNAME|PWD|SHLVL|_)=' > /tmp/image.env

FROM ghcr.io/paperless-ngx/paperless-ngx:3.5.1

# PostgreSQL's major version is pinned (18, as in upstream's compose file), so
# a newer Debian under the upstream image never changes the data format.
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
    apt-get install -y --no-install-recommends postgresql-18 redis-server util-linux; \
    rm -rf /var/lib/apt/lists/*

# Tika and Gotenberg, whole, plus the settings they start with.
COPY --from=img-gotenberg / /opt/rootfs/gotenberg/
COPY --from=img-tika / /opt/rootfs/tika/
COPY --from=env-gotenberg /tmp/image.env /opt/icestore/gotenberg.env
COPY --from=env-tika /tmp/image.env /opt/icestore/tika.env

# s6 services. Paperless's init-wait-for-db waits for PostgreSQL and
# init-wait-for-redis for Redis, so both are started before Paperless's own
# init steps. Tika and Gotenberg are only called when a document needs them.
COPY s6/ /etc/s6-overlay/s6-rc.d/
RUN set -eux; \
    for s in svc-postgres svc-redis svc-tika svc-gotenberg; do \
      chmod +x "/etc/s6-overlay/s6-rc.d/$s/run"; \
      touch "/etc/s6-overlay/s6-rc.d/user/contents.d/$s"; \
    done; \
    touch /etc/s6-overlay/s6-rc.d/init-wait-for-db/dependencies.d/svc-postgres \
          /etc/s6-overlay/s6-rc.d/init-wait-for-redis/dependencies.d/svc-redis

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

ENV PAPERLESS_REDIS=redis://127.0.0.1:6379 \
    PAPERLESS_DBENGINE=postgresql \
    PAPERLESS_DBHOST=127.0.0.1 \
    PAPERLESS_DBPORT=5432 \
    PAPERLESS_DBNAME=paperless \
    PAPERLESS_DBUSER=paperless \
    PAPERLESS_TIKA_ENDPOINT=http://127.0.0.1:9998 \
    PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://127.0.0.1:3000 \
    S6_SERVICES_GRACETIME=20000 \
    AIO_CRED_FILE=/tmp/icestore-credentials
# AIO_CRED_FILE: the CREDENTIALS banner file. s6-overlay can put a fresh tmpfs
# on /run in a privileged container, so it lives in /tmp. It is an image ENV
# (not only exported by the start script) because IceDash finds the file from
# the container's environment as Docker reports it.

LABEL org.opencontainers.image.title="paperless-ngx-full" \
      org.opencontainers.image.description="Paperless-ngx with PostgreSQL, Redis, Tika and Gotenberg inside and per-install secrets" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
