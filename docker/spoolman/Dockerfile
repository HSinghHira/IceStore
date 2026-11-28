# syntax=docker/dockerfile:1.7
#
# Spoolman, as upstream ships it, plus one IceStore start script that gives
# the data folder to the app user before upstream's entrypoint drops to it.
# ZimaOS makes the bind folder as root, and upstream never chowns it, so
# the app could not write its database there.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/donkie/spoolman:0.27.1

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers (docker/_common; built with --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="spoolman" \
      org.opencontainers.image.description="Spoolman with a data folder it can write to" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
