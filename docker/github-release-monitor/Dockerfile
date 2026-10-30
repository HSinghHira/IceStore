# syntax=docker/dockerfile:1.7
#
# GitHub Release Monitor, as upstream ships it, plus one IceStore start
# script that:
#   - gives every install its own BETTER_AUTH_SECRET and AUTH_SETUP_TOKEN
#     (made on first start, kept in the data folder),
#   - lets the app write to a data folder ZimaOS made as root,
#   - lets people sign in from home-network addresses on port 6182 over
#     plain http.
# Nothing else is changed.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/iamspido/github-release-monitor:2.6.1

USER root
RUN apk add --no-cache su-exec
COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="github-release-monitor" \
      org.opencontainers.image.description="GitHub Release Monitor with per-install auth secrets" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# Starts as root only to fix the data folder's owner, then runs the app as
# upstream's nextjs user through node's own entrypoint.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["node", "server.js"]
