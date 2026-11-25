# syntax=docker/dockerfile:1.7
#
# Typesense, as upstream ships it, plus one IceStore start script that gives
# every install its own secrets (made on first start, kept in /data).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM typesense/typesense:30.2

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="typesense" \
      org.opencontainers.image.description="Typesense with a per-install API key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]

