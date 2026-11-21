# syntax=docker/dockerfile:1.7
#
# HomeBox, as upstream ships it, plus one IceStore start script that gives
# every install its own HBOX_AUTH_API_KEY_PEPPER (made on first start, kept
# in /data), which HomeBox needs to start and does not make itself.
#
# The first account you register is the owner of your home.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/sysadminsmedia/homebox:0.27.1

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="homebox" \
      org.opencontainers.image.description="HomeBox with a per-install API key pepper" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/data/config.yml"]
