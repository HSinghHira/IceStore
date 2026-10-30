# syntax=docker/dockerfile:1.7
#
# Kitchen Board, as upstream ships it, plus one IceStore start script that
# gives every install its own SECRET_KEY (made on first start, kept in the
# data folder). Nothing else is changed.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM g33kphr33k/kitchenboard:1.6

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="kitchen-board" \
      org.opencontainers.image.description="Kitchen Board with a per-install secret key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# Upstream's /entrypoint.sh (run by icestore-init) fixes the owner of /data
# and drops to the kitchenboard user.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
