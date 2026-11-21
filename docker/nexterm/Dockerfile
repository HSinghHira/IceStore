# syntax=docker/dockerfile:1.7
#
# Nexterm, as upstream ships it, plus one IceStore start script that gives
# every install its own ENCRYPTION_KEY (made on first start, kept in
# /app/data), which Nexterm needs to start and does not make itself.
#
# Nexterm asks for the first admin account on its first page.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM nexterm/server:1.2.2-BETA

# openssl makes the encryption key (the upstream image has none).
RUN apk add --no-cache openssl
COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="nexterm" \
      org.opencontainers.image.description="Nexterm with a per-install encryption key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/bin/sh", "docker-start.sh"]
