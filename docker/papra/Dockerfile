# syntax=docker/dockerfile:1.7
#
# Papra, as upstream ships it (root variant), plus one IceStore start script
# that gives every install its own AUTH_SECRET (made on first start, kept in
# /app/app-data).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/papra-hq/papra:26.7.1-root

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="papra" \
      org.opencontainers.image.description="Papra with a per-install auth secret" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["pnpm", "start:with-migrations"]
