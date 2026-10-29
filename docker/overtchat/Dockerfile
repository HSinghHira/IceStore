# syntax=docker/dockerfile:1.7
#
# OvertChat, as upstream ships it, plus one IceStore start script that:
#   - gives every install its own BETTER_AUTH_SECRET (made on first start,
#     kept in the data folder),
#   - lets the app write to a data folder ZimaOS made as root,
#   - fills in the address settings from BETTER_AUTH_URL.
# Nothing else is changed. Search and speech services are not bundled; add
# your own in OvertChat's settings.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/yoloyash/overtchat-app:0.29.0

USER root
COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="overtchat" \
      org.opencontainers.image.description="OvertChat with a per-install auth secret" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# Starts as root only to fix the data folder's owner, then runs the app as
# upstream's nextjs user through upstream's own entrypoint.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["node", "apps/web/server.js"]
