# syntax=docker/dockerfile:1.7
#
# Ghostfolio, as upstream ships it, plus:
#   - PostgreSQL 17 (PGDG) and Redis (Debian's redis-server) run by
#     supervisord, so the two containers upstream runs next to it live in the
#     same one;
#   - one IceStore start script that gives every install its own JWT secret,
#     access token salt and database and Redis passwords (made on first
#     start, kept in /data).
#
# Ghostfolio's first account (Get Started) is the admin.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghostfolio/ghostfolio:3.100.0

USER root
# PostgreSQL's major version is pinned (17), so a newer Debian under the
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
    apt-get install -y --no-install-recommends postgresql-17 redis-server supervisor openssl util-linux procps tzdata; \
    rm -rf /var/lib/apt/lists/*

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY svc.sh /usr/local/bin/ghostfolio-svc
COPY supervisord.conf /etc/supervisor/icestore.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/ghostfolio-svc /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="ghostfolio" \
      org.opencontainers.image.description="Ghostfolio with PostgreSQL and Redis inside and per-install secrets" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 3333
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:3333/api/v1/health || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
