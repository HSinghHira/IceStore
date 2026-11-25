# syntax=docker/dockerfile:1.7
#
# PhotoPrism, as upstream ships it, plus one IceStore start script that gives
# every install its own secrets (made on first start, kept in /photoprism/storage).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM photoprism/photoprism:261029

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="photoprism" \
      org.opencontainers.image.description="PhotoPrism with per-install secrets" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]

