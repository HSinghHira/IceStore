# syntax=docker/dockerfile:1.7
#
# Pocket ID, as upstream ships it, plus one IceStore start script that gives
# every install its own ENCRYPTION_KEY (made on first start, kept in the data
# folder). Nothing else is changed.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/pocket-id/pocket-id:v2.19.1

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

# Set in the image, not only by the start script, so `docker exec pocket-id
# /app/pocket-id ...` (the healthcheck, one-time-access-token) finds the key
# too: Pocket ID refuses to run any command without one.
ENV ENCRYPTION_KEY_FILE=/app/data/.encryption_key

LABEL org.opencontainers.image.title="pocket-id" \
      org.opencontainers.image.description="Pocket ID with a per-install encryption key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/app/pocket-id"]
