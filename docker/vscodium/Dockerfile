# syntax=docker/dockerfile:1.7
#
# linuxserver's VSCodium web image, as upstream ships it, plus one IceStore
# start script that gives every install its own connection token (made on
# first start, kept in /config). Nothing else is changed.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM lscr.io/linuxserver/vscodium-web:1.143.17183-ls45

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="vscodium" \
      org.opencontainers.image.description="VSCodium web with a per-install connection token" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec /init`, so s6-overlay still runs as PID 1.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
