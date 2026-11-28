# syntax=docker/dockerfile:1.7
#
# Donetick, as upstream ships it, plus one IceStore start script that gives
# every install its own JWT secret (made on first start, kept in
# /donetick-data) instead of the shared one in upstream's selfhosted.yaml.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM donetick/donetick:v0.1.89

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="donetick" \
      org.opencontainers.image.description="Donetick with a per-install JWT secret" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/donetick"]
