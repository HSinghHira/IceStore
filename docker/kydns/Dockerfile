# syntax=docker/dockerfile:1.7
#
# KyDNS, as upstream ships it (distroless, no shell), plus busybox and one
# IceStore start script. KyDNS refuses to start when any folder above its
# setup socket (/var/lib/kydns/installer/setup.sock) is writable by group
# or others, and the data folder ZimaOS bind-mounts there can be. The start
# script removes those write bits before KyDNS starts.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/busnes-app/kydns-server:0.6.1.2

USER 0:0
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox
RUN ["/bin/busybox", "--install", "-s", "/bin"]

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers (docker/_common; built with --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="kydns" \
      org.opencontainers.image.description="KyDNS with a data folder its setup socket accepts" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/usr/local/bin/kydns", "serve", "--config", "/etc/kydns/kydns.yaml"]
