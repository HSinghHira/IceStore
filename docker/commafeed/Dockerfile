# syntax=docker/dockerfile:1.7
#
# CommaFeed, as upstream ships it, plus one IceStore start script that gives
# every install its own session key (made on first start, kept in
# /commafeed/data), so people stay signed in across restarts.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM athou/commafeed:7.5.3-h2

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="commafeed" \
      org.opencontainers.image.description="CommaFeed with a per-install session key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["./commafeed"]
