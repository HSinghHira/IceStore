# syntax=docker/dockerfile:1.7
#
# Paperless-ngx, as upstream ships it, plus:
#   - Redis (Debian's redis-server) as one more s6 service, so the task
#     broker upstream runs as a second container lives in the same one;
#   - one IceStore start script that gives every install its own
#     PAPERLESS_SECRET_KEY and admin password (made on first start, kept in
#     the data folder) and prints the login in a CREDENTIALS box.
# SQLite is the database (upstream's docker-compose.sqlite.yml).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/paperless-ngx/paperless-ngx:3.5.1

RUN apt-get update \
 && apt-get install --yes --quiet --no-install-recommends redis-server \
 && rm -rf /var/lib/apt/lists/*

# s6 service for Redis. Paperless's own init-wait-for-redis waits for it, and
# it starts after init-folders, so the data folder already belongs to the
# paperless user it runs as.
COPY s6/svc-redis/ /etc/s6-overlay/s6-rc.d/svc-redis/
RUN chmod +x /etc/s6-overlay/s6-rc.d/svc-redis/run \
 && touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-redis \
          /etc/s6-overlay/s6-rc.d/init-wait-for-redis/dependencies.d/svc-redis

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

ENV PAPERLESS_REDIS=redis://127.0.0.1:6379 \
    PAPERLESS_DBENGINE=sqlite

LABEL org.opencontainers.image.title="paperless-ngx" \
      org.opencontainers.image.description="Paperless-ngx with Redis inside and a per-install secret key and admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec /init`, so s6-overlay still runs as PID 1.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
