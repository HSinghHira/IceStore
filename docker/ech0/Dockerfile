# syntax=docker/dockerfile:1.7
#
# Ech0, as upstream ships it, plus one IceStore start script that gives
# every install its own JWT_SECRET (made on first start, kept in /app/data).
# Upstream's example uses a fixed one, and without one Ech0 makes a new
# secret on every start, which signs everyone out.
#
# The first account you register is the owner.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM sn0wl1n/ech0:v6.0.0

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="ech0" \
      org.opencontainers.image.description="Ech0 with a per-install JWT secret" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["serve"]
