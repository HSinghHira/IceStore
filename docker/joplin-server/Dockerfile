# syntax=docker/dockerfile:1.7
#
# Joplin Server, as upstream ships it, plus:
#   - PostgreSQL 16 (PGDG, the version upstream's compose file uses) and
#     supervisord, so the database upstream runs as a second container lives
#     in the same one;
#   - one IceStore start script that gives every install its own database
#     password and first admin password (made on first start, kept in /data)
#     and prints the login in a CREDENTIALS box.
# The handwriting-recognition service (transcribe) is left out.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM joplin/server:3.7.6

USER root
# PostgreSQL's major version is pinned (16), so a newer Debian under the
# upstream image never changes the data format.
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
    apt-get install -y --no-install-recommends postgresql-16 supervisor openssl util-linux procps tzdata; \
    rm -rf /var/lib/apt/lists/*

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/joplin-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/joplin-svc /usr/local/lib/icestore/credentials.sh

ENV APP_PORT=22300 DB_CLIENT=pg POSTGRES_HOST=/run/postgresql POSTGRES_PORT=5432 \
    POSTGRES_USER=joplin POSTGRES_DATABASE=joplin

LABEL org.opencontainers.image.title="joplin-server" \
      org.opencontainers.image.description="Joplin Server with PostgreSQL inside and a per-install admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 22300
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=240s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:22300/api/ping || exit 1

ENTRYPOINT ["tini", "--", "/usr/local/bin/icestore-init"]
CMD []
