# syntax=docker/dockerfile:1.7
#
# GitSave, as upstream ships it, plus one IceStore start script that gives
# every install its own JWT_SECRET and ENCRYPTION_SECRET (made on first
# start, kept in the data folder). Nothing else is changed.
#
# Upstream only publishes amd64 images.
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM timwitzdam/gitsave:1.4.0

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="gitsave" \
      org.opencontainers.image.description="GitSave with per-install secrets" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# Same command as upstream: update the database, then start the server.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/bin/sh", "-c", "npx prisma db push && npx tsx backend/server.ts"]
