# syntax=docker/dockerfile:1.7
#
# Livebook, as upstream ships it, plus one IceStore start script that gives
# every install its own secrets (made on first start, kept in /data).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/livebook-dev/livebook:0.19.11

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="livebook" \
      org.opencontainers.image.description="Livebook with a per-install password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/app/bin/server"]
