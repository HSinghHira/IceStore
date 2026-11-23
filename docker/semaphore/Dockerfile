# syntax=docker/dockerfile:1.7
#
# Semaphore UI, as upstream ships it, plus one IceStore start script that:
#   - gives every install its own access key encryption secret and admin
#     password (made on first start, kept in /data);
#   - uses SQLite in /data, so no database container is needed;
#   - gives /data to Semaphore's user (ZimaOS makes the folder as root) and
#     prints the login in a CREDENTIALS box.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM semaphoreui/semaphore:v2.20.24

USER root
RUN apk add --no-cache setpriv

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="semaphore" \
      org.opencontainers.image.description="Semaphore UI on SQLite with a per-install encryption secret and admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script runs upstream's server-wrapper as Semaphore's user (1001).
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/icestore-init"]
CMD ["/usr/local/bin/server-wrapper"]
